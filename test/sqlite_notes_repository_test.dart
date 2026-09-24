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

    test('migrates a v9 database and indexes it for search', () async {
      final String path = '${tempDir.path}/tano_notes.db';
      final Database legacy = await databaseFactoryFfi.openDatabase(path);
      await legacy.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          kind TEXT NOT NULL DEFAULT 'note' CHECK(kind IN ('note', 'task')),
          title TEXT,
          content TEXT,
          description TEXT NOT NULL DEFAULT '',
          date TEXT,
          important INTEGER,
          category TEXT,
          isDeleted INTEGER DEFAULT 0,
          isLocked INTEGER DEFAULT 0,
          deletedAt TEXT,
          attachments TEXT,
          coverImage TEXT,
          folderId TEXT,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      await legacy.execute('''
        CREATE TABLE folders (
          id TEXT PRIMARY KEY,
          name TEXT,
          date TEXT,
          important INTEGER DEFAULT 0,
          category TEXT,
          isLocked INTEGER DEFAULT 0,
          isDeleted INTEGER DEFAULT 0,
          deletedAt TEXT,
          coverImage TEXT,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      await legacy.execute('PRAGMA user_version = 9');
      await legacy.insert('notes', <String, Object?>{
        'id': 'legacy',
        'title': 'Legacy note',
        'content': 'searchable body',
        'description': '',
        'date': '2026-01-01 00:00:00.000',
        'isDeleted': 0,
        'isLocked': 0,
      });
      await legacy.close();

      // Opening at v10 creates the FTS index and backfills the existing notes.
      final List<Note> found = await repository.searchNotes('legacy');
      expect(found.map((Note n) => n.id), <String>['legacy']);
    });

    test('archive takes a note out of Home and back', () async {
      await repository.upsertNote(
        Note(
          id: 'arch',
          title: 'Set aside',
          content: '',
          date: '2026-01-01',
          folderId: 'f1',
        ),
      );

      await repository.archiveNote('arch');

      expect(await repository.loadNotes(), isEmpty);
      final List<Note> archived = await repository.loadArchivedNotes();
      expect(archived.single.id, 'arch');
      expect(archived.single.isArchived, isTrue);
      expect(archived.single.archivedAt, isNotNull);
      // An archived note never comes back through search.
      expect(await repository.searchNotes('aside'), isEmpty);

      await repository.restoreArchivedNote('arch');

      final Note restored = (await repository.loadNotes()).single;
      expect(restored.isArchived, isFalse);
      expect(restored.archivedAt, isNull);
      // Back to Home, and the creation date becomes the restore date.
      expect(restored.folderId, isNull);
      expect(restored.date, isNot('2026-01-01'));
      expect(await repository.loadArchivedNotes(), isEmpty);
    });

    test('restoreArchivedNotes brings a whole selection back', () async {
      await repository.upsertNotes(<Note>[
        Note(id: 'a', title: 'A', content: '', date: '2026-01-01'),
        Note(id: 'b', title: 'B', content: '', date: '2026-01-01'),
      ]);
      await repository.archiveNote('a');
      await repository.archiveNote('b');

      await repository.restoreArchivedNotes(<String>['a', 'b']);

      expect(
        (await repository.loadNotes()).map((Note n) => n.id),
        containsAll(<String>['a', 'b']),
      );
      expect(await repository.loadArchivedNotes(), isEmpty);
    });

    test('migrates a v10 database and adds the archive columns', () async {
      final String path = '${tempDir.path}/tano_notes.db';
      final Database legacy = await databaseFactoryFfi.openDatabase(path);
      await legacy.execute('''
        CREATE TABLE notes (
          id TEXT PRIMARY KEY,
          kind TEXT NOT NULL DEFAULT 'note' CHECK(kind IN ('note', 'task')),
          title TEXT,
          content TEXT,
          description TEXT NOT NULL DEFAULT '',
          date TEXT,
          important INTEGER,
          category TEXT,
          isDeleted INTEGER DEFAULT 0,
          isLocked INTEGER DEFAULT 0,
          deletedAt TEXT,
          attachments TEXT,
          coverImage TEXT,
          folderId TEXT,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      await legacy.execute('''
        CREATE TABLE folders (
          id TEXT PRIMARY KEY,
          name TEXT,
          date TEXT,
          important INTEGER DEFAULT 0,
          category TEXT,
          isLocked INTEGER DEFAULT 0,
          isDeleted INTEGER DEFAULT 0,
          deletedAt TEXT,
          coverImage TEXT,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
      await legacy.execute('PRAGMA user_version = 10');
      await legacy.insert('notes', <String, Object?>{
        'id': 'legacy',
        'title': 'Legacy',
        'content': '',
        'description': '',
        'date': '2026-01-01 00:00:00.000',
        'isDeleted': 0,
        'isLocked': 0,
      });
      await legacy.close();

      // Opening at v11 adds the archive columns; the old row archives cleanly.
      await repository.archiveNote('legacy');
      expect(
        (await repository.loadArchivedNotes()).map((Note n) => n.id),
        <String>['legacy'],
      );
    });

    test('searchNotes ignores punctuation and never treats it as a wildcard', () async {
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

      // Punctuation alone carries no word to match.
      expect(await repository.searchNotes('%'), isEmpty);
      expect(await repository.searchNotes('_'), isEmpty);
      // A word still finds its note, by prefix.
      expect(
        (await repository.searchNotes('100')).map((Note n) => n.id),
        contains('pct'),
      );
      expect(
        (await repository.searchNotes('a')).map((Note n) => n.id),
        contains('under'),
      );
      expect(
        (await repository.searchNotes('plain')).map((Note n) => n.id),
        contains('plain'),
      );
    });

    test('searchNotes finds a prefix in title, description or content', () async {
      await repository.upsertNote(
        Note(
          id: 'alpha',
          title: 'Alpha',
          content: 'nothing here',
          date: '2026-01-01 00:00:00.000',
        ),
      );
      await repository.upsertNote(
        Note(
          id: 'beta',
          title: 'Beta',
          description: 'the alphabet soup',
          content: '',
          date: '2026-01-02 00:00:00.000',
        ),
      );
      await repository.upsertNote(
        Note(
          id: 'gamma',
          title: 'Gamma',
          content: 'an alphabetic note',
          date: '2026-01-03 00:00:00.000',
        ),
      );

      expect(
        (await repository.searchNotes('alph')).map((Note n) => n.id),
        containsAll(<String>['alpha', 'beta', 'gamma']),
      );
      expect(
        (await repository.searchNotes('soup')).map((Note n) => n.id),
        <String>['beta'],
      );
    });

    test('searchNotes drops trashed notes and follows an update', () async {
      await repository.upsertNote(
        Note(
          id: 'moved',
          title: 'Before',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
        ),
      );
      expect(
        (await repository.searchNotes('before')).map((Note n) => n.id),
        <String>['moved'],
      );

      // An update must reindex: the old term is gone, the new one is found.
      await repository.upsertNote(
        Note(
          id: 'moved',
          title: 'After',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
        ),
      );
      expect(await repository.searchNotes('before'), isEmpty);
      expect(
        (await repository.searchNotes('after')).map((Note n) => n.id),
        <String>['moved'],
      );

      await repository.trashNote('moved');
      expect(await repository.searchNotes('after'), isEmpty);
    });

    test('ftsPrefixQuery quotes every word and drops punctuation', () {
      expect(ftsPrefixQuery('Hello World'), '"hello"* "world"*');
      expect(ftsPrefixQuery('a"b:c*'), '"a"* "b"* "c"*');
      expect(ftsPrefixQuery('%_  '), isNull);
      expect(ftsPrefixQuery(''), isNull);
    });

    test('escapeLikePattern escapes the LIKE wildcards for the fallback', () {
      expect(escapeLikePattern('100%'), '100\\%');
      expect(escapeLikePattern('a_b'), 'a\\_b');
      expect(escapeLikePattern('c\\d'), 'c\\\\d');
    });
  });
}
