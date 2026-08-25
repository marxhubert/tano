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

  /// Pins or unpins a note.
  Future<void> togglePin(String id);

  /// Locks or unlocks a note.
  Future<void> toggleLock(String id, {String? password});

  /// Permanently deletes a note from storage.
  Future<void> deleteNotePermanently(String id);

  /// Searches for notes matching the query in title or content.
  Future<List<Note>> searchNotes(String query);
}
