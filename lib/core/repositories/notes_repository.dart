import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';

/// Contract for persisting notes.
///
/// Views depend on this abstraction, not on a concrete storage, so the
/// business code stays pure Dart and storage can be swapped (file, cloud,
/// in-memory for tests).
abstract class NotesRepository {
  /// Loads every note from the underlying storage.
  Future<List<Note>> loadNotes();

  /// Loads only notes that are in the trash.
  Future<List<Note>> loadTrashNotes();

  /// Inserts or updates a single note.
  Future<void> upsertNote(Note note);

  /// Moves a note to the trash.
  Future<void> trashNote(String id);

  /// Restores a note from the trash.
  Future<void> restoreNote(String id);

  /// Permanently deletes a note from storage.
  Future<void> deleteNotePermanently(String id);

  /// Searches for notes matching the query in title or content.
  Future<List<Note>> searchNotes(String query);

  /// Deletes all notes from storage.
  Future<void> deleteAllNotes();
}

/// Optional capability for an all-or-nothing transfer, including ID conflicts.
abstract interface class AtomicNoteImporter {
  /// Inserts imported [folders] then [notes] in one transaction, so a conflict
  /// on either side leaves the store untouched. Folders come first because a
  /// note may reference one.
  Future<void> insertImportedNotes(
    List<Note> notes, {
    List<Folder> folders = const <Folder>[],
  });
}

/// Optional capability: apply a set of note writes in one transaction.
///
/// The SQLite repository implements it, so moving or deleting a whole selection
/// is all-or-nothing. In-memory test doubles keep their simple per-note loop
/// through [upsertNotesAtomically] and [trashNotesAtomically].
abstract interface class AtomicNotesWriter {
  /// Inserts or updates every note in one transaction.
  Future<void> upsertNotes(List<Note> notes);

  /// Moves every note to the trash in one transaction.
  Future<void> trashNotes(List<String> ids);
}

/// Optional capability: documents set aside in the archive.
///
/// Only notes and tasks can be archived, never a folder. SQLite implements it;
/// the archive page, the document menu and the Move-to list go through it.
abstract interface class ArchiveRepository {
  /// Loads every archived document.
  Future<List<Note>> loadArchivedNotes();

  /// Archives one document: it leaves Home and its folder.
  Future<void> archiveNote(String id);

  /// Archives several documents in one transaction.
  Future<void> archiveNotes(List<String> ids);

  /// Takes one document back to Home and resets its creation date.
  Future<void> restoreArchivedNote(String id);

  /// Takes several documents back to Home in one transaction.
  Future<void> restoreArchivedNotes(List<String> ids);
}

/// Persists [notes] atomically when the repository supports it, one by one
/// otherwise. An empty batch does nothing.
Future<void> upsertNotesAtomically(
  NotesRepository repository,
  List<Note> notes,
) async {
  if (notes.isEmpty) return;
  if (repository is AtomicNotesWriter) {
    await (repository as AtomicNotesWriter).upsertNotes(notes);
    return;
  }
  for (final Note note in notes) {
    await repository.upsertNote(note);
  }
}

/// Moves [ids] to the trash atomically when the repository supports it, one by
/// one otherwise. An empty batch does nothing.
Future<void> trashNotesAtomically(
  NotesRepository repository,
  List<String> ids,
) async {
  if (ids.isEmpty) return;
  if (repository is AtomicNotesWriter) {
    await (repository as AtomicNotesWriter).trashNotes(ids);
    return;
  }
  for (final String id in ids) {
    await repository.trashNote(id);
  }
}
