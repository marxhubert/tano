import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';

/// Owns the form state and the note-building logic of the edit screen.
class EditNoteViewModel extends ChangeNotifier {
  EditNoteViewModel({
    required this.repository,
    required this.add,
    this.initialNote,
  })  : id = add ? Random().nextInt(999999).toString() : (initialNote?.id ?? ''),
        selectedDate = add
            ? DateTime.now()
            : (DateTime.tryParse(initialNote?.date ?? '') ?? DateTime.now()) {
    important = initialNote?.important ?? false;
    category = initialNote?.category ?? 'neutral';
    isDeleted = initialNote?.isDeleted ?? false;
    isPinned = initialNote?.isPinned ?? false;
    isLocked = initialNote?.isLocked ?? false;
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
    );
  }

  /// Whether the current form differs from the note as it was opened.
  bool isDirty({required String title, required String content}) {
    final Note current = buildNote(title: title, content: content);
    // Compare essential business fields, excluding internal SQLite metadata if any
    return current.title != _initialNote.title ||
           current.content != _initialNote.content ||
           current.important != _initialNote.important ||
           current.category != _initialNote.category ||
           current.isPinned != _initialNote.isPinned ||
           current.isLocked != _initialNote.isLocked;
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
    );
  }
}
