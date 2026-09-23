import 'package:tano/shared/widgets/document_filter.dart';
import 'package:tano/core/models/note_access_policy.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/deleted_batch.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/config/card_sorting.dart';
import 'package:tano/shared/controllers/selection_controller.dart';

/// Owns the state and the actions of the home screen.
///
/// The home shows two groups: folders first, then the notes that are not filed
/// in any folder. Folders are invisible to the search.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    required this.repository,
    FoldersRepository? foldersRepository,
    List<Note>? initialNotes,
    List<Folder>? initialFolders,
  }) : _foldersRepository = foldersRepository,
       _allNotes = initialNotes != null
           ? List<Note>.of(initialNotes)
           : <Note>[],
       _folders = initialFolders != null
           ? List<Folder>.of(initialFolders)
           : <Folder>[] {
    _selection = SelectionController(
      isSelectable: (String id) => !_isLockedFolder(id),
    )..addListener(_onSelectionChanged);
    _sort();
  }

  @override
  void dispose() {
    _selection.removeListener(_onSelectionChanged);
    _selection.dispose();
    super.dispose();
  }

  /// Mirrors the selection into the FAB shape.
  void _onSelectionChanged() {
    _actionButtons = _selection.isActive ? 'multiple' : 'add';
    notifyListeners();
  }

  final NotesRepository repository;

  /// Folders storage. Null in the many tests that only provide notes; folders
  /// are then simply empty.
  final FoldersRepository? _foldersRepository;

  DocumentFilter _documentFilter = DocumentFilter.all;

  /// The filter actually applied. A kind with nothing left to show falls back
  /// to every document, so a preference the tab no longer offers never blanks
  /// the list.
  DocumentFilter get documentFilter =>
      _documentFilter != DocumentFilter.all && countFor(_documentFilter) == 0
      ? DocumentFilter.all
      : _documentFilter;

  void setDocumentFilter(DocumentFilter filter) {
    _documentFilter = filter;
    _selection.exit();
    notifyListeners();
  }

  List<Note> _allNotes;
  List<Folder> _folders;
  List<Note>? _searchResults;
  String _searchQuery = '';
  String _sortBy = 'date';
  String _secondarySortBy = 'date';
  bool _sortAscending = true;
  String _viewLayout = 'gridlist';
  late final SelectionController _selection;
  String _actionButtons = 'add';

  /// Notes and folders removed by the last delete, so undo can restore both.
  DeletedBatch? _lastDeleted;

  /// Notes currently displayed: unfiled notes, or the search results.
  List<Note> get notes => List<Note>.unmodifiable(_visibleNotes());

  /// Folders currently displayed (never during a search).
  List<Folder> get folders =>
      hasSearchQuery ? const <Folder>[] : List<Folder>.unmodifiable(_folders);

  bool get hasFolders => folders.isNotEmpty;
  int get notesCount => _visibleNotes().length;

  /// True when the page holds at least one document, the active kind filter
  /// aside: an empty docs group hides its tabs.
  bool get hasDocs => _unfiledNotes().isNotEmpty;

  /// Documents a search from Home could reach: every note, locked ones and the
  /// ones inside a locked folder left out, because search never considers them.
  int get searchableDocsCount {
    final NoteAccessPolicy policy = NoteAccessPolicy(_folders);
    return _allNotes.where(policy.isSearchable).length;
  }

  int get foldersCount => folders.length;

  /// Total selectable items on the home page: unfiled notes plus folders
  /// (notes filed in a folder are not shown here).
  int get itemsCount => notesCount + foldersCount;
  String get sortBy => _sortBy;
  String get secondarySortBy => _secondarySortBy;
  bool get sortAscending => _sortAscending;
  String get viewLayout => _viewLayout;
  bool get isInSelectionMode => _selection.isActive;
  String get actionButtons => _actionButtons;
  bool get hasSelection => _selection.isNotEmpty;
  int get selectedCount => _selection.count;
  Set<String> get selected => _selection.ids;
  bool get hasSearchQuery => _searchQuery.trim().isNotEmpty;

  /// l10n key of the page title: search results, folders or plain notes.
  String get pageTitleKey {
    if (hasSearchQuery) return 'search_results';
    if (hasFolders) return 'my_folders';
    return 'all_docs';
  }

  /// Whether any selected note or folder is locked.
  bool get hasLockedInSelection {
    return _allNotes.any((n) => _selection.contains(n.id) && n.isLocked) ||
        _folders.any((f) => _selection.contains(f.id) && f.isLocked);
  }

  /// Whether [note] should prompt for authentication where it currently is.
  ///
  /// A locked note filed in a locked folder does not: opening the folder
  /// already authenticated. Moving it out makes it locked again, because the
  /// flag itself is never changed.
  bool isNoteEffectivelyLocked(Note note) {
    if (!note.isLocked) return false;
    final Folder? folder = folderOf(note);
    return !(folder != null && folder.isLocked);
  }

  /// Folder a note is filed in, if any.
  Folder? folderOf(Note note) {
    final String? id = note.folderId;
    if (id == null) return null;
    for (final Folder folder in _folders) {
      if (folder.id == id) return folder;
    }
    return null;
  }

  /// IDs of all active (not deleted) notes.
  Set<String> get activeNoteIds =>
      _allNotes.where((n) => !n.isDeleted).map((n) => n.id).toSet();

  /// Loads notes and folders from the repository.
  Future<void> load() async {
    // Copy defensively: a repository may return a list it keeps mutating.
    _allNotes = List<Note>.of(await repository.loadNotes());
    _folders = List<Folder>.of(
      await _foldersRepository?.loadFolders() ?? const <Folder>[],
    );
    if (hasSearchQuery) {
      await _refreshSearch();
    }
    _sort();
    notifyListeners();
  }

  /// Reloads only the folders (the notes were provided by the splash).
  Future<void> loadFolders() async {
    _folders = List<Folder>.of(
      await _foldersRepository?.loadFolders() ?? const <Folder>[],
    );
    _sort();
    notifyListeners();
  }

  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query) return;
    _searchQuery = query;
    if (hasSearchQuery) {
      await _refreshSearch();
    } else {
      _searchResults = null;
    }
    _sort();
    notifyListeners();
  }

  /// Runs the repository search, then drops the locked notes: locked notes are
  /// only searchable from within, with "find in note".
  Future<void> _refreshSearch() async {
    final query = _searchQuery;
    final List<Note> results = await repository.searchNotes(query);
    if (query != _searchQuery) return;
    _searchResults = results
        .where(NoteAccessPolicy(_folders).isSearchable)
        .toList();
  }

  void setViewLayout(String viewLayout) {
    if (viewLayout != 'list' && viewLayout != 'gridlist') return;
    if (_viewLayout == viewLayout) return;
    _viewLayout = viewLayout;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) return;
    _sortBy = sortBy;
    if (sortBy == 'alpha' || sortBy == 'date') {
      _secondarySortBy = sortBy;
    }
    _sort();
    notifyListeners();
  }

  void setSecondarySortBy(String sortBy) {
    if (_secondarySortBy == sortBy) return;
    _secondarySortBy = sortBy;
    _sort();
    notifyListeners();
  }

  void setSortAscending(bool ascending) {
    if (_sortAscending == ascending) return;
    _sortAscending = ascending;
    _sort();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final int noteIndex = _allNotes.indexWhere((Note note) => note.id == id);
    if (noteIndex != -1) {
      final Note note = _allNotes[noteIndex];
      _allNotes[noteIndex] = note.copyWith(
        important: !note.important,
        updatedAt: DateTime.now().toString(),
      );
      repository.upsertNote(_allNotes[noteIndex]);
      _sort();
      notifyListeners();
      return;
    }
    final int folderIndex = _folders.indexWhere((Folder f) => f.id == id);
    if (folderIndex != -1) {
      final Folder folder = _folders[folderIndex];
      _folders[folderIndex] = folder.copyWith(
        important: !folder.important,
        updatedAt: DateTime.now().toString(),
      );
      _foldersRepository?.upsertFolder(_folders[folderIndex]);
      _sort();
      notifyListeners();
    }
  }

  /// A locked folder can never be selected; locked notes still can.
  bool _isLockedFolder(String id) =>
      _folders.any((Folder f) => f.id == id && f.isLocked);

  void enterSelectionMode(String id) => _selection.enter(id);

  void toggleSelection(String id) => _selection.toggle(id);

  void selectAll() {
    _selection.selectAll(<String>[
      for (final Note note in _visibleNotes()) note.id,
      for (final Folder folder in folders) folder.id,
    ]);
  }

  void clearSelection() => _selection.clear();

  void exitSelectionMode() => _selection.exit();

  /// Whether the selection contains a folder, which cannot be moved.
  bool get hasFolderInSelection =>
      _folders.any((Folder f) => _selection.contains(f.id));

  /// Number of selected notes currently shown on the home page.
  int get selectedNotesCount =>
      _visibleNotes().where((Note n) => _selection.contains(n.id)).length;

  /// Number of selected folders.
  int get selectedFoldersCount =>
      folders.where((Folder f) => _selection.contains(f.id)).length;

  /// The selected documents, split by kind: the selection sentence names what
  /// is actually selected.
  int get selectedPlainNotesCount => _visibleNotes()
      .where((Note n) => !n.isTask && _selection.contains(n.id))
      .length;

  int get selectedTaskCount => _visibleNotes()
      .where((Note n) => n.isTask && _selection.contains(n.id))
      .length;

  /// The noun the selection sentence uses: the kind selected keeps its name, a
  /// mix of kinds — a folder counted in — falls back to "docs".
  String get selectionNoun => selectionNounKey(
    notes: selectedPlainNotesCount,
    tasks: selectedTaskCount,
    folders: selectedFoldersCount,
  );

  bool get hasNoteInSelection => selectedNotesCount > 0;

  /// True when the selection mixes notes and folders.
  bool get hasMixedSelection => hasNoteInSelection && hasFolderInSelection;

  /// Total number of notes held by the selected folders, for the delete
  /// confirmation.
  int get selectedFoldersNoteCount {
    int count = 0;
    for (final Folder folder in _folders) {
      if (_selection.contains(folder.id)) {
        count += noteCountIn(folder.id);
      }
    }
    return count;
  }

  Future<void> deleteSelected() async {
    final List<Note> removed = <Note>[];
    final List<int> indexes = <int>[];
    final List<Folder> deletedFolders = _folders
        .where((Folder f) => _selection.contains(f.id))
        .toList();

    // The folder keeps its notes: they stay filed and travel with it.
    for (final Folder folder in deletedFolders) {
      await _foldersRepository?.trashFolder(folder.id);
    }
    _folders.removeWhere((Folder f) => _selection.contains(f.id));

    for (int i = 0; i < _allNotes.length; i++) {
      if (_selection.contains(_allNotes[i].id)) {
        removed.add(_allNotes[i]);
        indexes.add(i);
        await repository.trashNote(_allNotes[i].id);
      }
    }
    _allNotes.removeWhere((Note note) => _selection.contains(note.id));
    _lastDeleted = DeletedBatch(
      notes: removed,
      indexes: indexes,
      folders: deletedFolders,
    );
    _selection.exit();
  }

  /// Moves the selected notes into [folderId], or unfiles them when null.
  Future<void> moveSelectedTo(String? folderId) async {
    for (int i = 0; i < _allNotes.length; i++) {
      if (!_selection.contains(_allNotes[i].id)) continue;
      final Note moved =
          (folderId == null
                  ? _allNotes[i].withoutFolder()
                  : _allNotes[i].copyWith(folderId: folderId))
              .copyWith(updatedAt: DateTime.now().toString());
      _allNotes[i] = moved;
      await repository.upsertNote(moved);
    }
    _sort();
    _selection.exit();
  }

  Future<void> removeNote(String id) async {
    final int index = _allNotes.indexWhere((Note note) => note.id == id);
    if (index == -1) return;
    final Note note = _allNotes[index];
    await repository.trashNote(id);
    _allNotes.removeAt(index);
    _lastDeleted = DeletedBatch(notes: <Note>[note], indexes: <int>[index]);
    notifyListeners();
  }

  /// What the last delete removed, or null when there is nothing to put back.
  DeletedBatch? get lastDeletedBatch => _lastDeleted;

  /// Puts the last deletion back on screen.
  ///
  /// Storage is restored by the batch itself, through [showUndoDelete]: this only
  /// reinserts in the visible list and forgets.
  Future<void> reinsertLastDeleted() async {
    final DeletedBatch? batch = _lastDeleted;
    if (batch == null) return;
    for (int i = 0; i < batch.notes.length; i++) {
      final Note note = batch.notes[i];
      final int index = batch.indexes[i] > _allNotes.length
          ? _allNotes.length
          : batch.indexes[i];
      _allNotes.insert(index, note.copyWith(isDeleted: false, deletedAt: null));
    }
    for (final Folder folder in batch.folders) {
      _folders.add(folder.copyWith(isDeleted: false));
    }
    _sort();
    _lastDeleted = null;
    notifyListeners();
  }

  /// Creates a folder. The page only submits a non-blank [name]: there is no
  /// "Folder X" fallback any more.
  Future<Folder> addFolder(String name) async {
    final Folder folder = Folder(
      id: const Uuid().v4(),
      name: name.trim(),
      date: DateTime.now().toString(),
    );
    await _foldersRepository?.upsertFolder(folder);
    _folders.add(folder);
    _sort();
    notifyListeners();
    return folder;
  }

  /// Persists a folder change (name, theme, cover, lock…).
  Future<void> saveFolder(Folder folder) async {
    final Folder updated = folder.copyWith(
      updatedAt: DateTime.now().toString(),
    );
    final int index = _folders.indexWhere((Folder f) => f.id == updated.id);
    if (index != -1) {
      _folders[index] = updated;
    } else {
      _folders.add(updated);
    }
    await _foldersRepository?.upsertFolder(updated);
    _sort();
    notifyListeners();
  }

  /// Notes filed in [folderId], sorted with the current criteria.
  List<Note> notesInFolder(String folderId) {
    return _allNotes.where((Note n) => n.folderId == folderId).toList();
  }

  /// Number of notes filed in [folderId].
  int noteCountIn(String folderId) =>
      _allNotes.where((Note n) => n.folderId == folderId).length;

  Future<void> applyNoteAction({
    required bool add,
    required String originalId,
    required NoteAction action,
  }) async {
    switch (action.kind) {
      case NoteActionKind.save:
        if (add) {
          _allNotes.add(action.note!);
        } else {
          final int index = _allNotes.indexWhere(
            (Note note) => note.id == originalId,
          );
          if (index != -1) {
            _allNotes[index] = action.note!;
          }
        }
        await repository.upsertNote(action.note!);
        break;
      case NoteActionKind.delete:
        final int index = _allNotes.indexWhere(
          (Note note) => note.id == originalId,
        );
        if (index != -1) {
          final Note removed = _allNotes.removeAt(index);
          await repository.trashNote(originalId);
          _lastDeleted = DeletedBatch(
            notes: <Note>[removed],
            indexes: <int>[index],
          );
        }
        break;
      case NoteActionKind.cancel:
        break;
    }
    notifyListeners();
  }

  /// The documents the current screen would show for [filter], without
  /// changing the active one: the segmented control prints every count.
  int countFor(DocumentFilter filter) =>
      _sourceNotes().where(filter.matches).length;

  List<Note> _sourceNotes() =>
      hasSearchQuery ? (_searchResults ?? <Note>[]) : _unfiledNotes();

  List<Note> _visibleNotes() =>
      _sourceNotes().where(documentFilter.matches).toList();

  List<Note> _unfiledNotes() =>
      _allNotes.where((Note note) => note.folderId == null).toList();

  void _sort() {
    _allNotes.sort(
      NoteSorting(
        by: _sortBy,
        secondaryBy: _secondarySortBy,
        ascending: _sortAscending,
      ).compare,
    );
    _folders.sort(_compareFolders);
  }

  int _compareFolders(Folder a, Folder b) => EntitySorting<Folder>(
    by: _sortBy,
    secondaryBy: _secondarySortBy,
    ascending: _sortAscending,
  ).compare(a, b);
}
