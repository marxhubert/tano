import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/sqlite_notes_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late SQLiteNotesRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('tano_test_');
    repository = SQLiteNotesRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: '${tempDir.path}/tano_notes.db',
      documentsDirectory: () async => tempDir,
    );
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  group('SQLiteNotesRepository', () {
    test('an import collision rolls back the complete batch', () async {
      final existing = Note(
        id: 'existing',
        title: 'Keep',
        content: '',
        date: '2026-01-01',
      );
      await repository.upsertNote(existing);
      await expectLater(
        repository.insertImportedNotes([
          existing.copyWith(id: 'new', title: 'New'),
          existing.copyWith(title: 'Overwrite'),
        ]),
        throwsA(isA<DatabaseException>()),
      );
      final notes = await repository.loadNotes();
      expect(notes, hasLength(1));
      expect(notes.single.title, 'Keep');
    });

    test('insertImportedNotes stores folders before their notes', () async {
      await repository.insertImportedNotes(
        <Note>[
          Note(
            id: 'n1',
            title: 'In folder',
            content: '',
            date: '2026-01-01',
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Work', date: '2026-01-01'),
        ],
      );

      expect((await repository.loadFolders()).single.id, 'f1');
      expect((await repository.loadNotes()).single.folderId, 'f1');
    });

    test('a note conflict rolls back the imported folders too', () async {
      await repository.upsertNote(
        Note(id: 'n1', title: 'Existing', content: '', date: '2026-01-01'),
      );

      await expectLater(
        repository.insertImportedNotes(
          <Note>[
            Note(
              id: 'n1',
              title: 'Conflict',
              content: '',
              date: '2026-01-01',
              folderId: 'f1',
            ),
          ],
          folders: <Folder>[
            Folder(id: 'f1', name: 'Work', date: '2026-01-01'),
          ],
        ),
        throwsA(isA<DatabaseException>()),
      );

      expect(await repository.loadFolders(), isEmpty);
      expect((await repository.loadNotes()).single.title, 'Existing');
    });

    test('a fresh install starts empty', () async {
      final notes = await repository.loadNotes();

      expect(notes, isEmpty);
      expect(await repository.loadFolders(), isEmpty);
    });

    test('upsertNotes writes every note of the batch', () async {
      await repository.upsertNotes(<Note>[
        Note(id: 'a', title: 'A', content: '', date: '2026-01-01'),
        Note(id: 'b', title: 'B', content: '', date: '2026-01-02'),
      ]);

      expect(
        (await repository.loadNotes()).map((Note note) => note.id),
        containsAll(<String>['a', 'b']),
      );
    });

    test('trashNotes moves the whole batch to the trash', () async {
      await repository.upsertNotes(<Note>[
        Note(id: 'a', title: 'A', content: '', date: '2026-01-01'),
        Note(id: 'b', title: 'B', content: '', date: '2026-01-02'),
        Note(id: 'c', title: 'C', content: '', date: '2026-01-03'),
      ]);

      await repository.trashNotes(<String>['a', 'c']);

      expect(
        (await repository.loadNotes()).map((Note note) => note.id),
        <String>['b'],
      );
      expect(
        (await repository.loadTrashNotes()).map((Note note) => note.id),
        containsAll(<String>['a', 'c']),
      );
    });

    test('a configured provider with no passphrase fails closed', () async {
      final SQLiteNotesRepository guarded = SQLiteNotesRepository(
        databaseFactoryOverride: databaseFactoryFfi,
        databasePath: '${tempDir.path}/guarded.db',
        documentsDirectory: () async => tempDir,
        passwordProvider: () async => null,
      );

      await expectLater(
        guarded.loadNotes(),
        throwsA(isA<StorageUnavailableException>()),
      );
    });

    test('deleteAllFolders empties the folders, trashed or not', () async {
      await repository.upsertFolder(
        Folder(id: 'f1', name: 'One', date: '2026-01-01 00:00:00.000'),
      );
      await repository.upsertFolder(
        Folder(id: 'f2', name: 'Two', date: '2026-01-02 00:00:00.000'),
      );
      await repository.trashFolder('f2');
      expect(await repository.loadFolders(), hasLength(1));
      expect(await repository.loadTrashFolders(), hasLength(1));

      await repository.deleteAllFolders();

      expect(await repository.loadFolders(), isEmpty);
      expect(await repository.loadTrashFolders(), isEmpty);
    });

    test('discards pre-release JSON and backup test data', () async {
      for (final name in [
        'local_persistence.json',
        'local_persistence.json.bak',
        'tano_notes.db.plain.bak',
      ]) {
        await File(
          '${tempDir.path}/$name',
        ).writeAsString('obsolete private test data');
      }
      expect(await repository.loadNotes(), isEmpty);
      for (final name in [
        'local_persistence.json',
        'local_persistence.json.bak',
        'tano_notes.db.plain.bak',
      ]) {
        expect(await File('${tempDir.path}/$name').exists(), isFalse);
      }
    });

    test('trash, restore and permanent delete round-trip', () async {
      await repository.upsertNote(
        Note(
          id: '1',
          title: 'Keep me',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
        ),
      );

      await repository.trashNote('1');
      expect(await repository.loadNotes(), isEmpty);
      expect(
        (await repository.loadTrashNotes()).map((n) => n.id),
        contains('1'),
      );

      await repository.restoreNote('1');
      expect((await repository.loadNotes()).map((n) => n.id), contains('1'));
      expect(await repository.loadTrashNotes(), isEmpty);

      await repository.trashNote('1');
      await repository.deleteNotePermanently('1');
      expect(await repository.loadTrashNotes(), isEmpty);
    });

    test(
      'discards the pre-release plaintext database without retaining a backup',
      () async {
        final String path = '${tempDir.path}/tano_notes.db';

        // A database produced by a version before encryption: plain SQLite.
        final Database legacy = await databaseFactoryFfi.openDatabase(path);
        await legacy.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          title TEXT,
          content TEXT,
          date TEXT,
          important INTEGER,
          category TEXT,
          isDeleted INTEGER DEFAULT 0,
          isPinned INTEGER DEFAULT 0,
          isLocked INTEGER DEFAULT 0,
          deletedAt TEXT,
          attachments TEXT,
          coverImage TEXT
        )
      ''');
        await legacy.execute('PRAGMA user_version = 5');
        await legacy.insert('notes', <String, Object?>{
          'id': 'legacy-enc',
          'title': 'Before encryption',
          'content': 'secret content',
          'date': '2026-01-01 00:00:00.000',
          'important': 0,
          'category': 'note',
          'isDeleted': 0,
          'isPinned': 0,
          'isLocked': 0,
        });
        await legacy.close();

        final SQLiteNotesRepository encrypted = SQLiteNotesRepository(
          databaseFactoryOverride: databaseFactoryFfi,
          databasePath: path,
          documentsDirectory: () async => tempDir,
          passwordProvider: () async => 'test-passphrase',
        );
        final notes = await encrypted.loadNotes();

        expect(notes, isEmpty);
        expect(File('$path.plain.bak').existsSync(), isFalse);
      },
    );

    test('stores and reloads createdAt and updatedAt', () async {
      await repository.upsertNote(
        Note(
          id: 'stamped',
          title: 'Stamped',
          date: '2026-01-10 00:00:00.000',
          createdAt: '2026-01-01 00:00:00.000',
          updatedAt: '2026-02-01 00:00:00.000',
        ),
      );

      final notes = await repository.loadNotes();
      final stored = notes.firstWhere((n) => n.id == 'stamped');

      expect(stored.createdAt, '2026-01-01 00:00:00.000');
      expect(stored.updatedAt, '2026-02-01 00:00:00.000');
    });

    test('migrates a v6 database and backfills the timestamps', () async {
      final String path = '${tempDir.path}/tano_notes.db';
      final Database legacy = await databaseFactoryFfi.openDatabase(path);
      await legacy.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          title TEXT,
          content TEXT,
          date TEXT,
          important INTEGER,
          category TEXT,
          isDeleted INTEGER DEFAULT 0,
          isPinned INTEGER DEFAULT 0,
          isLocked INTEGER DEFAULT 0,
          deletedAt TEXT,
          attachments TEXT,
          coverImage TEXT,
          folderId TEXT
        )
      ''');
      await legacy.execute('''
        CREATE TABLE folders (
          id TEXT PRIMARY KEY,
          name TEXT,
          date TEXT,
          important INTEGER DEFAULT 0,
          category TEXT,
          isPinned INTEGER DEFAULT 0,
          isDeleted INTEGER DEFAULT 0,
          deletedAt TEXT
        )
      ''');
      await legacy.execute('PRAGMA user_version = 6');
      await legacy.insert('notes', <String, Object?>{
        'id': 'n1',
        'title': 'Kept',
        'content': 'x',
        'date': '2026-01-01 00:00:00.000',
        'important': 0,
        'category': 'note',
        'isDeleted': 0,
        'isPinned': 0,
        'isLocked': 0,
      });
      await legacy.insert('folders', <String, Object?>{
        'id': 'f1',
        'name': 'Studies',
        'date': '2026-01-02 00:00:00.000',
        'important': 0,
        'category': 'nuage',
        'isPinned': 0,
        'isDeleted': 0,
      });
      await legacy.close();

      final notes = await repository.loadNotes();
      final note = notes.firstWhere((n) => n.id == 'n1');
      expect(note.createdAt, '2026-01-01 00:00:00.000');
      expect(note.updatedAt, '2026-01-01 00:00:00.000');

      final folders = await repository.loadFolders();
      final folder = folders.firstWhere((f) => f.id == 'f1');
      expect(folder.createdAt, '2026-01-02 00:00:00.000');
      expect(folder.updatedAt, '2026-01-02 00:00:00.000');

      // The cover column, missed by the v6 upgrade, is restored.
      await repository.upsertFolder(folder.copyWith(coverImage: 'cover.png'));
      final reloaded = (await repository.loadFolders()).firstWhere(
        (f) => f.id == 'f1',
      );
      expect(reloaded.coverImage, 'cover.png');
    });

    test(
      'migrates a v6 database that already has folders.coverImage',
      () async {
        final String path = '${tempDir.path}/tano_notes.db';
        final Database legacy = await databaseFactoryFfi.openDatabase(path);
        await legacy.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          title TEXT,
          content TEXT,
          date TEXT,
          important INTEGER,
          category TEXT,
          isDeleted INTEGER DEFAULT 0,
          isPinned INTEGER DEFAULT 0,
          isLocked INTEGER DEFAULT 0,
          deletedAt TEXT,
          attachments TEXT,
          coverImage TEXT,
          folderId TEXT
        )
      ''');
        await legacy.execute('''
        CREATE TABLE folders (
          id TEXT PRIMARY KEY,
          name TEXT,
          date TEXT,
          important INTEGER DEFAULT 0,
          category TEXT,
          isPinned INTEGER DEFAULT 0,
          isDeleted INTEGER DEFAULT 0,
          deletedAt TEXT,
          coverImage TEXT
        )
      ''');
        await legacy.execute('PRAGMA user_version = 6');
        await legacy.insert('notes', <String, Object?>{
          'id': 'n1',
          'title': 'Kept',
          'date': '2026-01-01 00:00:00.000',
          'important': 0,
          'category': 'note',
          'isDeleted': 0,
          'isPinned': 0,
          'isLocked': 0,
        });
        await legacy.insert('folders', <String, Object?>{
          'id': 'f1',
          'name': 'Studies',
          'date': '2026-01-02 00:00:00.000',
          'important': 0,
          'category': 'nuage',
          'isPinned': 0,
          'isDeleted': 0,
          'coverImage': 'kept.png',
        });
        await legacy.close();

        final folders = await repository.loadFolders();
        final folder = folders.firstWhere((f) => f.id == 'f1');

        expect(folder.coverImage, 'kept.png');
        expect(folder.createdAt, '2026-01-02 00:00:00.000');
      },
    );

    test('searchNotes escapes LIKE wildcards literally', () async {
      await repository.upsertNote(
        Note(
          id: 'pct',
          title: '100% done',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
        ),
      );
      await repository.upsertNote(
        Note(
          id: 'under',
          title: 'a_b',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
        ),
      );
      await repository.upsertNote(
        Note(
          id: 'plain',
          title: 'plain',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
        ),
      );

      final percent = await repository.searchNotes('%');
      expect(percent.map((n) => n.id), contains('pct'));
      expect(percent.map((n) => n.id), isNot(contains('plain')));

      final underscore = await repository.searchNotes('_');
      expect(underscore.map((n) => n.id), contains('under'));
      expect(underscore.map((n) => n.id), isNot(contains('plain')));
    });
  });
}
