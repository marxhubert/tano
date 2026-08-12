import 'package:flutter/foundation.dart';
import 'package:tano/domain/notes_repository.dart';
import 'package:tano/models/note.dart';
import 'package:tano/utils/action.dart';

/// Owns the state and the actions of the home screen.
///
/// Pure Dart: no BuildContext, no widgets, no platform channels. The view
/// listens to this model and renders; persistence goes through
/// [NotesRepository].
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this.repository, List<Note>? initialNotes})
    : _notes = initialNotes != null ? List<Note>.of(initialNotes) : <Note>[] {
    _sortNotes();
  }

  final NotesRepository repository;

  List<Note> _notes;
  String _sortBy = 'date';
  String _viewLayout = 'list';
  bool _isInSelectionMode = false;
  final Set<int> _selected = <int>{};
  String _actionButtons = 'add';

  List<Note> get notes => List<Note>.unmodifiable(_notes);
  int get notesCount => _notes.length;
  String get sortBy => _sortBy;
  String get viewLayout => _viewLayout;
  bool get isInSelectionMode => _isInSelectionMode;
  String get actionButtons => _actionButtons;
  bool get hasSelection => _selected.isNotEmpty;
  int get selectedCount => _selected.length;
  Set<int> get selected => _selected;

  /// Loads the notes from the repository. Used when no initial notes are
  /// provided (e.g. navigation flows that do not come from the splash).
  Future<void> load() async {
    _notes = await repository.loadNotes();
    _sortNotes();
    notifyListeners();
  }

  void setViewLayout(String viewLayout) {
    if (viewLayout != 'compact' &&
        viewLayout != 'list' &&
        viewLayout != 'gridlist') {
      return;
    }
    if (_viewLayout == viewLayout) {
      return;
    }
    _viewLayout = viewLayout;
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    if (_sortBy == sortBy) {
      return;
    }
    _sortBy = sortBy;
    _sortNotes();
    notifyListeners();
  }

  void toggleFavorite(int index) {
    if (index < 0 || index >= _notes.length) {
      return;
    }
    final Note note = _notes[index];
    note.important = !(note.important ?? false);
    _persist();
    notifyListeners();
  }

  /// Long press: start the multi-selection mode with [index] selected.
  void enterSelectionMode(int index) {
    _selected.add(index);
    _isInSelectionMode = true;
    _actionButtons = 'multiple';
    notifyListeners();
  }

  void toggleSelection(int index) {
    if (!_selected.remove(index)) {
      _selected.add(index);
    }
    notifyListeners();
  }

  void selectAll() {
    for (int i = 0; i < _notes.length; i++) {
      _selected.add(i);
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

  /// Deletes every selected note, leaves the selection mode and persists.
  Future<void> deleteSelected() async {
    final List<int> indexes = _selected.toList()..sort();
    for (final int index in indexes.reversed) {
      _notes.removeAt(index);
    }
    _selected.clear();
    _isInSelectionMode = false;
    _actionButtons = 'add';
    await _persist();
    notifyListeners();
  }

  /// Removes a single note (e.g. swipe-to-delete) and persists.
  Future<void> removeNote(int index) async {
    if (index < 0 || index >= _notes.length) {
      return;
    }
    _notes.removeAt(index);
    await _persist();
    notifyListeners();
  }

  /// Applies the result of the edit screen (add / update / delete).
  Future<void> applyNoteAction({
    required bool add,
    required int index,
    required NoteAction action,
  }) async {
    switch (action.action) {
      case 'Save':
        if (add) {
          _notes.add(action.note!);
        } else {
          _notes[index] = action.note!;
        }
        break;
      case 'Delete':
        _notes.removeAt(index);
        break;
      case 'Cancel':
      default:
        break;
    }
    await _persist();
    notifyListeners();
  }

  void _sortNotes() {
    switch (_sortBy) {
      case 'date':
        _notes.sort((note1, note2) => note2.date!.compareTo(note1.date!));
        break;
      case 'alpha':
        _notes.sort(
          (note1, note2) => (note1.title ?? '').compareTo(note2.title ?? ''),
        );
        break;
      case 'important':
        _notes.sort(
          (note1, note2) => (note2.important ?? false).toString().compareTo(
            (note1.important ?? false).toString(),
          ),
        );
        break;
      case 'category':
        _notes.sort(
          (note1, note2) =>
              (note1.category ?? '').compareTo(note2.category ?? ''),
        );
        break;
    }
  }

  Future<void> _persist() => repository.saveNotes(_notes);
}
