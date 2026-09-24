import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/archive/archive_view_model.dart';
import 'package:tano/features/editor/open_editor.dart';
import 'package:tano/shared/config/card_sorting.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/config/document_filter_controller.dart';
import 'package:tano/shared/config/fab_side_controller.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/search_history_controller.dart';
import 'package:tano/shared/config/search_mode.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/sort_preferences_controller.dart';
import 'package:tano/shared/config/view_layout_controller.dart';
import 'package:tano/shared/controllers/selection_controller.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/document_filter.dart';
import 'package:tano/shared/widgets/empty_state.dart';
import 'package:tano/shared/widgets/entity_card_actions.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/search_history.dart';
import 'package:tano/shared/widgets/storage_recovery.dart';
import 'package:tano/shared/widgets/theme.dart';

/// The archive: the documents set aside out of Home and their folders.
///
/// It reuses the folder page's organisation (grid or list, sorting, document
/// filter, search) for documents only, and the trash's per-card actions.
class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  late final ArchiveViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SelectionController _selection = SelectionController();

  bool _loading = true;
  bool _isSearchMode = false;
  bool _searchStarted = false;
  String _searchQuery = '';
  String _sortBy = 'date';
  String _secondarySortBy = 'date';
  bool _sortAscending = true;

  /// The layout is the shared controller Home and a folder already use.
  String get _viewLayout => ViewLayoutController.instance.layout;

  /// The FAB's side, shared with the other pages.
  bool get _fabOnLeft => FabSideController.instance.onLeft;

  /// The shared kind filter; the archive shows the same tabs.
  DocumentFilter get _documentFilter =>
      DocumentFilterController.instance.filter;

  @override
  void initState() {
    super.initState();
    _viewModel = ArchiveViewModel(repository: getIt<NotesRepository>());
    ViewLayoutController.instance.addListener(_onExternalChange);
    SortPreferencesController.instance.addListener(_onExternalChange);
    DocumentFilterController.instance.addListener(_onExternalChange);
    FabSideController.instance.addListener(_onExternalChange);
    _loadPreferences();
    _load();
  }

  @override
  void dispose() {
    ViewLayoutController.instance.removeListener(_onExternalChange);
    SortPreferencesController.instance.removeListener(_onExternalChange);
    DocumentFilterController.instance.removeListener(_onExternalChange);
    FabSideController.instance.removeListener(_onExternalChange);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _selection.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onExternalChange() {
    if (!mounted) return;
    setState(_syncSort);
  }

  Future<void> _loadPreferences() async {
    await SortPreferencesController.instance.load();
    await DocumentFilterController.instance.load();
    await ViewLayoutController.instance.load();
    await FabSideController.instance.load();
    if (mounted) setState(_syncSort);
  }

  void _syncSort() {
    final SortPreferencesController sort = SortPreferencesController.instance;
    _sortBy = sort.by;
    _secondarySortBy = sort.secondaryBy;
    _sortAscending = sort.ascending;
  }

  Future<void> _load() async {
    await _viewModel.load();
    if (mounted) setState(() => _loading = false);
  }

  List<Note> _sorted(List<Note> notes) => NoteSorting(
    by: _sortBy,
    secondaryBy: _secondarySortBy,
    ascending: _sortAscending,
  ).sort(notes);

  /// The archive narrowed by the local search. A locked document never shows up
  /// in the results, exactly as everywhere else.
  List<Note> _filterSource() {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _viewModel.docs;
    return _viewModel.docs
        .where((Note note) => !note.isLocked && noteMatchesQuery(note, query))
        .toList();
  }

  int _countFor(DocumentFilter filter) =>
      _filterSource().where(filter.matches).length;

  /// Documents a search could reach: locked ones left out.
  int get _searchableDocCount =>
      _viewModel.docs.where((Note note) => !note.isLocked).length;

  DocumentFilter get _effectiveDocumentFilter =>
      _documentFilter != DocumentFilter.all && _countFor(_documentFilter) == 0
      ? DocumentFilter.all
      : _documentFilter;

  List<Note> get _visibleNotes =>
      _sorted(_filterSource().where(_effectiveDocumentFilter.matches).toList());

  bool get _resultsVisible => _isSearchMode && _searchStarted;

  bool get _showSearchHistory => showSearchHistory(
    isSearchMode: _isSearchMode,
    hasQuery: _searchQuery.trim().isNotEmpty,
  );

  bool get _showFilterTags =>
      _viewModel.docs.isNotEmpty &&
      (_selection.isActive ||
          (!_showSearchHistory && _searchQuery.trim().isEmpty));

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

  void _enterSelection() => setState(_selection.begin);

  void _exitSelection() => setState(_selection.exit);

  /// Opens an archived document read-only. Nothing can be changed there.
  Future<void> _open(Note note) async {
    if (_isSearchMode) _exitSearchMode();
    await openNoteEditor(
      context,
      add: false,
      note: note,
      authenticated: false,
      requiresAuthentication: note.isLocked,
      readOnly: true,
    );
    if (mounted) await _load();
  }

  Future<void> _unarchive(List<String> ids) async {
    if (ids.isEmpty) return;
    final bool restored = await runStorageOperation(
      context,
      () => _viewModel.restore(ids),
    );
    if (!restored || !mounted) return;
    setState(_selection.exit);
    await _load();
  }

  Future<void> _delete(List<String> ids) async {
    if (ids.isEmpty) return;
    final bool hasLocked = _viewModel.docs.any(
      (Note note) => ids.contains(note.id) && note.isLocked,
    );
    if (hasLocked && !await confirmLockedDeletion(context)) return;
    if (!mounted) return;
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: deleteSelectionTitle(
        count: ids.length,
        total: _viewModel.docs.length,
      ),
      action: AppText.tr('delete'),
    );
    if (confirm != true || !mounted) return;
    // Deleting from the archive moves the documents to the trash, where they
    // stay restorable; nothing is destroyed here.
    final bool trashed = await runStorageOperation(
      context,
      () => _viewModel.trash(ids),
    );
    if (!trashed || !mounted) return;
    setState(_selection.exit);
  }

  List<Widget> _actions() {
    if (_selection.isActive) {
      return <Widget>[
        IconButton(
          icon: const Icon(Symbols.unarchive),
          tooltip: AppText.tr('unarchive'),
          onPressed: _selection.isEmpty ? null : () => _unarchive(_selectedIds),
        ),
        // Leave the selection without touching anything.
        IconButton(
          icon: const Icon(Symbols.close),
          tooltip: AppText.tr('cancel'),
          onPressed: _exitSelection,
        ),
        IconButton(
          icon: Icon(Symbols.delete, color: TanoStates.error.dark),
          tooltip: AppText.tr('delete'),
          onPressed: _selection.isEmpty ? null : () => _delete(_selectedIds),
        ),
      ];
    }
    if (_isSearchMode) {
      return <Widget>[CancelButton(onPressed: _exitSearchMode)];
    }
    return <Widget>[
      // Search earns its place from the second searchable document.
      if (_searchableDocCount > 1)
        IconButton(
          icon: const Icon(Symbols.document_search),
          tooltip: AppText.tr('search'),
          onPressed: _enterSearchMode,
        ),
      // Selecting earns its place from the second document, like search.
      if (_viewModel.docs.length > 1)
        IconButton(
          icon: const Icon(Symbols.select_all),
          tooltip: AppText.tr('select'),
          onPressed: _enterSelection,
        ),
    ];
  }

  List<String> get _selectedIds => _visibleNotes
      .where((Note note) => _selection.contains(note.id))
      .map((Note note) => note.id)
      .toList();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _viewModel,
        SearchHistoryController.instance,
      ]),
      builder: (BuildContext context, Widget? _) {
        return PageScaffold(
          title: _showSearchHistory
              ? AppText.tr('search_history')
              : (_resultsVisible
                    ? AppText.tr('search_results')
                    : AppText.tr('option_archive')),
          // The archive title line carries no metadata.
          actions: _actions(),
          onPop: _selection.isActive ? _exitSelection : null,
          floatingActionButtonLocation: FlushFabLocation(onLeft: _fabOnLeft),
          // The search FAB zooms in and out. It stays in the tree, scaled to
          // zero when the search is closed, so both transitions are animated.
          floatingActionButton: IgnorePointer(
            ignoring: !_isSearchMode,
            child: AnimatedScale(
              scale: _isSearchMode ? 1.0 : 0.0,
              duration: TanoMotion.base,
              curve: Curves.easeInOutBack,
              child: AppFab(
                onLeft: _fabOnLeft,
                isSearchMode: true,
                controller: _searchController,
                focusNode: _searchFocusNode,
                onSearchChanged: (String value) {
                  setState(() {
                    _searchQuery = value;
                    if (value.trim().isNotEmpty) _searchStarted = true;
                  });
                },
                onReset: _clearSearch,
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
        );
      },
    );
  }

  Widget _buildNotes() {
    final List<Note> notes = _visibleNotes;
    if (notes.isEmpty) {
      return emptyStateSliver(
        context,
        _isSearchMode
            ? AppText.tr('no_note_found')
            : AppText.tr('archive_empty'),
        image: _isSearchMode ? EmptyArt.search : EmptyArt.box,
      );
    }
    final bool isList = _viewLayout == 'list';
    return SliverPadding(
      padding: appContentPadding(context),
      sliver: EntitySliver<Note>(
        items: notes,
        isList: isList,
        cardBuilder: (BuildContext context, Note note) =>
            _card(context, note, isList: isList),
      ),
    );
  }

  Widget _card(BuildContext context, Note note, {required bool isList}) {
    // An archived document shows when it was archived, not when it was created.
    final String date = formatNoteDate(note.archivedAt ?? note.date);
    return Stack(
      children: <Widget>[
        buildNoteCard(
          note: note,
          isList: isList,
          isSelected: _selection.contains(note.id),
          isInSelectionMode: _selection.isActive,
          activeNoteIds: _viewModel.activeNoteIds,
          dateText: date,
          dateIcon: Symbols.archive,
          onOpen: () => _open(note),
          onToggleSelection: () => setState(() => _selection.toggle(note.id)),
          onEnterSelection: () => setState(() => _selection.enter(note.id)),
        ),
        // The same two actions as the trash, always there.
        EntityCardActions(
          isListLayout: isList,
          onRestore: () => _unarchive(<String>[note.id]),
          onDelete: () => _delete(<String>[note.id]),
          textColor: cardTextColor(context, note.category),
        ),
      ],
    );
  }
}
