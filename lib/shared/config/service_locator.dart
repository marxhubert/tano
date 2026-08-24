import 'package:get_it/get_it.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/repositories/sqlite_notes_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  getIt.registerLazySingleton<NotesRepository>(() => SQLiteNotesRepository());
}
