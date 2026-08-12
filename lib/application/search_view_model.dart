import 'package:flutter/foundation.dart';
import 'package:tano/domain/notes_repository.dart';
import 'package:tano/models/note.dart';
import 'package:tano/utils/action.dart';

/// Owns the search state and actions of the search page.
///
/// Pure Dart: the view listens to this model and renders the results.
class SearchViewModel extends ChangeNotifier {
  SearchViewModel({required this.repository});

  final NotesRepository repository;

  List<Note> _allNotes = <Note>[];
  final List<Note> _results = <Note>[];
  String _query = '';

  List<Note> get results => List<Note>.unmodifiable(_results);
  bool get hasResults => _results.isNotEmpty;
  int get resultCount => _results.length;

  /// Loads every note (newest first) and re-runs the current search.
  Future<void> load() async {
    final List<Note> notes = await repository.loadNotes();
    notes.sort((note1, note2) => note2.date!.compareTo(note1.date!));
    _allNotes = notes;
    _runSearch();
    notifyListeners();
  }

  /// Updates the query and recomputes the results.
  void search(String keyword) {
    _query = keyword;
    _runSearch();
    notifyListeners();
  }

  /// Applies the result of the edit screen (update / delete) and persists.
  ///
  /// [original] is the note as it appears in the results; the edited note is
  /// located in the full list by identity, not by list index, because the
  /// results are only a subset of the notes.
  Future<void> applyNoteAction({
    required Note original,
    required NoteAction action,
  }) async {
    final int index = _allNotes.indexOf(original);
    switch (action.action) {
      case 'Save':
        if (index == -1) {
          _allNotes.add(action.note!);
        } else {
          _allNotes[index] = action.note!;
        }
        break;
      case 'Delete':
        if (index != -1) {
          _allNotes.removeAt(index);
        }
        break;
      case 'Cancel':
      default:
        break;
    }
    await repository.saveNotes(_allNotes);
    _runSearch();
    notifyListeners();
  }

  void _runSearch() {
    _results.clear();
    final String keyword = _query.trim();
    if (keyword.isEmpty) {
      return;
    }
    for (final Note note in _allNotes) {
      final bool inTitle =
          note.title != null &&
          note.title!.contains(RegExp(keyword, caseSensitive: false));
      final bool inContent =
          note.content != null &&
          note.content!.contains(RegExp(keyword, caseSensitive: false));
      if ((inTitle || inContent) && !_results.contains(note)) {
        _results.add(note);
      }
    }
  }
}
