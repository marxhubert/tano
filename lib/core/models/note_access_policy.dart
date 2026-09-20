import 'folder.dart';
import 'note.dart';

/// Visibility rules shared by search, navigation and export. This is a local
/// policy; authenticated peer permissions will be a separate boundary.
class NoteAccessPolicy {
  NoteAccessPolicy(Iterable<Folder> folders)
    : _folders = {for (final folder in folders) folder.id: folder};
  final Map<String, Folder> _folders;

  bool isReachable(Note note) =>
      !note.isDeleted &&
      (note.folderId == null ||
          (_folders[note.folderId] != null &&
              !_folders[note.folderId]!.isDeleted));

  bool requiresAuthentication(Note note) =>
      note.isLocked || (_folders[note.folderId]?.isLocked ?? false);

  /// The caller must already have opened this folder through authentication.
  /// An item's own lock excludes it even in an authenticated folder.
  bool isSearchableInFolder(Note note, String folderId) =>
      isReachable(note) && note.folderId == folderId && !note.isLocked;

  bool isSearchable(Note note) =>
      isReachable(note) && !requiresAuthentication(note);
}
