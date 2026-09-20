import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/repositories/sqlite_notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/shared/config/service_locator.dart';

class _Auth extends AuthService {
  bool available = false;
  @override
  Future<bool> isAvailable() async => available;
}

void main() {
  sqfliteFfiInit();

  test(
    'developer reset reloads fixtures and respects device lock capability',
    () async {
      SharedPreferences.setMockInitialValues({});
      await getIt.reset();
      final directory = await Directory.systemTemp.createTemp('tano_fixtures_');
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => directory.path);
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final repository = SQLiteNotesRepository(
        databaseFactoryOverride: databaseFactoryFfi,
        databasePath: '${directory.path}/notes.db',
        documentsDirectory: () async => directory,
      );
      final store = AttachmentsStore(
        documentsDirectory: () async => directory,
        cacheDirectory: () async => directory,
        keyProvider: () async => Uint8List(32),
      );
      final auth = _Auth();
      getIt.registerSingleton<NotesRepository>(repository);
      getIt.registerSingleton<AttachmentsStore>(store);
      getIt.registerSingleton<AuthService>(auth);
      addTearDown(() async {
        await getIt.reset();
        await directory.delete(recursive: true);
      });
      final model = SettingsViewModel(applyConsent: (_) async {});
      addTearDown(model.dispose);
      expect(await repository.loadNotes(), isEmpty);
      await repository.upsertNote(Note(id: 'old', isDeleted: true));
      await store.writeIfAbsent('old-file', Uint8List.fromList([1]));
      await model.developerReset();
      final notes = await repository.loadNotes();
      final folders = await repository.loadFolders();
      expect(notes.length, greaterThan(90));
      expect(folders, hasLength(5));
      expect(await repository.loadTrashNotes(), isEmpty);
      expect(await File(await store.pathOf('old-file')).exists(), isFalse);
      expect(notes.any((note) => note.isLocked), isFalse);
      expect(folders.any((folder) => folder.isLocked), isFalse);
      expect(notes.any((note) => note.content.contains('- [x]')), isTrue);
      for (final note in notes) {
        if (note.folderId != null) {
          expect(folders.any((folder) => folder.id == note.folderId), isTrue);
        }
        for (final link in RegExp(r'\[\[([^:]+):').allMatches(note.content)) {
          expect(notes.any((target) => target.id == link.group(1)), isTrue);
        }
      }
      auth.available = true;
      await model.developerReset();
      final reseeded = await repository.loadNotes();
      expect(reseeded, hasLength(notes.length));
      expect(reseeded.any((note) => note.isLocked), isTrue);
      expect(
        (await repository.loadFolders()).where((folder) => folder.isLocked),
        hasLength(2),
      );
      expect(model.isResetting, isFalse);
      await model.performHardReset(deleteData: true, deletePrefs: false);
      expect(await repository.loadNotes(), isEmpty);
      expect(await repository.loadFolders(), isEmpty);
    },
  );
}
