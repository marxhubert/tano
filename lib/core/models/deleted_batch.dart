import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';

/// The notes of [notes] that [isSelected] accepts, with the indexes they held.
///
/// Home and Folder both need this pair to build a [DeletedBatch] and to put the
/// notes back at their old positions; only the selection test differs.
({List<Note> notes, List<int> indexes}) collectSelectedNotes(
  List<Note> notes,
  bool Function(Note note) isSelected,
) {
  final List<Note> selected = <Note>[];
  final List<int> indexes = <int>[];
  for (int i = 0; i < notes.length; i++) {
    if (isSelected(notes[i])) {
      selected.add(notes[i]);
      indexes.add(i);
    }
  }
  return (notes: selected, indexes: indexes);
}

/// What a deletion removed, and the places it left.
///
/// One value shared by every screen that deletes: it carries what has to go
/// back, and it knows how to put it back in storage. Putting it back on screen
/// stays the caller's business, since only the caller knows its own list.
class DeletedBatch {
  const DeletedBatch({
    this.notes = const <Note>[],
    this.indexes = const <int>[],
    this.folders = const <Folder>[],
  });

  /// The notes that were removed, and the positions they held, in that order.
  final List<Note> notes;
  final List<int> indexes;

  final List<Folder> folders;

  bool get isEmpty => notes.isEmpty && folders.isEmpty;

  /// Puts everything back in storage. The caller restores the visible list.
  Future<void> restoreInStorage(NotesRepository repository) async {
    for (final Note note in notes) {
      await repository.restoreNote(note.id);
    }
    if (repository is FoldersRepository) {
      final FoldersRepository folders = repository as FoldersRepository;
      for (final Folder folder in this.folders) {
        await folders.restoreFolder(folder.id);
      }
    }
  }
}
