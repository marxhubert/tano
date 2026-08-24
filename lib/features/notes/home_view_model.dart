import 'package:flutter/foundation.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/action.dart';

/// Owns the state and the actions of the home screen.
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this.repository, List<Note>? initialNotes})
      : _notes = initialNotes != null ? List<Note>.of(initialNotes) : <Note>[] {
    _sortNotes();
  }

  final NotesRepository repository;

  List<Note> _notes;
  String _searchQuery = '';
  String _sortBy = 'date';
  String _secondarySortBy = 'date';
  bool _sortAscending = true;
  String _viewLayout = 'gridlist';
  bool _isInSelectionMode = false;
  final Set<String> _selected = <String>{};
  String _actionButtons = 'add';
  (List<Note>, List<int>)? _lastDeleted;

  /// Notes currently displayed, filtered by the search query.
  List<Note> get notes => List<Note>.unmodifiable(_filteredNotes());
  int get notesCount => _filteredNotes().length;
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

  /// Loads the notes from the repository.
  Future<void> load() async {
    _notes = await repository.loadNotes();
    _sortNotes();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
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
    _sortNotes();
    notifyListeners();
  }

  void setSecondarySortBy(String sortBy) {
    if (_secondarySortBy == sortBy) return;
    _secondarySortBy = sortBy;
    _sortNotes();
    notifyListeners();
  }

  void setSortAscending(bool ascending) {
    if (_sortAscending == ascending) return;
    _sortAscending = ascending;
    _sortNotes();
    notifyListeners();
  }

  void toggleFavorite(String id) {
    final int index = _notes.indexWhere((Note note) => note.id == id);
    if (index == -1) return;
    final Note note = _notes[index];
    _notes[index] = note.copyWith(important: !note.important);
    _persist();
    notifyListeners();
  }

  void enterSelectionMode(String id) {
    _selected.add(id);
    _isInSelectionMode = true;
    _actionButtons = 'multiple';
    notifyListeners();
  }

  void toggleSelection(String id) {
    if (!_selected.remove(id)) {
      _selected.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    for (final Note note in _filteredNotes()) {
      _selected.add(note.id);
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

  Future<void> deleteSelected() async {
    final List<Note> removed = <Note>[];
    final List<int> indexes = <int>[];
    for (int i = 0; i < _notes.length; i++) {
      if (_selected.contains(_notes[i].id)) {
        removed.add(_notes[i]);
        indexes.add(i);
      }
    }
    _notes.removeWhere((Note note) => _selected.contains(note.id));
    _lastDeleted = (removed, indexes);
    _selected.clear();
    _isInSelectionMode = false;
    _actionButtons = 'add';
    await _persist();
    notifyListeners();
  }

  Future<void> removeNote(String id) async {
    final int index = _notes.indexWhere((Note note) => note.id == id);
    if (index == -1) return;
    final Note removed = _notes.removeAt(index);
    _lastDeleted = (<Note>[removed], <int>[index]);
    await _persist();
    notifyListeners();
  }

  Future<void> undoLastDelete() async {
    final (List<Note>, List<int>)? record = _lastDeleted;
    if (record == null) return;
    final List<Note> notes = record.$1;
    final List<int> indexes = record.$2;
    for (int i = 0; i < indexes.length; i++) {
      final int index = indexes[i] > _notes.length ? _notes.length : indexes[i];
      _notes.insert(index, notes[i]);
    }
    _lastDeleted = null;
    await _persist();
    notifyListeners();
  }

  Future<void> applyNoteAction({
    required bool add,
    required String originalId,
    required NoteAction action,
  }) async {
    switch (action.kind) {
      case NoteActionKind.save:
        if (add) {
          _notes.add(action.note!);
        } else {
          final int index = _notes.indexWhere(
            (Note note) => note.id == originalId,
          );
          if (index != -1) {
            _notes[index] = action.note!;
          }
        }
        break;
      case NoteActionKind.delete:
        _notes.removeWhere((Note note) => note.id == originalId);
        break;
      case NoteActionKind.cancel:
        break;
    }
    await _persist();
    notifyListeners();
  }

  List<Note> _filteredNotes() {
    final String keyword = _searchQuery.trim();
    if (keyword.isEmpty) return _notes;
    return _notes.where((Note note) {
      return note.title.contains(RegExp(keyword, caseSensitive: false)) ||
          note.content.contains(RegExp(keyword, caseSensitive: false));
    }).toList();
  }

  void _sortNotes() {
    _notes.sort((note1, note2) {
      int comparison = _compare(note1, note2, _sortBy);

      if (comparison == 0 && (_sortBy == 'important' || _sortBy == 'theme')) {
        // Compose with the last chosen "Title" or "Date" if primary sort is equal
        comparison = _compare(note1, note2, _secondarySortBy);
      }

      if (comparison == 0 && _sortBy != 'date' && _secondarySortBy != 'date') {
        // Absolute fallback to date (newest first)
        comparison = _compare(note1, note2, 'date');
      }

      return _sortAscending ? comparison : -comparison;
    });
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

  Future<void> _persist() => repository.saveNotes(_notes);
}
