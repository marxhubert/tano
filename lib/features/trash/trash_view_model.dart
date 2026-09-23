import 'package:flutter/foundation.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';

/// Everything the trash shows: the notes deleted on their own and the folders
/// deleted as a whole, each with the notes it still contains.
class TrashViewModel extends ChangeNotifier {
  TrashViewModel({
    required this.notesRepository,
    required this.foldersRepository,
  });

  final NotesRepository notesRepository;
  final FoldersRepository foldersRepository;

  List<Note> _deletedNotes = [];
  List<Folder> _deletedFolders = [];
  List<Note> _activeNotes = [];
  Set<String> _activeNoteIds = <String>{};

  List<Note> get deletedNotes => List.unmodifiable(_deletedNotes);
  List<Folder> get deletedFolders => List.unmodifiable(_deletedFolders);
  bool get isEmpty => _deletedNotes.isEmpty && _deletedFolders.isEmpty;

  /// IDs of every active (not deleted) note, for link styling in the excerpt.
  Set<String> get activeNoteIds => _activeNoteIds;

  /// Notes still filed in [folderId]: they travel with their folder.
  int noteCountIn(String folderId) =>
      _activeNotes.where((Note note) => note.folderId == folderId).length;

  /// Whether permanently deleting [folderId] would also destroy locked
  /// content: the folder itself is locked, or a locked note is filed in it.
  bool folderHasLockedContent(String folderId) {
    for (final Folder folder in _deletedFolders) {
      if (folder.id == folderId && folder.isLocked) return true;
    }
    return _activeNotes.any(
      (Note note) => note.folderId == folderId && note.isLocked,
    );
  }

  /// Whether emptying the trash would destroy at least one locked item.
  bool get hasLockedItems =>
      _deletedNotes.any((Note note) => note.isLocked) ||
      _deletedFolders.any((Folder folder) => folderHasLockedContent(folder.id));

  Future<void> load() async {
    _deletedNotes = await notesRepository.loadTrashNotes();
    _deletedFolders = await foldersRepository.loadTrashFolders();
    _activeNotes = await notesRepository.loadNotes();
    _activeNoteIds = _activeNotes
        .where((Note note) => !note.isDeleted)
        .map((Note note) => note.id)
        .toSet();
    // Newest deleted first, notes and folders sharing the same rule.
    _deletedNotes.sort((a, b) => _newestFirst(a.deletedAt, b.deletedAt));
    _deletedFolders.sort((a, b) => _newestFirst(a.deletedAt, b.deletedAt));
    notifyListeners();
  }

  Future<void> restoreNote(String id) async {
    await notesRepository.restoreNote(id);
    _deletedNotes.removeWhere((Note n) => n.id == id);
    notifyListeners();
  }

  Future<void> deleteNotePermanently(String id) async {
    await notesRepository.deleteNotePermanently(id);
    _deletedNotes.removeWhere((Note n) => n.id == id);
    notifyListeners();
  }

  /// Restores the folder; the notes it still contains come back with it.
  Future<void> restoreFolder(String id) async {
    await foldersRepository.restoreFolder(id);
    _deletedFolders.removeWhere((Folder f) => f.id == id);
    notifyListeners();
  }

  /// Deletes the folder and the notes it contains for good.
  Future<void> deleteFolderPermanently(String id) async {
    await foldersRepository.deleteFolderPermanently(id);
    _deletedFolders.removeWhere((Folder f) => f.id == id);
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    for (final Folder folder in _deletedFolders) {
      await foldersRepository.deleteFolderPermanently(folder.id);
    }
    for (final Note note in _deletedNotes) {
      await notesRepository.deleteNotePermanently(note.id);
    }
    _deletedFolders.clear();
    _deletedNotes.clear();
    notifyListeners();
  }

  static int _newestFirst(String? a, String? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
