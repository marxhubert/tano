import 'dart:async';
import 'package:tano/shared/widgets/document_filter.dart';
import 'package:tano/core/models/task.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/document_filter_controller.dart';
import 'package:tano/shared/config/fab_side_controller.dart';
import 'package:tano/shared/config/view_layout_controller.dart';
import 'package:tano/shared/widgets/toast.dart';
import 'package:tano/shared/widgets/undo_delete.dart';
import 'package:tano/core/models/deleted_batch.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/features/notes/widgets/folder_grid_view.dart';
import 'package:tano/features/notes/widgets/note_cards.dart';
import 'package:tano/features/folder/folder_page.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/shared/widgets/fab/fab_route_collapse.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/editor/open_editor.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/widgets/menu.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/storage_recovery.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/config/route_observer.dart';
import 'package:tano/shared/config/search_history_controller.dart';
import 'package:tano/shared/config/search_mode.dart';
import 'package:tano/shared/config/sort_preferences_controller.dart';
import 'package:tano/shared/widgets/search_history.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/empty_state.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.initialNotes, this.openEditorOnLaunch = false});

  /// Notes already loaded by the splash screen. When null (legacy
  /// navigation flows), the view model falls back to loading them.
  final List<Note>? initialNotes;

  /// Opens the editor as soon as the page appears, when there is no note yet.
  /// The introduction sets it, so its last page does create the first note.
  final bool openEditorOnLaunch;

  @override
  HomeState createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> with RouteAware, FabRouteCollapse<Home> {
  late final HomeViewModel _viewModel;
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  final GlobalKey<AppFabState> _fabKey = GlobalKey<AppFabState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchMode = false;
  bool _wasInSelectionMode = false;

  @override
  void initState() {
    super.initState();
    final NotesRepository repository = getIt<NotesRepository>();
    _viewModel = HomeViewModel(
      repository: repository,
      // The SQLite repository also knows about folders; the in-memory test
      // doubles only implement notes, in which case folders stay empty.
      foldersRepository: repository is FoldersRepository
          ? repository as FoldersRepository
          : null,
      initialNotes: widget.initialNotes,
    );
    _wasInSelectionMode = _viewModel.isInSelectionMode;
    if (widget.initialNotes == null) {
      // Navigation flows that do not receive the data loaded by the splash
      // screen fall back to loading the notes themselves.
      _viewModel.load();
    } else {
      // The notes are already there; only the folders still need loading.
      _viewModel.loadFolders();
    }
    _loadPreferences();
    _viewModel.addListener(_onViewModelChanged);
    ViewLayoutController.instance.addListener(_syncViewLayout);
    SortPreferencesController.instance.addListener(_onSortChanged);
    DocumentFilterController.instance.addListener(_onDocumentFilterChanged);
    FabSideController.instance.addListener(_onFabSideChanged);
    if (widget.openEditorOnLaunch && (widget.initialNotes?.isEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openNoteEditor(add: true, note: Note());
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of<void>(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    disposeFabRouteCollapse();
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    ViewLayoutController.instance.removeListener(_syncViewLayout);
    SortPreferencesController.instance.removeListener(_onSortChanged);
    DocumentFilterController.instance.removeListener(_onDocumentFilterChanged);
    FabSideController.instance.removeListener(_onFabSideChanged);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  GlobalKey<AppFabState> get fabKey => _fabKey;

  /// Called when another route (editor, settings, ...) is pushed on top of
  /// Home. Dismiss the undo snack bar immediately so it does not linger if
  /// the user comes back before its timeout, then let [FabRouteCollapse] fold
  /// the FAB.
  @override
  void didPushNext() {
    ScaffoldMessenger.of(context).clearSnackBars();
    super.didPushNext();
  }

  void _onViewModelChanged() {
    if (_viewModel.isInSelectionMode && _isSearchMode) {
      setState(() {
        _isSearchMode = false;
      });
      _searchFocusNode.unfocus();
    } else if (_wasInSelectionMode && !_viewModel.isInSelectionMode) {
      // We just exited selection mode: clear search to return to the full list.
      if (_viewModel.hasSearchQuery) {
        _clearSearch();
      }
    }
    _wasInSelectionMode = _viewModel.isInSelectionMode;
  }

  /// The FAB's side, shared with every other page.
  bool get _fabOnLeft => FabSideController.instance.onLeft;

  Future<void> _loadPreferences() async {
    // The shared controllers own the choices; Home only mirrors them.
    await ViewLayoutController.instance.load();
    _viewModel.setViewLayout(ViewLayoutController.instance.layout);
    await SortPreferencesController.instance.load();
    _applySortPreferences();

    await DocumentFilterController.instance.load();
    _viewModel.setDocumentFilter(DocumentFilterController.instance.filter);

    await FabSideController.instance.load();
  }

  /// Mirrors the shared sorting controller into the view model, which re-sorts
  /// and notifies on any real change.
  void _applySortPreferences() {
    final SortPreferencesController sort = SortPreferencesController.instance;
    _viewModel.setSortBy(sort.by);
    _viewModel.setSecondarySortBy(sort.secondaryBy);
    _viewModel.setSortAscending(sort.ascending);
  }

  void _onSortChanged() => _applySortPreferences();

  void _onDocumentFilterChanged() =>
      _viewModel.setDocumentFilter(DocumentFilterController.instance.filter);

  /// The side is global: the controller notifies every page and persists it.
  Future<void> _setFabOnLeft(bool value) async {
    await FabSideController.instance.setOnLeft(value);
    if (mounted) setState(() {});
  }

  void _onFabSideChanged() {
    if (mounted) setState(() {});
  }

  /// The layout changed elsewhere — in a folder, say. Mirror it here.
  void _syncViewLayout() {
    if (!mounted) return;
    _viewModel.setViewLayout(ViewLayoutController.instance.layout);
  }

  Future<void> _openNoteEditor({required bool add, required Note note}) async {
    // Opening a note leaves the search: coming back shows the whole list.
    if (_isSearchMode) _exitSearchMode();
    // A locked note filed in a locked folder does not prompt again.
    final NoteAction? result = await openNoteEditor(
      context,
      add: add,
      note: note,
      authenticated: false,
      requiresAuthentication: _viewModel.isNoteEffectivelyLocked(note),
      fullscreenDialog: true,
    );
    if (result != null) {
      await _viewModel.applyNoteAction(
        add: add,
        originalId: note.id,
        action: result,
      );
    }
    // The editor may persist changes directly (auto-save on bookmark/category/
    // pin, or the back-navigation "save" action) without returning a
    // NoteAction. Refresh the list so it always reflects the latest persisted
    // state.
    await _viewModel.load();
  }

  void _changeLayout(String viewLayout) {
    // This page first, so the swap is instant; the controller then keeps every
    // other page in step and persists the choice.
    _viewModel.setViewLayout(viewLayout);
    ViewLayoutController.instance.setLayout(viewLayout);
  }

  void _clearSearch() {
    _searchController.clear();
    _viewModel.setSearchQuery('');
  }

  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
    focusSearchField(
      focusNode: _searchFocusNode,
      isStillActive: () => mounted && _isSearchMode,
    );
  }

  void _exitSearchMode() {
    leaveSearchMode(controller: _searchController, focusNode: _searchFocusNode);
    _clearSearch();
    setState(() {
      _isSearchMode = false;
    });
  }

  /// Metadata of the page title line: the folder group when folders exist,
  /// the notes group otherwise (both groups never share one counter).
  String get _pageMetadata => _viewModel.hasFolders
      ? _groupMetadata(
          count: _viewModel.selectedFoldersCount,
          total: _viewModel.foldersCount,
          noun: 'folder',
        )
      : _notesMetadata;

  /// Metadata of the notes group header.
  String get _notesMetadata => _groupMetadata(
    count: _viewModel.selectedNotesCount,
    total: _viewModel.notesCount,
    // "notes", "tasks", or "docs" once the kinds are mixed — a folder in the
    // selection counts as another kind.
    noun: _viewModel.selectionNoun,
  );

  /// One group's metadata: its own selection wording while selecting, its
  /// plain count otherwise.
  String _groupMetadata({
    required int count,
    required int total,
    required String noun,
  }) {
    if (!_viewModel.isInSelectionMode || count == 0) {
      return groupCountLabel(total: total, noun: noun);
    }
    return selectionCountLabel(count: count, total: total, noun: noun);
  }

  /// Prompts for a folder name and creates it. The prompt keeps its save action
  /// disabled until the field holds a name, so no blank folder can be created.
  bool _isAddingFolder = false;

  Future<void> _addFolder() async {
    // Guard against a double submission (fast double tap / keyboard submit).
    if (_isAddingFolder) return;
    _isAddingFolder = true;
    try {
      await _promptAndCreateFolder();
    } finally {
      _isAddingFolder = false;
    }
  }

  Future<void> _promptAndCreateFolder() async {
    final String? name = await showAdaptivePrompt(
      context: context,
      title: AppText.tr('add_folder'),
      hint: AppText.tr('folder_name'),
      maxLength: 54,
      requireText: true,
    );

    if (name == null || !mounted) return;
    await runStorageOperation(context, () async {
      await _viewModel.addFolder(name);
    });
  }

  Future<void> _showUndoSnackBar() async {
    ScaffoldMessenger.of(context).clearSnackBars();
    final DeletedBatch? batch = _viewModel.lastDeletedBatch;
    if (batch == null || batch.isEmpty) return;
    // The same notice, the same words and the same restore as a folder page.
    await announceDeletion(
      context,
      repository: getIt<NotesRepository>(),
      batch: batch,
      onRestored: _viewModel.reinsertLastDeleted,
    );
  }

  /// Moves the selection, then says where it went. The block that left is not
  /// always where the eye is looking.
  Future<void> _moveSelectedTo(String? folderId) async {
    final int count = _viewModel.selected.length;
    if (!await runStorageOperation(
      context,
      () => _viewModel.moveSelectedTo(folderId),
    )) {
      // A failed batch may have moved only part of the selection: reload so the
      // list and storage agree again.
      await _viewModel.load();
      return;
    }
    if (!mounted) return;
    await announceMove(context, count: count, folderId: folderId);
  }

  /// Archives the selection: the documents leave Home, nothing is deleted.
  Future<void> _archiveSelected() async {
    if (!_viewModel.hasSelection) return;
    if (!await runStorageOperation(context, _viewModel.archiveSelected)) {
      await _viewModel.load();
      return;
    }
    if (!mounted) return;
    await _viewModel.load();
  }

  /// True when the page has nothing to show: the illustration is then the only
  /// content, and it has to hold its place when the keyboard opens.
  bool get _isEmptyHome =>
      _viewModel.folders.isEmpty && _viewModel.notes.isEmpty;

  Widget _layoutChanger(List<Note> notes, String viewLayout) {
    if (notes.isEmpty) {
      if (_viewModel.hasSearchQuery) {
        return emptyStateSliver(
          context,
          AppText.tr('no_note_found'),
          image: EmptyArt.search,
        );
      }
      return emptyStateSliver(
        context,
        AppText.tr('no_data'),
        image: EmptyArt.box,
      );
    }

    return _notesSliver(notes, viewLayout);
  }

  Widget _notesSliver(List<Note> notes, String viewLayout) {
    return NoteCards(
      viewModel: _viewModel,
      isList: viewLayout == 'list',
      onOpenNote: (Note note) {
        _openNoteEditor(add: false, note: note);
      },
    );
  }

  /// True while the field is open on an empty query with something to offer.
  bool get _showSearchHistory => showSearchHistory(
    isSearchMode: _isSearchMode,
    hasQuery: _viewModel.hasSearchQuery,
  );

  /// Home content: the folder group on top, then the unfiled notes.
  Widget _buildHomeContent() {
    // While the field is empty, the recent searches stand in for the list.
    if (_showSearchHistory) {
      return searchHistorySliver(
        context,
        onSelected: (String query) {
          _searchController.text = query;
          _viewModel.setSearchQuery(query);
        },
      );
    }
    final List<Folder> folders = _viewModel.folders;
    final List<Note> notes = _viewModel.notes;
    final String viewLayout = _viewModel.viewLayout;

    if (folders.isEmpty) {
      return _layoutChanger(notes, viewLayout);
    }

    return SliverMainAxisGroup(
      slivers: <Widget>[
        // The folder group has no header of its own: the page title is its
        // title. Only the notes group gets one, styled like the page title.
        // Folders stay a grid whatever layout the documents use.
        FolderGridView(viewModel: _viewModel, onOpenFolder: _openFolder),
        // An empty docs group shows nothing at all: no spacer, no tabs, no
        // empty-state paragraph.
        if (_viewModel.hasDocs) ...<Widget>[
          const SliverToBoxAdapter(child: SizedBox(height: 20.0)),
          _notesSectionHeader(),
          _notesSliver(notes, viewLayout),
        ],
      ],
    );
  }

  /// The kind control, shared by the page header and the notes group header.
  /// It prints every count, so no separate counter is needed.
  Widget _documentFilterControl() => DocumentFilterControl(
    value: _viewModel.documentFilter,
    countOf: _viewModel.countFor,
    // Selecting something replaces the tags with the selection sentence.
    selectionLabel: _viewModel.isInSelectionMode ? _notesMetadata : null,
    onChanged: DocumentFilterController.instance.set,
  );

  Widget _notesSectionHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        // Matches the page header: the metadata line sits the same distance
        // above its content, above and below.
        padding: const EdgeInsets.only(bottom: appPaddingTight),
        child: SectionTitleLine(
          titleWidget: _documentFilterControl(),
          crossAxisAlignment: CrossAxisAlignment.center,
          padding: EdgeInsets.symmetric(
            horizontal: appSidePad(context, appPaddingSmall),
          ),
        ),
      ),
    );
  }

  Future<void> _openFolder(Folder folder) async {
    // Opening a folder leaves the search: coming back shows the whole list.
    if (_isSearchMode) _exitSearchMode();
    if (folder.isLocked) {
      final bool authenticated = await getIt<AuthService>().authenticate(
        reason: AppText.tr('auth_reason'),
      );
      if (!authenticated || !mounted) return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => FolderPage(folder: folder),
      ),
    );
    await _viewModel.load();
  }

  List<Widget>? _buildAppBarActions() {
    if (_viewModel.isInSelectionMode) {
      return <Widget>[CancelButton(onPressed: _viewModel.exitSelectionMode)];
    }
    if (_isSearchMode) {
      return <Widget>[CancelButton(onPressed: _exitSearchMode)];
    }
    return <Widget>[
      // Search earns its place from the third searchable document: below that
      // there is nothing the list could not show at a glance. Locked notes do
      // not count, search never reaches them.
      if (_viewModel.searchableDocsCount > 2)
        IconButton(
          icon: const Icon(Symbols.document_search),
          tooltip: AppText.tr('search'),
          onPressed: _enterSearchMode,
        ),
      const ThemeToggleButton(),
      _buildAdaptiveMenu(),
    ];
  }

  Widget _buildAdaptiveMenu() => AppBarMenuButton(
    layout: _viewModel.viewLayout,
    onLayout: _changeLayout,
    onLeft: _fabOnLeft,
    onLeftChanged: _setFabOnLeft,
    onSettings: () async {
      await Navigator.of(context).pushNamed('/settings');
      _loadPreferences();
      await _viewModel.load();
    },
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // Also rebuild when the language changes: a route that stays in the
      // stack does not rebuild on its own.
      listenable: Listenable.merge(<Listenable>[
        _viewModel,
        LocaleController.instance,
        SearchHistoryController.instance,
      ]),
      builder: (BuildContext context, Widget? child) {
        return PageScaffold(
          title: _showSearchHistory
              ? AppText.tr('search_history')
              : AppText.tr(_viewModel.pageTitleKey),
          titleWidget:
              !_showSearchHistory &&
                  !_viewModel.hasFolders &&
                  !_viewModel.hasSearchQuery &&
                  _viewModel.hasDocs
              ? _documentFilterControl()
              : null,
          headerCrossAxisAlignment: CrossAxisAlignment.center,
          isHome: true,
          freezeBody: _isEmptyHome,
          // Scrolled in, the reduced title is the app's name.
          appBarTitleWidget: const TanoAppBarTitle(),
          scaffoldKey: _scaffoldState,
          actions: _buildAppBarActions(),
          // The document counts live in the segmented control; this line keeps
          // the folder count, and the selection wording.
          headerMetadata: _showSearchHistory || !_viewModel.hasFolders
              ? null
              : _pageMetadata,
          headerMetadataWidget: _showSearchHistory
              ? clearSearchHistoryButton(context)
              : null,
          slivers: [
            SliverPadding(
              padding: appContentPadding(context),
              sliver: _buildHomeContent(),
            ),
          ],
          floatingActionButtonLocation: FlushFabLocation(onLeft: _fabOnLeft),
          floatingActionButton: AppFab(
            key: _fabKey,
            onLeft: _fabOnLeft,
            isSearchMode: _isSearchMode,
            isSelectionMode: _viewModel.isInSelectionMode,
            // Moving needs a selection and never applies to a folder.
            canMove:
                _viewModel.hasSelection && !_viewModel.hasFolderInSelection,
            // Deleting needs a selection too.
            canDelete: _viewModel.hasSelection,
            controller: _searchController,
            focusNode: _searchFocusNode,
            onAdd: () {
              _openNoteEditor(add: true, note: Note());
            },
            onAddFolder: _addFolder,
            onAddTask: () => _openNoteEditor(add: true, note: Task()),
            onSearchChanged: (String value) {
              _viewModel.setSearchQuery(value);
            },
            onReset: _clearSearch,
            onDelete: () async {
              // The FAB only offers delete with a selection, so the only
              // refusal left is a locked item.
              if (_viewModel.hasLockedInSelection) {
                showAdaptiveNotice(context, AppText.tr('delete_locked_error'));
                return;
              }
              final bool? confirmDeletion = await getConfirmation(
                context: context,
                actionTitle: deleteSelectionTitle(
                  count: _viewModel.selectedCount,
                  total: _viewModel.notesCount,
                ),
                action: AppText.tr('delete'),
                message: _viewModel.hasFolderInSelection
                    ? AppText.tr('delete_folder_question', <String, String>{
                        'count': '${_viewModel.selectedFoldersNoteCount}',
                      })
                    : null,
              );
              if (!context.mounted || confirmDeletion != true) return;
              if (!await runStorageOperation(
                context,
                _viewModel.deleteSelected,
              )) {
                // A failed batch may have trashed only part of the selection:
                // reload so the list and storage agree again.
                await _viewModel.load();
                return;
              }
              await _showUndoSnackBar();
            },
            onMoveTo: _moveSelectedTo,
            onMoveToArchive: _archiveSelected,
            onClearSelection: _viewModel.clearSelection,
            onSelectAll: _viewModel.selectAll,
          ),
        );
      },
    );
  }
}
