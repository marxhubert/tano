import 'package:tano/shared/widgets/document_filter.dart';
import 'package:tano/core/models/task.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/feedback_controller.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/shared/widgets/toast.dart';
import 'package:tano/shared/widgets/undo_delete.dart';
import 'package:tano/core/models/deleted_batch.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/features/notes/widgets/folder_grid_view.dart';
import 'package:tano/features/notes/widgets/note_grid_view.dart';
import 'package:tano/features/notes/widgets/note_list_view.dart';
import 'package:tano/features/folder/folder_page.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/widgets/menu.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/config/route_observer.dart';
import 'package:tano/shared/config/search_history_controller.dart';
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

class HomeState extends State<Home> with RouteAware {
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
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  /// Called when another route (editor, settings, ...) is pushed on top of
  /// Home. Dismiss the undo snack bar immediately so it does not linger if
  /// the user comes back before its timeout.
  @override
  void didPushNext() {
    ScaffoldMessenger.of(context).clearSnackBars();
    // Fold the FAB once Home is fully covered, so it is already reduced when
    // the user comes back, with no visible collapse during the push.
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _fabKey.currentState?.collapse();
    });
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

  /// Whether the FAB sits on the left instead of the right.
  bool _fabOnLeft = false;

  Future<SecurePreferences> _getPrefs() => SecurePreferences.getInstance();

  Future<void> _loadPreferences() async {
    final SecurePreferences prefs = await _getPrefs();
    if (!prefs.containsKey('viewLayout')) {
      await prefs.setString('viewLayout', 'gridlist');
    }
    _viewModel.setViewLayout(prefs.getString('viewLayout') ?? 'gridlist');
    if (!prefs.containsKey('sortBy')) {
      await prefs.setString('sortBy', 'date');
    }
    _viewModel.setSortBy(prefs.getString('sortBy') ?? 'date');

    if (!prefs.containsKey('secondarySortBy')) {
      await prefs.setString('secondarySortBy', 'date');
    }
    _viewModel.setSecondarySortBy(prefs.getString('secondarySortBy') ?? 'date');

    if (!prefs.containsKey('sortAscending')) {
      await prefs.setBool('sortAscending', true);
    }
    _viewModel.setSortAscending(prefs.getBool('sortAscending') ?? true);

    if (!prefs.containsKey('documentFilter')) {
      await prefs.setString('documentFilter', DocumentFilter.all.name);
    }
    _viewModel.setDocumentFilter(
      documentFilterFromName(prefs.getString('documentFilter')) ??
          DocumentFilter.all,
    );

    if (!prefs.containsKey('fabOnLeft')) {
      await prefs.setBool('fabOnLeft', false);
    }
    final bool fabOnLeft = prefs.getBool('fabOnLeft') ?? false;
    if (fabOnLeft != _fabOnLeft && mounted) {
      setState(() => _fabOnLeft = fabOnLeft);
    }
  }

  Future<void> _setFabOnLeft(bool value) async {
    if (value == _fabOnLeft) return;
    setState(() => _fabOnLeft = value);
    final SecurePreferences prefs = await _getPrefs();
    await prefs.setBool('fabOnLeft', value);
  }

  Future<void> _saveViewLayoutPref(String viewLayout) async {
    final SecurePreferences prefs = await _getPrefs();
    await prefs.setString('viewLayout', viewLayout);
  }

  Future<void> _openNoteEditor({required bool add, required Note note}) async {
    // Opening a note leaves the search: coming back shows the whole list.
    if (_isSearchMode) _exitSearchMode();
    bool authenticated = false;
    // A locked note filed in a locked folder does not prompt again.
    if (_viewModel.isNoteEffectivelyLocked(note)) {
      authenticated = await getIt<AuthService>().authenticate(
        reason: AppText.tr('auth_reason'),
      );
      // The system prompt is awaited: the widget may be gone by now.
      if (!authenticated || !mounted) return;
    }

    final NoteAction? result = await Navigator.push(
      context,
      MaterialPageRoute<NoteAction>(
        builder: (context) => EditNote(
          add: add,
          index: -1,
          noteAction: NoteAction(kind: NoteActionKind.cancel, note: note),
          authenticated: authenticated,
        ),
        fullscreenDialog: true,
      ),
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
    _viewModel.setViewLayout(viewLayout);
    _saveViewLayoutPref(viewLayout);
  }

  void _clearSearch() {
    _searchController.clear();
    _viewModel.setSearchQuery('');
  }

  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only focus if the user is still in search mode: the frame may run
      // after a quick enter-then-cancel, which must not leave an orphaned
      // focused node (and an open keyboard) on the home screen.
      if (mounted && _isSearchMode) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _exitSearchMode() {
    // Leaving the search is what makes it a search: remember the query before
    // the field is emptied.
    SearchHistoryController.instance.add(_searchController.text);
    _clearSearch();
    // Release the search focus so the keyboard closes immediately.
    _searchFocusNode.unfocus();
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
          single: 'single_folder_selected',
          many: 'folders_selected',
          all: 'all_folders_selected',
        )
      : _notesMetadata;

  /// Metadata of the notes group header.
  String get _notesMetadata => _groupMetadata(
    count: _viewModel.selectedNotesCount,
    total: _viewModel.notesCount,
    noun: 'note',
    single: 'single_note_selected',
    many: 'notes_selected',
    all: 'all_notes_selected',
  );

  /// One group's metadata: its own selection wording while selecting, its
  /// plain count otherwise.
  String _groupMetadata({
    required int count,
    required int total,
    required String noun,
    required String single,
    required String many,
    required String all,
  }) {
    if (!_viewModel.isInSelectionMode || count == 0) {
      return '$total ${total > 1 ? AppText.tr('${noun}s') : AppText.tr(noun)}';
    }
    if (count > 1) {
      if (count == total) {
        return AppText.tr(all, <String, String>{'count': '$count'});
      }
      return AppText.tr(many, <String, String>{
        'count': '$count',
        'total': '$total',
      });
    }
    return AppText.tr(single, <String, String>{'count': '$count'});
  }

  String _deleteActionTitle() {
    if (_viewModel.selectedCount > 1) {
      return _viewModel.selectedCount == _viewModel.notesCount
          ? AppText.tr('delete_all_notes')
          : AppText.tr('delete_notes', <String, String>{
              'count': '${_viewModel.selectedCount}',
            });
    }
    return AppText.tr('delete_note');
  }

  /// Prompts for a folder name and creates the folder. Empty names fall back
  /// to "Folder X" inside the view model.
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
    );

    if (name == null || !mounted) return;
    await _viewModel.addFolder(name);
  }

  void _showUndoSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    final DeletedBatch? batch = _viewModel.lastDeletedBatch;
    if (batch == null || batch.isEmpty) return;
    // The same notice, the same words and the same restore as a folder page.
    showUndoDelete(
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
    await _viewModel.moveSelectedTo(folderId);
    if (!mounted) return;
    await FeedbackController.instance.impact();
    if (!mounted) return;
    await showMovedToast(context, count: count, folderId: folderId);
  }

  /// True when the page has nothing to show: the illustration is then the only
  /// content, and it has to hold its place when the keyboard opens.
  bool get _isEmptyHome =>
      _viewModel.folders.isEmpty && _viewModel.notes.isEmpty;

  Widget _layoutChanger(List<Note> notes, String viewLayout) {
    if (notes.isEmpty) {
      if (_viewModel.hasSearchQuery) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: emptyState(
            context,
            AppText.tr('no_note_found'),
            image: EmptyArt.search,
          ),
        );
      }
      if (_viewModel.isFilterHidingAll) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: emptyState(
            context,
            _viewModel.documentFilter.emptyLabel,
            image: EmptyArt.notFound,
          ),
        );
      }
      return SliverFillRemaining(
        hasScrollBody: false,
        child: emptyState(context, AppText.tr('no_data'), image: EmptyArt.box),
      );
    }

    return _notesSliver(notes, viewLayout);
  }

  Widget _notesSliver(List<Note> notes, String viewLayout) {
    if (notes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: emptyState(
          context,
          _viewModel.documentFilter.emptyLabel,
          image: EmptyArt.notFound,
        ),
      );
    }
    switch (viewLayout) {
      case 'gridlist':
        return NoteGridView(
          viewModel: _viewModel,
          onOpenNote: (Note note) {
            _openNoteEditor(add: false, note: note);
          },
        );
      case 'list':
      default:
        return NoteListView(
          viewModel: _viewModel,
          onOpenNote: (Note note) {
            _openNoteEditor(add: false, note: note);
          },
        );
    }
  }

  /// The recent searches, shown while the field is empty: the shortcut a
  /// search screen is expected to offer.
  Widget _searchHistorySliver(List<String> entries) {
    return SliverList(
      delegate: SliverChildListDelegate(<Widget>[
        for (final String query in entries)
          InkWell(
            borderRadius: BorderRadius.circular(appBorderRadius),
            onTap: () {
              _searchController.text = query;
              _viewModel.setSearchQuery(query);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: appPaddingSmall,
                vertical: appPaddingMedium,
              ),
              child: Text(
                query,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: TanoText.body,
                  color: primaryTextColor(context),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  /// True while the field is open on an empty query with something to offer.
  bool get _showSearchHistory =>
      _isSearchMode &&
      !_viewModel.hasSearchQuery &&
      SearchHistoryController.instance.entries.isNotEmpty;

  /// The "Clear" action, in the metadata slot of the title line.
  Widget _clearHistoryButton() {
    return TextButton(
      onPressed: () => SearchHistoryController.instance.clear(),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(AppText.tr('clear'), style: titleMetadataStyle(context)),
    );
  }

  /// Home content: the folder group on top, then the unfiled notes.
  Widget _buildHomeContent() {
    // While the field is empty, the recent searches stand in for the list.
    if (_showSearchHistory) {
      return _searchHistorySliver(SearchHistoryController.instance.entries);
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
        const SliverToBoxAdapter(child: SizedBox(height: 20.0)),
        ...<Widget>[_notesSectionHeader(), _notesSliver(notes, viewLayout)],
      ],
    );
  }

  /// The kind control, shared by the page header and the notes group header.
  /// It prints every count, so no separate counter is needed.
  Widget _documentFilterControl() => DocumentFilterControl(
    value: _viewModel.documentFilter,
    countOf: _viewModel.countFor,
    onChanged: (DocumentFilter filter) {
      _viewModel.setDocumentFilter(filter);
      _saveDocumentFilterPref(filter);
    },
  );

  Future<void> _saveDocumentFilterPref(DocumentFilter filter) async {
    final SecurePreferences prefs = await _getPrefs();
    await prefs.setString('documentFilter', filter.name);
  }

  Widget _notesSectionHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        // Matches the page header: the metadata line sits the same distance
        // above its content, above and below.
        padding: const EdgeInsets.only(bottom: appPaddingTight),
        child: SectionTitleLine(
          titleWidget: _documentFilterControl(),
          crossAxisAlignment: CrossAxisAlignment.center,
          // The counts live in the segments; only a selection still needs a
          // sentence of its own here.
          metadata: _viewModel.isInSelectionMode ? _notesMetadata : null,
          padding: const EdgeInsets.symmetric(horizontal: appPaddingSmall),
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
      IconButton(
        icon: const Icon(Symbols.search),
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
                  !_viewModel.hasSearchQuery
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
              ? _clearHistoryButton()
              : null,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(appPaddingMedium),
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
              if (!_viewModel.hasSelection) {
                // TODO: No action needed for now, maybe show a hint?
              } else if (_viewModel.hasLockedInSelection) {
                showAdaptiveNotice(context, AppText.tr('delete_locked_error'));
              } else {
                final bool? confirmDeletion = await getConfirmation(
                  context: context,
                  actionTitle: _deleteActionTitle(),
                  action: AppText.tr('delete'),
                  message: _viewModel.hasFolderInSelection
                      ? AppText.tr('delete_folder_question', <String, String>{
                          'count': '${_viewModel.selectedFoldersNoteCount}',
                        })
                      : null,
                );
                if (confirmDeletion == true) {
                  await _viewModel.deleteSelected();
                  await FeedbackController.instance.impact();
                  if (!mounted) return;
                  _showUndoSnackBar();
                }
              }
            },
            onMoveTo: _moveSelectedTo,
            onClearSelection: _viewModel.clearSelection,
            onSelectAll: _viewModel.selectAll,
          ),
        );
      },
    );
  }
}
