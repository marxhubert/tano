import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/action.dart';

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
  })  : _foldersRepository = foldersRepository,
        _allNotes = initialNotes != null ? List<Note>.of(initialNotes) : <Note>[],
        _folders =
            initialFolders != null ? List<Folder>.of(initialFolders) : <Folder>[] {
    _sort();
  }

  final NotesRepository repository;

  /// Folders storage. Null in the many tests that only provide notes; folders
  /// are then simply empty.
  final FoldersRepository? _foldersRepository;

  List<Note> _allNotes;
  List<Folder> _folders;
  List<Note>? _searchResults;
  String _searchQuery = '';
  String _sortBy = 'date';
  String _secondarySortBy = 'date';
  bool _sortAscending = true;
  String _viewLayout = 'gridlist';
  bool _isInSelectionMode = false;
  final Set<String> _selected = <String>{};
  String _actionButtons = 'add';
  (List<Note>, List<int>)? _lastDeleted;

  /// Notes currently displayed: unfiled notes, or the search results.
  List<Note> get notes => List<Note>.unmodifiable(_visibleNotes());

  /// Folders currently displayed (never during a search).
  List<Folder> get folders =>
      hasSearchQuery ? const <Folder>[] : List<Folder>.unmodifiable(_folders);

  bool get hasFolders => folders.isNotEmpty;
  int get notesCount => _visibleNotes().length;
  int get foldersCount => folders.length;

  /// Total selectable items on the home page: unfiled notes plus folders
  /// (notes filed in a folder are not shown here).
  int get itemsCount => notesCount + foldersCount;
  String get sortBy => _sortBy;
  String get secondarySortBy => _secondarySortBy;
  bool get sortAscending => _sortAscending;
  String get viewLayout => _viewLayout;
  bool get isInSelectionMode => _isInSelectionMode;
  String get actionButtons => _actionButtons;
  bool get hasSelection => _selected.isNotEmpty;
  int get selectedCount => _selected.length;
  Set<String> get selected => _selected;
  bool get hasSearchQuery => _searchQuery.trim().isNotEmpty;

  /// l10n key of the page title: search results, folders or plain notes.
  String get pageTitleKey {
    if (hasSearchQuery) return 'search_results';
    if (hasFolders) return 'my_folders';
    return 'all_notes';
  }

  /// Whether any selected note or folder is locked.
  bool get hasLockedInSelection {
    return _allNotes.any((n) => _selected.contains(n.id) && n.isLocked) ||
        _folders.any((f) => _selected.contains(f.id) && f.isLocked);
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
    final List<Note> results = await repository.searchNotes(_searchQuery);
    _searchResults =
        results.where((Note n) => !n.isLocked).toList(growable: true);
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
      _allNotes[noteIndex] = note.copyWith(important: !note.important);
      repository.upsertNote(_allNotes[noteIndex]);
      notifyListeners();
      return;
    }
    final int folderIndex = _folders.indexWhere((Folder f) => f.id == id);
    if (folderIndex != -1) {
      final Folder folder = _folders[folderIndex];
      _folders[folderIndex] = folder.copyWith(important: !folder.important);
      _foldersRepository?.upsertFolder(_folders[folderIndex]);
      notifyListeners();
    }
  }

  /// A locked folder can never be selected; locked notes still can.
  bool _isLockedFolder(String id) =>
      _folders.any((Folder f) => f.id == id && f.isLocked);

  void enterSelectionMode(String id) {
    if (_isLockedFolder(id)) return;
    _selected.add(id);
    _isInSelectionMode = true;
    _actionButtons = 'multiple';
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (_isLockedFolder(id)) return;
    if (!_selected.remove(id)) {
      _selected.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    for (final Note note in _visibleNotes()) {
      _selected.add(note.id);
    }
    // A locked folder is not selectable.
    for (final Folder folder in folders) {
      if (!folder.isLocked) _selected.add(folder.id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selected.clear();
    notifyListeners();
  }

  void exitSelectionMode() {
    _selected.clear();
    _isInSelectionMode = false;
    _actionButtons = 'add';
    notifyListeners();
  }

  /// Whether the selection contains a folder, which cannot be moved.
  bool get hasFolderInSelection =>
      _folders.any((Folder f) => _selected.contains(f.id));

  /// Number of selected notes currently shown on the home page.
  int get selectedNotesCount =>
      _visibleNotes().where((Note n) => _selected.contains(n.id)).length;

  /// Number of selected folders.
  int get selectedFoldersCount =>
      folders.where((Folder f) => _selected.contains(f.id)).length;

  bool get hasNoteInSelection => selectedNotesCount > 0;

  /// True when the selection mixes notes and folders.
  bool get hasMixedSelection =>
      hasNoteInSelection && hasFolderInSelection;

  /// Total number of notes held by the selected folders, for the delete
  /// confirmation.
  int get selectedFoldersNoteCount {
    int count = 0;
    for (final Folder folder in _folders) {
      if (_selected.contains(folder.id)) {
        count += noteCountIn(folder.id);
      }
    }
    return count;
  }

  Future<void> deleteSelected() async {
    final List<Note> removed = <Note>[];
    final List<int> indexes = <int>[];
    final Set<String> folderIds = _folders
        .where((Folder f) => _selected.contains(f.id))
        .map((Folder f) => f.id)
        .toSet();

    // Deleting a folder deletes its content too.
    for (final String folderId in folderIds) {
      final List<Note> children =
          _allNotes.where((Note n) => n.folderId == folderId).toList();
      for (final Note note in children) {
        await repository.trashNote(note.id);
      }
      _allNotes.removeWhere((Note n) => n.folderId == folderId);
      await _foldersRepository?.trashFolder(folderId);
    }
    _folders.removeWhere((Folder f) => folderIds.contains(f.id));

    for (int i = 0; i < _allNotes.length; i++) {
      if (_selected.contains(_allNotes[i].id)) {
        removed.add(_allNotes[i]);
        indexes.add(i);
        await repository.trashNote(_allNotes[i].id);
      }
    }
    _allNotes.removeWhere((Note note) => _selected.contains(note.id));
    _lastDeleted = (removed, indexes);
    _selected.clear();
    _isInSelectionMode = false;
    _actionButtons = 'add';
    notifyListeners();
  }

  /// Moves the selected notes into [folderId], or unfiles them when null.
  Future<void> moveSelectedTo(String? folderId) async {
    for (int i = 0; i < _allNotes.length; i++) {
      if (!_selected.contains(_allNotes[i].id)) continue;
      final Note moved = folderId == null
          ? _allNotes[i].withoutFolder()
          : _allNotes[i].copyWith(folderId: folderId);
      _allNotes[i] = moved;
      await repository.upsertNote(moved);
    }
    _sort();
    _selected.clear();
    _isInSelectionMode = false;
    _actionButtons = 'add';
    notifyListeners();
  }

  Future<void> removeNote(String id) async {
    final int index = _allNotes.indexWhere((Note note) => note.id == id);
    if (index == -1) return;
    final Note note = _allNotes[index];
    await repository.trashNote(id);
    _allNotes.removeAt(index);
    _lastDeleted = (<Note>[note], <int>[index]);
    notifyListeners();
  }

  Future<void> undoLastDelete() async {
    final (List<Note>, List<int>)? record = _lastDeleted;
    if (record == null) return;
    final List<Note> notesToRestore = record.$1;
    final List<int> originalIndexes = record.$2;
    for (int i = 0; i < notesToRestore.length; i++) {
      final Note note = notesToRestore[i];
      await repository.restoreNote(note.id);
      final int index =
          originalIndexes[i] > _allNotes.length ? _allNotes.length : originalIndexes[i];
      _allNotes.insert(index, note.copyWith(isDeleted: false, deletedAt: null));
    }
    _lastDeleted = null;
    notifyListeners();
  }

  Future<void> togglePin(String id) async {
    final int folderIndex = _folders.indexWhere((Folder f) => f.id == id);
    if (folderIndex != -1) {
      await _foldersRepository?.toggleFolderPin(id);
      final Folder folder = _folders[folderIndex];
      _folders[folderIndex] = folder.copyWith(isPinned: !folder.isPinned);
      _sort();
      notifyListeners();
      return;
    }
    final int index = _allNotes.indexWhere((Note note) => note.id == id);
    if (index == -1) return;
    await repository.togglePin(id);
    final Note note = _allNotes[index];
    _allNotes[index] = note.copyWith(isPinned: !note.isPinned);
    _sort();
    notifyListeners();
  }

  /// Creates a folder. An empty [name] falls back to "Folder X".
  Future<Folder> addFolder(String name) async {
    final String trimmed = name.trim();
    final String folderName = trimmed.isNotEmpty
        ? trimmed
        : await _foldersRepository?.nextFolderName() ?? 'Folder 1';
    final Folder folder = Folder(
      id: const Uuid().v4(),
      name: folderName,
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
    final int index = _folders.indexWhere((Folder f) => f.id == folder.id);
    if (index != -1) {
      _folders[index] = folder;
    } else {
      _folders.add(folder);
    }
    await _foldersRepository?.upsertFolder(folder);
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
          _lastDeleted = (<Note>[removed], <int>[index]);
        }
        break;
      case NoteActionKind.cancel:
        break;
    }
    notifyListeners();
  }

  List<Note> _visibleNotes() {
    final List<Note> source =
        hasSearchQuery ? (_searchResults ?? <Note>[]) : _unfiledNotes();
    return List<Note>.of(source);
  }

  List<Note> _unfiledNotes() =>
      _allNotes.where((Note note) => note.folderId == null).toList();

  void _sort() {
    _allNotes.sort(_compareNotes);
    _folders.sort(_compareFolders);
  }

  int _compareNotes(Note note1, Note note2) {
    return _compareEntities(
      pinned1: note1.isPinned,
      pinned2: note2.isPinned,
      compare: () => _compare(note1, note2, _sortBy),
      fallbackCompare: () => _compare(note1, note2, _secondarySortBy),
      dateCompare: () => _compare(note1, note2, 'date'),
    );
  }

  int _compareFolders(Folder folder1, Folder folder2) {
    return _compareEntities(
      pinned1: folder1.isPinned,
      pinned2: folder2.isPinned,
      compare: () => _compareFolder(folder1, folder2, _sortBy),
      fallbackCompare: () => _compareFolder(folder1, folder2, _secondarySortBy),
      dateCompare: () => _compareFolder(folder1, folder2, 'date'),
    );
  }

  int _compareEntities({
    required bool pinned1,
    required bool pinned2,
    required int Function() compare,
    required int Function() fallbackCompare,
    required int Function() dateCompare,
  }) {
    if (pinned1 && !pinned2) return -1;
    if (!pinned1 && pinned2) return 1;

    int comparison = compare();
    if (comparison == 0 && (_sortBy == 'important' || _sortBy == 'theme')) {
      comparison = fallbackCompare();
    }
    if (comparison == 0 && _sortBy != 'date' && _secondarySortBy != 'date') {
      comparison = dateCompare();
    }
    return _sortAscending ? comparison : -comparison;
  }

  int _compare(Note note1, Note note2, String criteria) {
    switch (criteria) {
      case 'alpha':
        return note1.title.toLowerCase().compareTo(note2.title.toLowerCase());
      case 'date':
        return note2.date.compareTo(note1.date);
      case 'important':
        final int a = note1.important ? 1 : 0;
        final int b = note2.important ? 1 : 0;
        return b.compareTo(a);
      case 'theme':
      case 'category':
        return _themeWeight(note1.category)
            .compareTo(_themeWeight(note2.category));
      default:
        return 0;
    }
  }

  int _compareFolder(Folder folder1, Folder folder2, String criteria) {
    switch (criteria) {
      case 'alpha':
        return folder1.name.toLowerCase().compareTo(folder2.name.toLowerCase());
      case 'date':
        return folder2.date.compareTo(folder1.date);
      case 'important':
        final int a = folder1.important ? 1 : 0;
        final int b = folder2.important ? 1 : 0;
        return b.compareTo(a);
      case 'theme':
      case 'category':
        return _themeWeight(folder1.category)
            .compareTo(_themeWeight(folder2.category));
      default:
        return 0;
    }
  }

  int _themeWeight(String theme) {
    switch (theme) {
      case 'menthe': return 0;
      case 'citron': return 1;
      case 'peche': return 2;
      case 'lavande': return 3;
      case 'rose': return 4;
      case 'azur': return 5;
      case 'sable': return 6;
      case 'sauge': return 7;
      case 'bonbon': return 8;
      case 'nuage':
      default: return 9;
    }
  }
}
