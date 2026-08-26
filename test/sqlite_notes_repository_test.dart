import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/notes_json_codec.dart';
import 'package:tano/core/repositories/sqlite_notes_repository.dart';

void main() {
  sqfliteFfiInit();

  late Directory tempDir;
  late SQLiteNotesRepository repository;

  setUp(() async {
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
    test('seeds demo notes on first launch', () async {
      final notes = await repository.loadNotes();

      expect(notes, hasLength(24));
      expect(notes.every((n) => !n.isDeleted), isTrue);
    });

    test('migrates notes from the legacy JSON file', () async {
      final legacyNotes = <Note>[
        Note(
          id: 'legacy-1',
          title: 'Legacy one',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
          important: true,
          category: 'menthe',
        ),
        Note(
          id: 'legacy-2',
          title: 'Legacy two',
          content: 'y',
          date: '2026-01-02 00:00:00.000',
          important: false,
          category: 'rose',
        ),
      ];
      final legacyFile = File('${tempDir.path}/local_persistence.json');
      await legacyFile.writeAsString(encodeNotes(legacyNotes));

      final notes = await repository.loadNotes();

      expect(notes, hasLength(2));
      expect(
        notes.map((n) => n.title),
        containsAll(<String>['Legacy one', 'Legacy two']),
      );
      expect(notes.firstWhere((n) => n.id == 'legacy-1').important, isTrue);

      // The legacy file is renamed to .bak, never deleted.
      expect(File('${tempDir.path}/local_persistence.json').existsSync(), isFalse);
      expect(
        File('${tempDir.path}/local_persistence.json.bak').existsSync(),
        isTrue,
      );
    });

    test('trash, restore and permanent delete round-trip', () async {
      await repository.upsertNote(
        Note(id: '1', title: 'Keep me', content: 'x', date: '2026-01-01 00:00:00.000'),
      );

      await repository.trashNote('1');
      expect(await repository.loadNotes(), isEmpty);
      expect((await repository.loadTrashNotes()).map((n) => n.id), contains('1'));

      await repository.restoreNote('1');
      expect((await repository.loadNotes()).map((n) => n.id), contains('1'));
      expect(await repository.loadTrashNotes(), isEmpty);

      await repository.trashNote('1');
      await repository.deleteNotePermanently('1');
      expect(await repository.loadTrashNotes(), isEmpty);
    });

    test('searchNotes escapes LIKE wildcards literally', () async {
      await repository.upsertNote(
        Note(id: 'pct', title: '100% done', content: 'x', date: '2026-01-01 00:00:00.000'),
      );
      await repository.upsertNote(
        Note(id: 'under', title: 'a_b', content: 'x', date: '2026-01-01 00:00:00.000'),
      );
      await repository.upsertNote(
        Note(id: 'plain', title: 'plain', content: 'x', date: '2026-01-01 00:00:00.000'),
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
