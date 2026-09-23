import 'package:tano/core/models/folder.dart';

/// Contract for persisting folders.
///
/// Kept separate from [NotesRepository] so the many in-memory test doubles do
/// not have to grow folder support all at once.
abstract class FoldersRepository {
  /// Loads every folder that is not in the trash.
  Future<List<Folder>> loadFolders();

  /// Inserts or updates a single folder.
  Future<void> upsertFolder(Folder folder);

  /// Moves a folder to the trash, keeping its notes exactly as they are: the
  /// folder stays whole in the trash and restoring it brings its content back.
  Future<void> trashFolder(String id);

  /// Loads every folder in the trash.
  Future<List<Folder>> loadTrashFolders();

  /// Restores a trashed folder, together with the notes it still contains.
  Future<void> restoreFolder(String id);

  /// Deletes a trashed folder and the notes it contains for good.
  Future<void> deleteFolderPermanently(String id);

  /// Deletes every folder for good, trashed or not. The hard reset takes the
  /// folders and the notes together.
  Future<void> deleteAllFolders();
}

/// A repository with no folders at all.
///
/// Keeps the trash working when the notes repository has no folder support
/// (lightweight in-memory doubles in tests).
class EmptyFoldersRepository implements FoldersRepository {
  const EmptyFoldersRepository();

  @override
  Future<List<Folder>> loadFolders() async => <Folder>[];
  @override
  Future<List<Folder>> loadTrashFolders() async => <Folder>[];
  @override
  Future<void> upsertFolder(Folder folder) async {}
  @override
  Future<void> trashFolder(String id) async {}
  @override
  Future<void> restoreFolder(String id) async {}
  @override
  Future<void> deleteFolderPermanently(String id) async {}

  @override
  Future<void> deleteAllFolders() async {}
}
