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

  /// Moves a folder to the trash. Notes it contained are unfiled, not deleted.
  Future<void> trashFolder(String id);

  /// Pins or unpins a folder.
  Future<void> toggleFolderPin(String id);

  /// Smallest "Folder X" name that is not already used.
  Future<String> nextFolderName();
}
