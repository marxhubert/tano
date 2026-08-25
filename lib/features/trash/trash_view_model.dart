import 'package:flutter/foundation.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';

class TrashViewModel extends ChangeNotifier {
  TrashViewModel({required this.repository});

  final NotesRepository repository;
  List<Note> _deletedNotes = [];

  List<Note> get deletedNotes => List.unmodifiable(_deletedNotes);
  bool get isEmpty => _deletedNotes.isEmpty;

  Future<void> load() async {
    _deletedNotes = await repository.loadTrashNotes();
    // Sort by deletedAt (newest deleted first)
    _deletedNotes.sort((a, b) {
      if (a.deletedAt == null && b.deletedAt == null) return 0;
      if (a.deletedAt == null) return 1;
      if (b.deletedAt == null) return -1;
      return b.deletedAt!.compareTo(a.deletedAt!);
    });
    notifyListeners();
  }

  Future<void> restore(String id) async {
    await repository.restoreNote(id);
    _deletedNotes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> deletePermanently(String id) async {
    await repository.deleteNotePermanently(id);
    _deletedNotes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    for (final note in _deletedNotes) {
      await repository.deleteNotePermanently(note.id);
    }
    _deletedNotes.clear();
    notifyListeners();
  }
}
