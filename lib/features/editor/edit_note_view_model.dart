import 'package:flutter/foundation.dart';
import 'package:tano/core/models/task.dart';
import 'package:tano/core/models/content_entity.dart';
import 'package:uuid/uuid.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/services/lock_gate.dart';

/// Outcome of [EditNoteViewModel.toggleLock], so the UI can react to each case.
enum LockToggleResult {
  /// The note is now locked.
  locked,

  /// The note is now unlocked.
  unlocked,

  /// The user cancelled or failed the system authentication.
  cancelled,

  /// The device has no system credential, so the note cannot be locked.
  unavailable,
}

/// Owns the form state and the note-building logic of the edit screen.
class EditNoteViewModel extends ChangeNotifier {
  EditNoteViewModel({
    required this.repository,
    required this.add,
    this.initialNote,
  }) : id = add ? const Uuid().v4() : (initialNote?.id ?? ''),
       selectedDate = add
           ? DateTime.now()
           : (DateTime.tryParse(initialNote?.date ?? '') ?? DateTime.now()) {
    description = initialNote?.description ?? '';
    important = initialNote?.important ?? false;
    category = initialNote?.category ?? Note.defaultCategory;
    isDeleted = initialNote?.isDeleted ?? false;
    isLocked = initialNote?.isLocked ?? false;
    attachments = List<String>.of(initialNote?.attachments ?? const <String>[]);
    coverImage = initialNote?.coverImage;
    folderId = initialNote?.folderId;
    _initialNote = _buildInitialNote(
      title: initialNote?.title ?? '',
      content: initialNote?.content ?? '',
    );
  }

  final NotesRepository repository;
  final bool add;
  final Note? initialNote;
  bool get isTask => initialNote?.isTask ?? false;

  late final String id;
  late DateTime selectedDate;
  String description = '';
  late bool important;
  late String category;
  late bool isDeleted;
  late bool isLocked;
  late List<String> attachments;
  String? coverImage;

  /// Folder the note belongs to, preserved across edits and creation.
  String? folderId;
  late Note _initialNote;

  /// Loads the note data from the repository (refresh).
  Future<void> load() async {
    final notes = await repository.loadNotes();
    final note = notes.firstWhere(
      (n) => n.id == id,
      orElse: () => _initialNote,
    );
    _initialNote = note;
    category = note.category;
    important = note.important;
    isLocked = note.isLocked;
    coverImage = note.coverImage;
    folderId = note.folderId;
    selectedDate = DateTime.tryParse(note.date) ?? DateTime.now();
    notifyListeners();
  }

  void toggleImportant() {
    important = !important;
    notifyListeners();
  }

  /// Locks or unlocks the note.
  ///
  /// Locking is immediate: there is nothing to protect yet. It is however
  /// refused when the device has no system credential, since the note could
  /// then never be unlocked again. Unlocking always requires the system
  /// credential.
  Future<LockToggleResult> toggleLock() async {
    final LockGateResult gate = await requestLockChange(isLocked: isLocked);
    switch (gate) {
      case LockGateResult.unavailable:
        return LockToggleResult.unavailable;
      case LockGateResult.refused:
        return LockToggleResult.cancelled;
      case LockGateResult.granted:
        isLocked = !isLocked;
        notifyListeners();
        return isLocked ? LockToggleResult.locked : LockToggleResult.unlocked;
    }
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

  void setCoverImage(String? value) {
    if (coverImage == value) return;
    coverImage = value;
    notifyListeners();
  }

  /// Normalizes raw editor values the same way [buildNote] does, so that
  /// dirty checks and save-time normalization compare like with like.
  static ({String title, String content}) normalize({
    required String title,
    required String content,
  }) {
    final String trimmedContent = content.trim();
    final String trimmedTitle = title.trim();
    final int max = trimmedContent.length < 18 ? trimmedContent.length : 18;
    final String computedTitle = trimmedTitle != ''
        ? trimmedTitle
        : trimmedContent.substring(0, max).replaceAll('\n', ' ');
    return (title: computedTitle, content: trimmedContent);
  }

  ({String title, String content}) _normalize({
    required String title,
    required String content,
  }) {
    if (!isTask) return normalize(title: title, content: content);
    final normalized = TaskContent.normalize(content);
    final items = TaskContent.savedItems(normalized);
    final fallback = items.isEmpty ? description : items.first.text;
    return (
      title: normalize(title: title, content: fallback).title,
      content: normalized,
    );
  }

  /// Builds the [Note] from the current form values.
  Note buildNote({required String title, required String content}) {
    final normalized = _normalize(title: title, content: content);

    return Note(
      kind: isTask ? EntityKind.task : EntityKind.note,
      id: id,
      date: selectedDate.toString(),
      createdAt: _initialNote.createdAt,
      updatedAt: DateTime.now().toString(),
      title: normalized.title,
      content: normalized.content,
      description: description.trim(),
      important: important,
      category: category,
      isDeleted: isDeleted,
      isLocked: isLocked,
      attachments: attachments,
      coverImage: coverImage,
      folderId: folderId,
    );
  }

  /// Whether the current form differs from the note as it was opened.
  bool isDirty({required String title, required String content}) {
    // Compare normalized values on both sides so the save-time normalization
    // (trimming, deriving a title from the content) never counts as a user
    // edit. This is also what makes an in-place save settle: [_initialNote]
    // then holds the normalized note while the editor still holds the raw
    // text (an untitled note keeps an empty title field after saving).
    final current = _normalize(title: title, content: content);
    final initial = _normalize(
      title: _initialNote.title,
      content: _initialNote.content,
    );
    return current.title != initial.title ||
        current.content != initial.content ||
        description.trim() != _initialNote.description.trim() ||
        important != _initialNote.important ||
        category != _initialNote.category ||
        isLocked != _initialNote.isLocked ||
        coverImage != _initialNote.coverImage ||
        folderId != _initialNote.folderId ||
        !listEquals(attachments, _initialNote.attachments);
  }

  /// Business rule: a note is savable when at least its title or its content is not blank.
  bool isValid({required String title, required String content}) {
    return title.trim().isNotEmpty ||
        (isTask && description.trim().isNotEmpty) ||
        (isTask
            ? TaskContent.savedItems(content).isNotEmpty
            : content.trim().isNotEmpty) ||
        coverImage != null;
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
      kind: isTask ? EntityKind.task : EntityKind.note,
      id: id,
      date: selectedDate.toString(),
      createdAt: initialNote?.createdAt ?? selectedDate.toString(),
      updatedAt: initialNote?.updatedAt ?? selectedDate.toString(),
      title: title,
      content: content,
      description: description,
      important: important,
      category: category,
      isDeleted: isDeleted,
      isLocked: isLocked,
      attachments: attachments,
      coverImage: coverImage,
      folderId: folderId,
    );
  }
}
