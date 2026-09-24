import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/repositories/sqlite_notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/services/export_service.dart';
import 'package:tano/core/services/import_service.dart';

/// Minimal in-memory store: the fuzz tests only care that the import path
/// cannot escape with an uncontrolled error.
class _MemoryRepo implements NotesRepository {
  final List<Note> notes = <Note>[];

  @override
  Future<List<Note>> loadNotes() async =>
      notes.where((Note n) => !n.isDeleted).toList();
  @override
  Future<List<Note>> loadTrashNotes() async =>
      notes.where((Note n) => n.isDeleted).toList();
  @override
  Future<void> upsertNote(Note note) async {
    final int index = notes.indexWhere((Note n) => n.id == note.id);
    if (index == -1) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
  }

  @override
  Future<void> trashNote(String id) async {}
  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {}
  @override
  Future<List<Note>> searchNotes(String query) async => <Note>[];
  @override
  Future<void> deleteAllNotes() async => notes.clear();
}

/// Authentication that always succeeds, so a locked import proceeds.
class _OpenAuth extends AuthService {
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> authenticate({String? reason}) async => true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late AttachmentsStore store;
  final Uint8List key = Uint8List.fromList(List<int>.filled(32, 3));

  AttachmentsStore makeStore(Directory dir) => AttachmentsStore(
    documentsDirectory: () async => dir,
    cacheDirectory: () async => dir,
    keyProvider: () async => key,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tempDir = await Directory.systemTemp.createTemp('tano_fuzz_');
    store = makeStore(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Note note(int i) => Note(
    id: 'n$i',
    title: 'Note $i',
    content: 'body $i',
    date: '2026-01-01 00:00:00.000',
  );

  test('a mutated export never escapes as an uncontrolled error', () async {
    final Uint8List valid = await ExportService(
      attachments: store,
      argon2: Argon2Params.fast,
    ).build(
      notes: <Note>[note(0), note(1)],
      password: 'secret123',
    );
    // Deterministic: a seeded generator makes a failure reproducible.
    final Random random = Random(20260921);

    for (int round = 0; round < 64; round++) {
      final Uint8List mutated = Uint8List.fromList(valid);
      final int flips = 1 + random.nextInt(8);
      for (int flip = 0; flip < flips; flip++) {
        final int at = random.nextInt(mutated.length);
        mutated[at] ^= 1 << random.nextInt(8);
      }

      final ImportService importer = ImportService(
        repository: _MemoryRepo(),
        attachments: store,
        auth: _OpenAuth(),
        argon2: Argon2Params.fast,
      );
      try {
        await importer.import(mutated, password: 'secret123');
      } on ImportException {
        // The expected, controlled failure for a damaged export.
      }
    }
  });

  test('random bytes are always rejected with an ImportException', () async {
    final Random random = Random(7);
    for (int round = 0; round < 32; round++) {
      final Uint8List bytes = Uint8List.fromList(
        List<int>.generate(random.nextInt(4096), (_) => random.nextInt(256)),
      );
      final ImportService importer = ImportService(
        repository: _MemoryRepo(),
        attachments: store,
        auth: _OpenAuth(),
        argon2: Argon2Params.fast,
      );
      await expectLater(
        importer.import(bytes),
        throwsA(isA<ImportException>()),
      );
    }
  });

  test('a 300-note export imports and stays searchable', () async {
    final SQLiteNotesRepository repository = SQLiteNotesRepository(
      databaseFactoryOverride: databaseFactoryFfi,
      databasePath: '${tempDir.path}/tano_notes.db',
      documentsDirectory: () async => tempDir,
    );
    final List<Note> notes = <Note>[
      for (int i = 0; i < 300; i++) note(i),
    ];

    final Uint8List bytes = await ExportService(
      attachments: store,
    ).build(notes: notes);
    final ImportResult result = await ImportService(
      repository: repository,
      attachments: store,
      auth: _OpenAuth(),
    ).import(bytes);

    expect(result.added, 300);
    expect(await repository.loadNotes(), hasLength(300));
    // The FTS index was built while importing: a fresh search finds a note.
    expect(
      (await repository.searchNotes('note 250')).map((Note n) => n.id),
      contains('n250'),
    );
  });
}
