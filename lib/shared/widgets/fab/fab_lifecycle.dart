part of 'app_fab.dart';

/// Adapts page inputs and asynchronous data to the synchronous presentation.
/// All mutations happen in lifecycle methods or explicit actions, never build.
mixin _FabStateMixin on State<AppFab> {
  late final FabPresentation _presentation;
  FabVerticalMenu get _verticalMenu => _presentation.menu;
  FabMode get _mode {
    if (widget.isFindMode) return FabMode.find;
    if (widget.isSelectionMode) return FabMode.selection;
    if (widget.isSearchMode) return FabMode.search;
    if (widget.isFolderMode) return FabMode.folder;
    if (widget.isEditorMode) return FabMode.editor;
    return FabMode.home;
  }

  List<Note> _availableNotes = [];
  List<Folder> _availableFolders = [];
  bool _notesLoaded = false;
  bool _foldersLoaded = false;
  bool _notesLoading = false;
  bool _foldersLoading = false;
  bool _notesFailed = false;
  bool _foldersFailed = false;
  bool _hasFolders = false;
  int _requestGeneration = 0;
  double _measuredMenuHeight = 0;
  ListSortCriteria _sortCriteria = ListSortCriteria.date;
  bool _isAscending = true;
  bool _layoutReportPending = false;

  @override
  void initState() {
    super.initState();
    _presentation = FabPresentation(
      mode: _mode,
      initiallyCollapsed: widget.isEditorMode && widget.isAddMode,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reconcile();
    _scheduleLayoutReport();
  }

  @override
  void didUpdateWidget(covariant AppFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changedContext =
        oldWidget.currentNoteId != widget.currentNoteId ||
        oldWidget.currentFolderId != widget.currentFolderId ||
        oldWidget.isTaskMode != widget.isTaskMode;
    if (changedContext) {
      _invalidateRequests();
      _presentation.closeMenu();
      _availableNotes = [];
      _availableFolders = [];
      _notesLoaded = _foldersLoaded = false;
    }
    _reconcile();
    if (oldWidget.onLeft != widget.onLeft) _scheduleLayoutReport();
  }

  void _reconcile() {
    final previousMenu = _verticalMenu;
    final previousMode = _presentation.mode;
    _presentation.reconcile(
      mode: _mode,
      keyboardOpen: MediaQuery.viewInsetsOf(context).bottom > 0,
      titleEditing: widget.isTitleEditing,
      collapsedByDefault: widget.collapsedByDefault,
      canMove: widget.canMove,
    );
    if (previousMenu != _verticalMenu || previousMode != _mode) {
      _invalidateRequests();
    }
  }

  void _invalidateRequests() {
    _requestGeneration++;
    _notesLoading = _foldersLoading = false;
  }

  void collapse() {
    if (!mounted) return;
    setState(() {
      _invalidateRequests();
      _presentation.collapse();
    });
  }

  void _expand() => setState(_presentation.expand);

  void closeVerticalMenu() {
    if (!mounted) return;
    setState(() {
      _invalidateRequests();
      _presentation.closeMenu();
    });
  }

  void _showMenu(FabVerticalMenu menu) {
    setState(() {
      _invalidateRequests();
      _presentation.openMenu(menu);
    });
    _refreshMenuData();
  }

  void _toggleVerticalMenu(FabVerticalMenu menu) {
    setState(() {
      _invalidateRequests();
      _presentation.toggleMenu(menu);
    });
    _refreshMenuData();
  }

  void _openMoveMenu(FabVerticalMenu returnTo) {
    setState(() {
      _invalidateRequests();
      _presentation.openMove(returnTo);
    });
    _refreshMenuData();
  }

  void _refreshMenuData() {
    switch (_verticalMenu) {
      case FabVerticalMenu.add:
      case FabVerticalMenu.link:
        if (!widget.isFolderMode) unawaited(_loadNotes());
      case FabVerticalMenu.more:
        if (!widget.isFolderMode) unawaited(_loadFolders());
      case FabVerticalMenu.move:
        unawaited(_loadFolders());
      default:
        break;
    }
  }

  bool _currentRequest(int generation) =>
      mounted && generation == _requestGeneration;

  Future<void> _loadNotes() async {
    if (_notesLoading) return;
    final generation = _requestGeneration;
    setState(() {
      _notesLoading = true;
      _notesFailed = false;
    });
    try {
      final notes = getIt.isRegistered<NotesRepository>()
          ? await getIt<NotesRepository>().loadNotes()
          : const <Note>[];
      if (!_currentRequest(generation)) return;
      setState(() {
        _availableNotes = notes
            .where(
              (note) =>
                  note.id != widget.currentNoteId &&
                  !note.isDeleted &&
                  (!widget.isTaskMode || !note.isTask),
            )
            .toList();
        _notesLoaded = true;
        _notesLoading = false;
      });
    } catch (_) {
      if (!_currentRequest(generation)) return;
      setState(() {
        _notesLoading = false;
        _notesFailed = true;
      });
    }
  }

  Future<void> _loadFolders() async {
    if (_foldersLoading) return;
    final generation = _requestGeneration;
    setState(() {
      _foldersLoading = true;
      _foldersFailed = false;
    });
    try {
      final repository = getIt.isRegistered<NotesRepository>()
          ? getIt<NotesRepository>()
          : null;
      final folders = repository is FoldersRepository
          ? await (repository as FoldersRepository).loadFolders()
          : const <Folder>[];
      if (!_currentRequest(generation)) return;
      setState(() {
        _hasFolders = folders.isNotEmpty;
        _availableFolders = folders
            .where((folder) => folder.id != widget.currentFolderId)
            .toList();
        _foldersLoaded = true;
        _foldersLoading = false;
      });
    } catch (_) {
      if (!_currentRequest(generation)) return;
      setState(() {
        _foldersLoading = false;
        _foldersFailed = true;
      });
    }
  }

  void _menuMeasured(Size size) {
    if (!mounted || _verticalMenu == FabVerticalMenu.none) return;
    if ((size.height - _measuredMenuHeight).abs() > .5) {
      setState(() => _measuredMenuHeight = size.height);
    }
  }

  void _scheduleLayoutReport() {
    if (_layoutReportPending || widget.onLayoutChanged == null) return;
    _layoutReportPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _layoutReportPending = false;
      if (mounted) widget.onLayoutChanged?.call();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _reportSettledLayout() => _scheduleLayoutReport();
}
