import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/features/notes/widgets/folder_grid_view.dart';
import 'package:tano/features/notes/widgets/folder_list_view.dart';
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
import 'package:tano/shared/widgets/no_record.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/config/route_observer.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.initialNotes});

  /// Notes already loaded by the splash screen. When null (legacy
  /// navigation flows), the view model falls back to loading them.
  final List<Note>? initialNotes;

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
      foldersRepository:
          repository is FoldersRepository ? repository as FoldersRepository : null,
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
  }

  Future<void> _saveViewLayoutPref(String viewLayout) async {
    final SecurePreferences prefs = await _getPrefs();
    await prefs.setString('viewLayout', viewLayout);
  }

  Future<void> _openNoteEditor({
    required bool add,
    required Note note,
  }) async {
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
    _clearSearch();
    // Release the search focus so the keyboard closes immediately.
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchMode = false;
    });
  }

  /// Metadata of the page title line: the folder group when folders exist,
  /// the notes group otherwise (both groups never share one counter).
  String get _pageMetadata =>
      _viewModel.hasFolders
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
    // The message reflects what was actually removed: notes, folders, or both.
    final List<String> parts = <String>[
      if (_viewModel.lastDeletedFolders.isNotEmpty)
        AppText.count(
          _viewModel.lastDeletedFolders.length,
          'folder',
          'folders',
        ),
      if (_viewModel.lastDeletedNotes.isNotEmpty)
        AppText.count(_viewModel.lastDeletedNotes.length, 'note', 'notes'),
    ];
    showAdaptiveNoticeWithAction(
      context: context,
      message: parts.isEmpty
          ? AppText.tr('note_deleted')
          : '${parts.join(' & ')} ${AppText.tr('deleted')}',
      actionLabel: AppText.tr('undo'),
      onAction: _viewModel.undoLastDelete,
    );
  }

  Widget _layoutChanger(List<Note> notes, String viewLayout) {
    if (notes.isEmpty) {
      if (_viewModel.hasSearchQuery) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              AppText.tr('no_note_found'),
              style: const TextStyle(fontSize: TanoText.tiny),
            ),
          ),
        );
      }
      return SliverFillRemaining(
        hasScrollBody: false,
        child: noRecordFound(context),
      );
    }

    return _notesSliver(notes, viewLayout);
  }

  Widget _notesSliver(List<Note> notes, String viewLayout) {
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
          onShowUndoSnackBar: _showUndoSnackBar,
          confirmDelete: _confirmDelete,
        );
    }
  }

  /// Home content: the folder group on top, then the unfiled notes.
  Widget _buildHomeContent() {
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
        if (viewLayout == 'list')
          FolderListView(viewModel: _viewModel, onOpenFolder: _openFolder)
        else
          FolderGridView(viewModel: _viewModel, onOpenFolder: _openFolder),
        const SliverToBoxAdapter(child: SizedBox(height: 20.0)),
        if (notes.isNotEmpty) ...<Widget>[
          _notesSectionHeader(),
          _notesSliver(notes, viewLayout),
        ],
      ],
    );
  }

  /// "My notes" group header: same style as the page title, with the note
  /// count on the same line.
  Widget _notesSectionHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        // The content sits in a 12px sliver padding: adding 6 lines the notes
        // title up with the page title (18px).
        child: SectionTitleLine(
          title: AppText.tr('all_notes'),
          metadata: _notesMetadata,
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

  Future<bool?> _confirmDelete() {
    return getConfirmation(
      context: context,
      actionTitle: _deleteActionTitle(),
      action: AppText.tr('delete'),
    );
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

  Widget _buildAdaptiveMenu() {
    final ThemeData theme = Theme.of(context);
    if (theme.platform == TargetPlatform.iOS || theme.platform == TargetPlatform.macOS) {
      return IconButton(
        icon: const Icon(Symbols.more_vert, weight: 900.0),
        tooltip: AppText.tr('more'),
        onPressed: () => _showCupertinoActionSheet(),
      );
    }

    return PopupMenuButton<PopupItem>(
      icon: const Icon(Symbols.more_vert, weight: 900.0),
      offset: const Offset(0, 56),
      elevation: 4.0,
      constraints: const BoxConstraints(minWidth: 160.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(appBorderRadius),
      ),
      onSelected: ((valueSelected) async {
        _handleMenuAction(valueSelected.value.toLowerCase());
      }),
      itemBuilder: (BuildContext context) {
        final List<PopupItem> popupItems = [];
        menuItems.forEach((String key, PopupItem popupItem) {
          popupItems.add(popupItem);
        });
        return popupItems.map<PopupMenuEntry<PopupItem>>((PopupItem popupItem) {
          if (popupItem.value == 'separator') {
            return const PopupMenuDivider(height: 1.0);
          }
          return PopupMenuItem<PopupItem>(
            value: popupItem,
            height: popupItem.value == 'header' ? 40.0 : 48.0,
            enabled: popupItem.value != 'header',
            padding: EdgeInsets.zero,
            child: popupButton(
              context: context,
              popupItem: popupItem,
              layout: _viewModel.viewLayout,
              lang: LocaleController.instance.language,
            ),
          );
        }).toList();
      },
    );
  }

  void _showCupertinoActionSheet() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _handleMenuAction('list');
            },
            child: Text(
              AppText.tr('menu_list'),
              style: TextStyle(
                color: tanoTeal,
                fontSize: TanoText.emptyState,
                fontWeight: _viewModel.viewLayout == 'list' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _handleMenuAction('gridlist');
            },
            child: Text(
              AppText.tr('menu_grid'),
              style: TextStyle(
                color: tanoTeal,
                fontSize: TanoText.emptyState,
                fontWeight: _viewModel.viewLayout == 'gridlist' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _handleMenuAction('settings');
            },
            child: Text(
              AppText.tr('settings'),
              style: const TextStyle(color: tanoTeal, fontSize: TanoText.emptyState),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            AppText.tr('cancel'),
            style: TextStyle(color: primaryTextColor(context), fontSize: TanoText.emptyState),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case "list":
        _changeLayout('list');
        break;
      case "gridlist":
        _changeLayout('gridlist');
        break;
      case "settings":
        await Navigator.of(context).pushNamed('/settings');
        _loadPreferences();
        await _viewModel.load();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // Also rebuild when the language changes: a route that stays in the
      // stack does not rebuild on its own.
      listenable: Listenable.merge(<Listenable>[
        _viewModel,
        LocaleController.instance,
      ]),
      builder: (BuildContext context, Widget? child) {
        return PageScaffold(
          title: AppText.tr(_viewModel.pageTitleKey),
          isHome: true,
          // Scrolled in, the reduced title is the app's name.
          appBarTitleWidget: const TanoAppBarTitle(),
          scaffoldKey: _scaffoldState,
          actions: _buildAppBarActions(),
          headerMetadata: _pageMetadata,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(appPaddingMedium),
              sliver: _buildHomeContent(),
            ),
          ],
          floatingActionButtonLocation: const FlushEndFabLocation(),
          floatingActionButton: AppFab(
            key: _fabKey,
            isSearchMode: _isSearchMode,
            isSelectionMode: _viewModel.isInSelectionMode,
            // Moving needs a selection and never applies to a folder.
            canMove: _viewModel.hasSelection &&
                !_viewModel.hasFolderInSelection,
            // Deleting needs a selection too.
            canDelete: _viewModel.hasSelection,
            controller: _searchController,
            focusNode: _searchFocusNode,
            onAdd: () {
              _openNoteEditor(add: true, note: Note());
            },
            onAddFolder: _addFolder,
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
                  _showUndoSnackBar();
                }
              }
            },
            onMoveTo: _viewModel.moveSelectedTo,
            onClearSelection: _viewModel.clearSelection,
            onSelectAll: _viewModel.selectAll,
          ),
        );
      },
    );
  }
}
