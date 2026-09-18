import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';

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
