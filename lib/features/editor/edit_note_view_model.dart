import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';

/// Owns the form state and the note-building logic of the edit screen.
class EditNoteViewModel extends ChangeNotifier {
  EditNoteViewModel({
    required this.repository,
    required this.add,
    this.initialNote,
  })  : id = add ? const Uuid().v4() : (initialNote?.id ?? ''),
        selectedDate = add
            ? DateTime.now()
            : (DateTime.tryParse(initialNote?.date ?? '') ?? DateTime.now()) {
    important = initialNote?.important ?? false;
    category = initialNote?.category ?? Note.defaultCategory;
    isDeleted = initialNote?.isDeleted ?? false;
    isPinned = initialNote?.isPinned ?? false;
    isLocked = initialNote?.isLocked ?? false;
    attachments = List<String>.of(initialNote?.attachments ?? const <String>[]);
    _initialNote = _buildInitialNote(
      title: initialNote?.title ?? '',
      content: initialNote?.content ?? '',
    );
  }

  final NotesRepository repository;
  final bool add;
  final Note? initialNote;

  late final String id;
  late final DateTime selectedDate;
  late bool important;
  late String category;
  late bool isDeleted;
  late bool isPinned;
  late bool isLocked;
  late List<String> attachments;
  late Note _initialNote;

  /// Loads the note data from the repository (refresh).
  Future<void> load() async {
    final notes = await repository.loadNotes();
    final note = notes.firstWhere((n) => n.id == id, orElse: () => _initialNote);
    _initialNote = note;
    category = note.category;
    important = note.important;
    isPinned = note.isPinned;
    isLocked = note.isLocked;
    selectedDate = DateTime.tryParse(note.date) ?? DateTime.now();
    notifyListeners();
  }

  void toggleImportant() {
    important = !important;
    notifyListeners();
  }

  void togglePin() {
    isPinned = !isPinned;
    notifyListeners();
  }

  void setCategory(String category) {
    if (this.category == category) {
      return;
    }
    this.category = category;
    notifyListeners();
  }

  /// Replaces the note's attachment list.
  void setAttachments(List<String> value) {
    attachments = List<String>.of(value);
    notifyListeners();
  }

  /// Builds the [Note] from the current form values.
  Note buildNote({required String title, required String content}) {
    final String trimmedContent = content.trim();
    final String trimmedTitle = title.trim();
    final int max = trimmedContent.length < 18 ? trimmedContent.length : 18;
    final String computedTitle = trimmedTitle != ''
        ? trimmedTitle
        : trimmedContent.substring(0, max).replaceAll('\n', ' ');

    return Note(
      id: id,
      date: selectedDate.toString(),
      title: computedTitle,
      content: trimmedContent,
      important: important,
      category: category,
      isDeleted: isDeleted,
      isPinned: isPinned,
      isLocked: isLocked,
      attachments: attachments,
    );
  }

  /// Whether the current form differs from the note as it was opened.
  bool isDirty({required String title, required String content}) {
    // Compare the raw editor values against the raw initial values. The
    // save-time normalization (trimming, deriving a title from the content)
    // must not count as a user edit, otherwise notes with leading/trailing
    // whitespace would always look dirty.
    return title != _initialNote.title ||
          content != _initialNote.content ||
          important != _initialNote.important ||
          category != _initialNote.category ||
          isPinned != _initialNote.isPinned ||
          isLocked != _initialNote.isLocked;
  }

  /// Business rule: a note is savable when at least its title or its content is not blank.
  bool isValid({required String title, required String content}) {
    return title.trim().isNotEmpty || content.trim().isNotEmpty;
  }

  /// Persists a saved note.
  Future<void> persistSavedNote(Note note) async {
    await repository.upsertNote(note);
    _initialNote = note;
  }

  /// Special save for theme or bookmark changes.
  Future<void> autoSaveThemeOrBookmark({
    required String title,
    required String content,
  }) async {
    if (!isValid(title: title, content: content)) return;

    final Note note = buildNote(title: title, content: content);
    await persistSavedNote(note);
  }

  Note _buildInitialNote({required String title, required String content}) {
    return Note(
      id: id,
      date: selectedDate.toString(),
      title: title,
      content: content,
      important: important,
      category: category,
      isDeleted: isDeleted,
      isPinned: isPinned,
      isLocked: isLocked,
      attachments: attachments,
    );
  }
}
