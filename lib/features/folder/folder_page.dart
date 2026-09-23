import 'dart:async';
import 'package:tano/shared/widgets/document_filter.dart';
import 'package:tano/core/models/task.dart';
import 'package:tano/shared/widgets/privacy_guard.dart';
import 'package:tano/core/models/note_access_policy.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/widgets/undo_delete.dart';
import 'package:tano/core/models/deleted_batch.dart';
import 'package:tano/core/models/content_entity.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/services/lock_gate.dart';
import 'package:tano/shared/controllers/selection_controller.dart';
import 'package:tano/features/editor/open_editor.dart';
import 'package:tano/shared/config/card_sorting.dart';
import 'package:tano/shared/config/document_filter_controller.dart';
import 'package:tano/shared/config/feedback_controller.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/fab_side_controller.dart';
import 'package:tano/shared/config/search_history_controller.dart';
import 'package:tano/shared/config/search_mode.dart';
import 'package:tano/shared/config/sort_preferences_controller.dart';
import 'package:tano/shared/config/view_layout_controller.dart';
import 'package:tano/shared/widgets/search_history.dart';
import 'package:tano/shared/config/route_observer.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/shared/widgets/fab/fab_route_collapse.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/menu.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/toast.dart';
import 'package:tano/shared/widgets/empty_state.dart';

/// Shows the notes filed in a single folder and its organisation actions.
class FolderPage extends StatefulWidget {
  const FolderPage({super.key, required this.folder});

  final Folder folder;

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage>
    with RouteAware, FabRouteCollapse<FolderPage> {
  final GlobalKey<AppFabState> _fabKey = GlobalKey<AppFabState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  DocumentFilter _documentFilter = DocumentFilter.all;
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  late Folder _folder;
  List<Note> _notes = <Note>[];
  Set<String> _activeNoteIds = <String>{};
  bool _loading = true;
  bool _isSearchMode = false;
  bool _searchStarted = false;
  bool _isEditingTitle = false;
  String _searchQuery = '';

  /// The layout lives in the shared controller, so Home sees a change made here.
  String get _viewLayout => ViewLayoutController.instance.layout;

  /// The FAB's side, shared with Home: one global choice.
  bool get _fabOnLeft => FabSideController.instance.onLeft;
  String _sortBy = 'date';
  String _secondarySortBy = 'date';
  bool _sortAscending = true;
  final SelectionController _selection = SelectionController();

  FoldersRepository? get _foldersRepository {
    final NotesRepository repository = getIt<NotesRepository>();
    return repository is FoldersRepository
        ? repository as FoldersRepository
        : null;
  }

  bool _canLock = false;

  Future<void> _loadLockCapability() async {
    final available =
        getIt.isRegistered<AuthService>() &&
        await getIt<AuthService>().isAvailable();
    if (mounted) setState(() => _canLock = available);
  }

  @override
  void initState() {
    super.initState();
    _loadLockCapability();
    _folder = widget.folder;
    _titleFocusNode.addListener(_onTitleFocusChanged);
    ViewLayoutController.instance.addListener(_onViewLayoutChanged);
    SortPreferencesController.instance.addListener(_onSortChanged);
    DocumentFilterController.instance.addListener(_onDocumentFilterChanged);
    FabSideController.instance.addListener(_onFabSideChanged);
    _loadPreferences();
    _load();
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
  GlobalKey<AppFabState> get fabKey => _fabKey;

  @override
  void dispose() {
    disposeFabRouteCollapse();
    routeObserver.unsubscribe(this);
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    ViewLayoutController.instance.removeListener(_onViewLayoutChanged);
    SortPreferencesController.instance.removeListener(_onSortChanged);
    DocumentFilterController.instance.removeListener(
      _onDocumentFilterChanged,
    );
    FabSideController.instance.removeListener(_onFabSideChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _selection.dispose();
    super.dispose();
  }

  /// The layout is the shared controller Home also listens to, so a switch here
  /// shows there — and the other way round.
  Future<void> _changeViewLayout(String viewLayout) async {
    await ViewLayoutController.instance.setLayout(viewLayout);
    if (mounted) setState(() {});
  }

  void _onViewLayoutChanged() {
    if (mounted) setState(() {});
  }

  /// The side is global: the controller notifies every page and persists it.
  Future<void> _setFabOnLeft(bool value) async {
    await FabSideController.instance.setOnLeft(value);
    if (mounted) setState(() {});
  }

  void _onFabSideChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).pushNamed('/settings');
    if (mounted) await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await ViewLayoutController.instance.load();
    await SortPreferencesController.instance.load();
    await DocumentFilterController.instance.load();
    await FabSideController.instance.load();
    if (!mounted) return;
    setState(() {
      _documentFilter = DocumentFilterController.instance.filter;
      _syncSort();
      _notes = _sorted(_notes);
    });
  }

  /// Copies the shared sorting controller into the page's own fields.
  void _syncSort() {
    final SortPreferencesController sort = SortPreferencesController.instance;
    _sortBy = sort.by;
    _secondarySortBy = sort.secondaryBy;
    _sortAscending = sort.ascending;
  }

  /// Settings changed the chosen order: re-sort without re-reading the keys.
  void _onSortChanged() {
    if (!mounted) return;
    setState(() {
      _syncSort();
      _notes = _sorted(_notes);
    });
  }

  /// The filter changed on this page or on Home: mirror it.
  void _onDocumentFilterChanged() {
    if (!mounted) return;
    setState(() => _documentFilter = DocumentFilterController.instance.filter);
  }

  /// Notes sorted like the home screen: important first, then the chosen
  /// criterion. Without this the folder kept the raw repository order.
  List<Note> _sorted(List<Note> notes) => NoteSorting(
    by: _sortBy,
    secondaryBy: _secondarySortBy,
    ascending: _sortAscending,
  ).sort(notes);

  Future<void> _load() async {
    final List<Note> all = await getIt<NotesRepository>().loadNotes();
    if (!mounted) return;
    setState(() {
      _activeNoteIds = activeEntityIds(all);
      _notes = _sorted(
        all.where((Note note) => note.folderId == _folder.id).toList(),
      );
      _loading = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
      _searchStarted = false;
    });
    focusSearchField(
      focusNode: _searchFocusNode,
      isStillActive: () => mounted && _isSearchMode,
    );
  }

  void _exitSearchMode() {
    leaveSearchMode(controller: _searchController, focusNode: _searchFocusNode);
    setState(() {
      _isSearchMode = false;
      _searchStarted = false;
      _searchQuery = '';
    });
  }

  Future<void> _save(Folder folder) async {
    final Folder updated = folder.copyWith(
      updatedAt: DateTime.now().toString(),
    );
    await _foldersRepository?.upsertFolder(updated);
    if (!mounted) return;
    setState(() => _folder = updated);
  }

  void _onTitleFocusChanged() {
    if (!_titleFocusNode.hasFocus) {
      _exitTitleEdit();
    }
  }

  /// Puts the folder title in edit mode: the name becomes an editable field,
  /// the caret blinks right after it and the keyboard opens.
  void _startTitleEdit() {
    _fabKey.currentState?.closeVerticalMenu();
    _titleController.text = _folder.name;
    _titleController.selection = TextSelection.collapsed(
      offset: _folder.name.length,
    );
    setState(() => _isEditingTitle = true);
  }

  /// Leaves title edit mode and silently stores the new name when it changed.
  Future<void> _exitTitleEdit() async {
    if (!_isEditingTitle) return;
    final String name = _titleController.text.trim();
    setState(() => _isEditingTitle = false);
    _titleFocusNode.unfocus();
    if (name.isEmpty || name == _folder.name) return;
    await _save(_folder.copyWith(name: name));
  }

  Future<void> _openNote({required bool add, required Note note}) async {
    // Opening a note leaves the search: coming back shows the whole folder.
    if (_isSearchMode) _exitSearchMode();
    // A locked note always asks for the system credential, unless the folder
    // itself is locked: opening it already authenticated the user.
    final NoteAction? result = await openNoteEditor(
      context,
      add: add,
      note: note,
      authenticated: _folder.isLocked,
      requiresAuthentication: note.isLocked && !_folder.isLocked,
    );
    if (result != null && result.note != null) {
      if (result.kind == NoteActionKind.delete) {
        await getIt<NotesRepository>().trashNote(result.note!.id);
      } else if (result.kind == NoteActionKind.save) {
        await getIt<NotesRepository>().upsertNote(result.note!);
      }
    }
    await _load();
  }

  Note _newNote() => Note(folderId: _folder.id, category: _folder.category);

  Future<void> _toggleLock() async {
    final LockGateResult gate = await requestLockChange(
      isLocked: _folder.isLocked,
    );
    if (gate == LockGateResult.unavailable) {
      if (!mounted) return;
      await showAdaptiveAlert(
        context: context,
        title: AppText.tr('lock_unavailable_title'),
        message: AppText.tr('lock_requires_device_lock'),
      );
      return;
    }
    if (gate == LockGateResult.refused || !mounted) return;
    final bool locked = !_folder.isLocked;
    await _save(_folder.copyWith(isLocked: locked));
    if (!mounted) return;
    await FeedbackController.instance.success();
    if (!mounted) return;
    await showLockToast(context, locked: locked, folder: true);
  }

  Future<void> _delete() async {
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: AppText.tr('delete_folder'),
      action: AppText.tr('delete'),
      message: AppText.tr('delete_folder_question', <String, String>{
        'count': '${_notes.length}',
      }),
    );
    if (confirm != true || !mounted) return;

    // The folder keeps its notes: they stay filed and travel with it.
    await _foldersRepository?.trashFolder(_folder.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _enterSelection(String id) {
    // Keep the search active: the selection stays scoped to the results.
    setState(() => _selection.enter(id));
  }

  void _toggleSelection(String id) {
    setState(() => _selection.toggle(id));
  }

  void _exitSelection() {
    setState(_selection.exit);
    // Leaving the selection never brings the search back.
    if (_isSearchMode) _exitSearchMode();
  }

  Future<void> _deleteSelected() async {
    // A locked note is only deleted from inside, once opened: the list never
    // removes one, exactly like Home.
    if (_notes.any(
      (Note note) => _selection.contains(note.id) && note.isLocked,
    )) {
      showAdaptiveNotice(context, AppText.tr('delete_locked_error'));
      return;
    }
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: deleteSelectionTitle(
        count: _selection.count,
        total: _visibleNotes.length,
      ),
      action: AppText.tr('delete'),
    );
    if (confirm != true || !mounted) return;
    final NotesRepository repository = getIt<NotesRepository>();

    // Keep what leaves, with its place, so the undo can put it back exactly
    // where it was - the same accounting the home page does.
    final ({List<Note> notes, List<int> indexes}) selected =
        collectSelectedNotes(
          _notes,
          (Note note) => _selection.contains(note.id),
        );
    for (final Note note in selected.notes) {
      await repository.trashNote(note.id);
    }
    if (!mounted) return;
    setState(() {
      _notes.removeWhere((Note note) => _selection.contains(note.id));
      _selection.exit();
    });
    // Leaving the selection never brings the search back.
    if (_isSearchMode) _exitSearchMode();
    if (selected.notes.isNotEmpty) {
      showUndoDelete(
        context,
        repository: repository,
        batch: DeletedBatch(notes: selected.notes, indexes: selected.indexes),
        onRestored: () async {
          if (!mounted) return;
          setState(() {
            // From the end, so an insertion never shifts a place still to come.
            for (int i = selected.indexes.length - 1; i >= 0; i--) {
              _notes.insert(
                selected.indexes[i].clamp(0, _notes.length),
                selected.notes[i],
              );
            }
          });
        },
      );
    }
  }

  /// Moves the selected notes to [folderId], or back home when null.
  Future<void> _moveTo(String? folderId) async {
    final NotesRepository repository = getIt<NotesRepository>();
    final List<Note> selected = _notes
        .where((Note note) => _selection.contains(note.id))
        .toList();
    for (final Note note in selected) {
      await repository.upsertNote(
        note.copyWith(folderId: folderId, updatedAt: DateTime.now().toString()),
      );
    }
    final int count = selected.length;
    if (!mounted) return;
    setState(_selection.exit);
    // Leaving the selection never brings the search back.
    if (_isSearchMode) _exitSearchMode();
    await _load();
    if (!mounted) return;
    await announceMove(context, count: count, folderId: folderId);
  }

  /// The folder content narrowed by the local search, before the kind filter:
  /// the segmented control counts every kind from here. A locked note never
  /// shows up in the search results.
  List<Note> _filterSource() {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _notes;
    return _notes
        .where(
          (Note note) =>
              NoteAccessPolicy([
                _folder,
              ]).isSearchableInFolder(note, _folder.id) &&
              (note.title.toLowerCase().contains(query) ||
                  note.description.toLowerCase().contains(query) ||
                  note.content.toLowerCase().contains(query)),
        )
        .toList();
  }

  /// How many notes the given view would show right now.
  int _countFor(DocumentFilter filter) =>
      _filterSource().where(filter.matches).length;

  /// Documents a search inside this folder could reach: its notes, locked ones
  /// left out, because search never considers them.
  int get _searchableDocCount =>
      _notes.where((Note note) => !note.isLocked).length;

  /// The filter actually applied. A kind with nothing left to show falls back
  /// to every document, so a preference the tab no longer offers never blanks
  /// the list.
  DocumentFilter get _effectiveDocumentFilter =>
      _documentFilter != DocumentFilter.all && _countFor(_documentFilter) == 0
      ? DocumentFilter.all
      : _documentFilter;

  /// Notes shown: the folder content, filtered by the search and the kind.
  List<Note> get _visibleNotes =>
      _filterSource().where(_effectiveDocumentFilter.matches).toList();

  /// True once the user has actually typed in the search field: only then
  /// does the page switch to the results presentation.
  bool get _resultsVisible => _isSearchMode && _searchStarted;

  /// The recent searches stand in for the results while the field is empty —
  /// the same screen Home offers.
  bool get _showSearchHistory => showSearchHistory(
    isSearchMode: _isSearchMode,
    hasQuery: _searchQuery.trim().isNotEmpty,
  );

  /// The kind tags step aside while a search is on screen, exactly as they do
  /// on Home, and an empty folder has nothing to tag. A selection keeps them:
  /// its sentence is printed there.
  bool get _showFilterTags =>
      _notes.isNotEmpty &&
      (_selection.isActive ||
          (!_showSearchHistory && _searchQuery.trim().isEmpty));

  String _noteCountLabel(int count) =>
      groupCountLabel(total: count, noun: 'note');

  /// Metadata on the title line, mirroring the home page: the selection while
  /// selecting, the result count while searching, the note count otherwise.
  String? get _headerMetadata {
    if (_selection.isActive) {
      // While searching, the total is the number of results.
      final int count = _selection.count;
      final int total = _visibleNotes.length;
      final List<Note> selected = _visibleNotes
          .where((Note note) => _selection.contains(note.id))
          .toList();
      final String noun = selectionNounKey(
        notes: selected.where((Note note) => !note.isTask).length,
        tasks: selected.where((Note note) => note.isTask).length,
        folders: 0,
      );
      return selectionCountLabel(count: count, total: total, noun: noun);
    }
    if (_resultsVisible) return _noteCountLabel(_visibleNotes.length);
    return null;
  }

  Widget _folderFlags(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_folder.isLocked)
        // The lock reads exactly like the bookmark: same size, same outline,
        // same amber.
        metadataGlyph(
          context,
          Symbols.lock,
          color: tanoAmber,
          fill: 0,
          size: 18.0,
        ),
      if (_folder.isLocked && _folder.important) const SizedBox(width: 8),
      if (_folder.important)
        // Bigger and outlined on the title line, so the folder's own mark
        // reads at a glance next to the lock.
        metadataGlyph(
          context,
          Symbols.bookmark,
          color: tanoAmber,
          fill: 0,
          size: 20.0,
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    // The folder's colour tints its own card, not the page.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color immersiveBg = getImmersiveBackgroundColor(isDark: isDark);
    // The folder's FAB always rests in its reduced form; tapping it expands
    // the action bar. This keeps it from hiding the notes or the cover.
    // The recent searches live in a shared controller: the page rebuilds when
    // they change, exactly as Home does.
    return ListenableBuilder(
      listenable: SearchHistoryController.instance,
      builder: (BuildContext context, Widget? child) => ProtectedContent(
        protected: _folder.isLocked,
        child: PageScaffold(
          backgroundColor: immersiveBg,
          // The folder name is always the page title, even in selection mode.
          title: _showSearchHistory
              ? AppText.tr('search_history')
              : (_resultsVisible ? AppText.tr('search_results') : _folder.name),
          // A landscape phone moves the folder title, flags included, to the app
          // bar and drops the body's title line. Home keeps its own.
          condenseHeader: true,

          headerMetadataWidget: _showSearchHistory
              ? clearSearchHistoryButton(context)
              : (!_resultsVisible ? _folderFlags(context) : null),
          // On the reduced title the order is the other way round: the bookmark
          // leads, the title follows, the lock closes the line.
          headerMetadataLeading: _showSearchHistory
              ? clearSearchHistoryButton(context)
              : (!_resultsVisible && _folder.important
                    ? reducedTitleBookmark()
                    : null),
          headerMetadataTrailing:
              !_showSearchHistory && !_resultsVisible && _folder.isLocked
              ? reducedTitleLock()
              : null,
          // Nothing but the illustration: it must hold its place.
          freezeBody: !_loading && _visibleNotes.isEmpty,
          titleWidget: _isEditingTitle
              ? TapRegion(
                  onTapOutside: (_) => _exitTitleEdit(),
                  child: TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    autofocus: true,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 54,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _exitTitleEdit(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: TanoText.pageTitle,
                      letterSpacing: -0.41,
                      color: getTextColor(
                        Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                      counter: Offstage(),
                    ),
                  ),
                )
              : null,
          actions: _selection.isActive
              ? <Widget>[CancelButton(onPressed: _exitSelection)]
              : _isSearchMode
              ? <Widget>[CancelButton(onPressed: _exitSearchMode)]
              : <Widget>[
                  // Search earns its place from the second searchable note:
                  // locked notes do not count, search never reaches them.
                  if (_searchableDocCount > 1)
                    IconButton(
                      icon: const Icon(Symbols.document_search),
                      tooltip: AppText.tr('search'),
                      onPressed: _enterSearchMode,
                    ),
                  const ThemeToggleButton(),
                  // The same menu as Home: a folder adds a note from its FAB, so
                  // the app bar no longer carries an "add note" action.
                  AppBarMenuButton(
                    layout: _viewLayout,
                    onLayout: _changeViewLayout,
                    onLeft: _fabOnLeft,
                    onLeftChanged: _setFabOnLeft,
                    onSettings: _openSettings,
                  ),
                ],
          floatingActionButtonLocation: FlushFabLocation(onLeft: _fabOnLeft),
          // A single, stable FAB for both modes: only the icons animate when the
          // selection mode toggles, the FAB box itself does not move.
          floatingActionButton: AppFab(
            key: _fabKey,
            onLeft: _fabOnLeft,
            // The folder shares the editor's bar (its add/more menus), so it
            // must select it here; isFolderMode then adapts those menus.
            isEditorMode: true,
            isFolderMode: true,
            isSelectionMode: _selection.isActive,
            // Moving needs at least one selected note.
            canMove: _selection.isNotEmpty,
            canDelete: _selection.isNotEmpty,
            isSearchMode: _isSearchMode,
            collapsedByDefault: true,
            controller: _searchController,
            focusNode: _searchFocusNode,
            isImportant: _folder.important,
            isLocked: _folder.isLocked,
            canLock: _canLock,
            isTitleEditing: _isEditingTitle,
            currentCategory: _folder.category,
            currentFolderId: _folder.id,
            onAddNote: () => _openNote(add: true, note: _newNote()),
            onAddTask: () => _openNote(
              add: true,
              note: Task(folderId: _folder.id, category: _folder.category),
            ),
            onColorSelected: (String name) =>
                _save(_folder.copyWith(category: name)),
            onImportantSelected: () =>
                _save(_folder.copyWith(important: !_folder.important)),
            onLockSelected: _toggleLock,
            onDeleteSelected: _delete,
            onEditTitle: _startTitleEdit,
            onSearchChanged: (String value) {
              setState(() {
                _searchQuery = value;
                // Only from the first typed letter does the page switch to the
                // results presentation.
                if (value.trim().isNotEmpty) {
                  _searchStarted = true;
                }
              });
            },
            onReset: _clearSearch,
            onDelete: _deleteSelected,
            onMoveTo: _moveTo,
            onClearSelection: () => setState(_selection.clear),
            onSelectAll: () => setState(
              // Only the notes currently shown (search results included).
              () => _selection.selectAll(
                _visibleNotes.map((Note note) => note.id),
              ),
            ),
          ),
          slivers: <Widget>[
            if (!_loading && _showFilterTags)
              SliverToBoxAdapter(
                child: SectionTitleLine(
                  padding: EdgeInsets.symmetric(
                    horizontal: appSidePad(context, appPaddingLarge),
                  ),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  titleWidget: DocumentFilterControl(
                    value: _effectiveDocumentFilter,
                    countOf: _countFor,
                    // Selecting something replaces the tags with the sentence.
                    selectionLabel: _selection.isActive
                        ? _headerMetadata
                        : null,
                    onChanged: (DocumentFilter filter) {
                      setState(_selection.exit);
                      DocumentFilterController.instance.set(filter);
                    },
                  ),
                ),
              ),
            if (_loading)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (_showSearchHistory)
              SliverPadding(
                // The same frame as the notes above it, so the ruled rows line
                // up with the cards.
                padding: appContentPadding(context),
                sliver: searchHistorySliver(
                  context,
                  onSelected: (String query) {
                    setState(() {
                      _searchController.text = query;
                      _searchQuery = query;
                      _searchStarted = true;
                    });
                  },
                ),
              )
            else
              _buildNotes(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes() {
    final List<Note> notes = _visibleNotes;
    if (notes.isEmpty) {
      return emptyStateSliver(
        context,
        _isSearchMode ? AppText.tr('no_note_found') : AppText.tr('folder_empty'),
        image: _isSearchMode ? EmptyArt.search : EmptyArt.folder,
      );
    }

    final bool isList = _viewLayout == 'list';
    return SliverPadding(
      padding: appContentPadding(context),
      sliver: EntitySliver<Note>(
        items: notes,
        isList: isList,
        cardBuilder: (BuildContext context, Note note) =>
            _card(note, isList: isList),
      ),
    );
  }

  Widget _card(Note note, {required bool isList}) => buildNoteCard(
    note: note,
    isList: isList,
    isSelected: _selection.contains(note.id),
    isInSelectionMode: _selection.isActive,
    activeNoteIds: _activeNoteIds,
    onOpen: () => _openNote(add: false, note: note),
    onToggleSelection: () => _toggleSelection(note.id),
    onEnterSelection: () => _enterSelection(note.id),
  );
}
