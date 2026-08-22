import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';

/// Owns the form state and the note-building logic of the edit screen.
///
/// Pure Dart: the widget keeps the text controllers, this model knows how to
/// turn their content into a [Note] and how to persist it.
class EditNoteViewModel extends ChangeNotifier {
  EditNoteViewModel({
    required this.repository,
    required this.add,
    this.initialNote,
  }) : id = add ? Random().nextInt(999999).toString() : (initialNote?.id ?? ''),
       selectedDate = add
           ? DateTime.now()
           : (DateTime.tryParse(initialNote?.date ?? '') ?? DateTime.now()) {
    important = initialNote?.important ?? false;
    category = initialNote?.category ?? 'neutral';
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
  late Note _initialNote;

  void toggleImportant() {
    important = !important;
    notifyListeners();
  }

  void setCategory(String category) {
    if (this.category == category) {
      return;
    }
    this.category = category;
    notifyListeners();
  }

  /// Builds the [Note] from the current form values. The title falls back
  /// to the first characters of the content when left empty.
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
    );
  }

  /// Whether the current form differs from the note as it was opened.
  bool isDirty({required String title, required String content}) {
    final Note current = buildNote(title: title, content: content);
    return current.toJson().toString() != _initialNote.toJson().toString();
  }

  /// Business rule: a note is savable when at least its title or its content is not blank.
  bool isValid({required String title, required String content}) {
    return title.trim().isNotEmpty || content.trim().isNotEmpty;
  }

  /// Persists a saved note: adds it or replaces the note with the same id,
  /// then saves the whole list.
  Future<void> persistSavedNote(Note note) async {
    final List<Note> notes = await repository.loadNotes();
    final int index = notes.indexWhere((Note n) => n.id == note.id);
    if (index == -1) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
    await repository.saveNotes(notes);
    // Update the baseline after saving so it's no longer "dirty"
    _initialNote = note;
  }

  /// Special save for theme changes: persists the current state (with the new theme)
  /// and updates the baseline so that further text changes don't trigger the alert
  /// immediately unless modified again.
  Future<void> autoSaveTheme({required String title, required String content}) async {
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
    );
  }
}
