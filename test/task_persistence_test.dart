import 'package:tano/core/models/folder.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/core/models/note_access_policy.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/task.dart';
import 'package:tano/core/repositories/sqlite_notes_repository.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/services/export_service.dart';
import 'package:tano/core/services/import_service.dart';
import 'package:tano/features/editor/edit_note_view_model.dart';

class _Auth extends AuthService {
  @override
  Future<bool> isAvailable() async => false;
}

void main() {
  sqfliteFfiInit();
  test(
    'task content and kind survive edit, SQLite, move, trash and archive',
    () async {
      final directory = await Directory.systemTemp.createTemp('tano_task_');
      addTearDown(() => directory.delete(recursive: true));
      final repository = SQLiteNotesRepository(
        databaseFactoryOverride: databaseFactoryFfi,
        databasePath: '${directory.path}/source.db',
        documentsDirectory: () async => directory,
      );
      final model = EditNoteViewModel(
        repository: repository,
        add: true,
        initialNote: Task(),
      );
      addTearDown(model.dispose);
      expect(model.isValid(title: '', content: '- [ ] '), isFalse);
      model.description = 'Shopping details';
      final task = model.buildNote(
        title: '',
        content: '- [ ] Milk\n- [x] Bread\n- [ ] ',
      );
      expect(task.title, 'Milk');
      expect(task.isTask, isTrue);
      await model.persistSavedNote(task);
      expect(
        model.isDirty(title: '', content: '- [ ] Milk\n- [x] Bread\n- [ ] '),
        isFalse,
      );
      await model.load();
      var stored = (await repository.loadNotes()).single;
      expect(stored.isTask, isTrue);
      expect(stored.description, 'Shopping details');
      expect(TaskContent.savedItems(stored.content).length, 2);
      await repository.upsertFolder(Folder(id: 'folder', name: 'Folder'));
      await repository.upsertNote(stored.copyWith(folderId: 'folder'));
      final home = HomeViewModel(
        repository: repository,
        foldersRepository: repository,
      );
      addTearDown(home.dispose);
      await home.load();
      await home.setSearchQuery('Milk');
      expect(home.notes.single.isTask, isTrue);
      await repository.upsertNote(
        stored.copyWith(folderId: 'folder', isLocked: true),
      );
      await home.load();
      expect(home.notes, isEmpty);
      expect(
        NoteAccessPolicy(
          [],
        ).isSearchable((await repository.loadNotes()).single),
        isFalse,
      );
      await repository.trashNote(task.id);
      stored = (await repository.loadTrashNotes()).single;
      expect(stored.isTask, isTrue);
      await repository.restoreNote(task.id);
      stored = (await repository.loadNotes()).single;
      final store = AttachmentsStore(
        documentsDirectory: () async => directory,
        cacheDirectory: () async => directory,
        keyProvider: () async => Uint8List(32),
      );
      final bytes = await ExportService(
        attachments: store,
        argon2: Argon2Params.fast,
      ).build(notes: [stored], password: 'secret123');
      final target = SQLiteNotesRepository(
        databaseFactoryOverride: databaseFactoryFfi,
        databasePath: '${directory.path}/target.db',
        documentsDirectory: () async => directory,
      );
      await ImportService(
        repository: target,
        attachments: store,
        auth: _Auth(),
        argon2: Argon2Params.fast,
      ).import(bytes, password: 'secret123');
      final imported = (await target.loadNotes()).single;
      expect(imported.isTask, isTrue);
      expect(imported.content, stored.content);
      expect(imported.description, stored.description);
      expect(imported.isLocked, isFalse);
      expect(imported.folderId, isNull);
      expect(Note.fromJson({'id': 'old'}).isTask, isFalse);
      expect(() => Note.fromJson({'kind': 'unknown'}), throwsFormatException);
    },
  );
}
