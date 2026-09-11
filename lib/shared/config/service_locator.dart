import 'package:get_it/get_it.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/repositories/sqlite_notes_repository.dart';
import 'package:tano/core/services/installation_key.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  getIt.registerLazySingleton<NotesRepository>(
    () => SQLiteNotesRepository(
      // The database is encrypted with a key that lives in the OS secure
      // storage and never leaves the device.
      passwordProvider: InstallationKey.instance.databasePassphrase,
    ),
  );
}
