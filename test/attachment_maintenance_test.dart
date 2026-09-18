import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/sqlite_notes_repository.dart';
import 'package:tano/core/services/attachment_maintenance.dart';

class _BrokenReferences implements AttachmentReferenceSource {
  @override
  Future<Set<String>> referencedAttachments() async =>
      throw StateError('unreadable database');
}

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late AttachmentsStore store;
  late SQLiteNotesRepository repository;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('tano_gc_');
    store = AttachmentsStore(
      documentsDirectory: () async => directory,
      cacheDirectory: () async => directory,
      keyProvider: () async => Uint8List(32),
    );
    repository = SQLiteNotesRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: '${directory.path}/notes.db',
      documentsDirectory: () async => directory,
    );
    for (final name in ['shared', 'trash', 'folder-cover', 'orphan']) {
      await store.writeIfAbsent(name, Uint8List.fromList([1, 2, 3]));
    }
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'keeps shared references, trash and folder covers; collects only orphans',
    () async {
      await repository.upsertNote(Note(id: 'one', attachments: ['shared']));
      await repository.upsertNote(Note(id: 'two', coverImage: 'shared'));
      await repository.upsertNote(
        Note(id: 'deleted', isDeleted: true, attachments: ['trash']),
      );
      await repository.upsertFolder(
        Folder(id: 'folder', isDeleted: true, coverImage: 'folder-cover'),
      );
      await repository.deleteNotePermanently('one');
      final gc = AttachmentMaintenance(source: repository, store: store);
      expect(await gc.collectAtStartup(), 1);
      for (final name in ['shared', 'trash', 'folder-cover']) {
        expect(await store.read(name), [1, 2, 3]);
      }
      expect(await File(await store.pathOf('orphan')).exists(), isFalse);
      expect(await gc.collectAtStartup(), 0);
    },
  );

  test('a failed reference snapshot never authorizes deletion', () async {
    await expectLater(
      AttachmentMaintenance(
        source: _BrokenReferences(),
        store: store,
      ).collectAtStartup(),
      throwsStateError,
    );
    expect(await store.read('orphan'), [1, 2, 3]);
  });

  test(
    'malformed persisted references fail closed before deleting any file',
    () async {
      await repository.loadNotes();
      final db = await databaseFactoryFfi.openDatabase(
        '${directory.path}/notes.db',
      );
      await db.insert('notes', {'id': 'broken', 'attachments': 'not-json'});
      await expectLater(
        AttachmentMaintenance(
          source: repository,
          store: store,
        ).collectAtStartup(),
        throwsFormatException,
      );
      expect(await store.read('orphan'), [1, 2, 3]);
    },
  );
}
