import 'package:tano/models/note.dart';

/// Contract for persisting notes.
///
/// Views depend on this abstraction, not on a concrete storage, so the
/// business code stays pure Dart and storage can be swapped (file, cloud,
/// in-memory for tests).
abstract class NotesRepository {
    /// Loads every note from the underlying storage.
    ///
    /// On first launch the repository seeds the app with demo notes so the
    /// first screen is never empty.
    Future<List<Note>> loadNotes();

    /// Replaces the whole stored note list.
    Future<void> saveNotes(List<Note> notes);
}
