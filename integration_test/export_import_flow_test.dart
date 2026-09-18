import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/sqlite_notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/services/export_service.dart';
import 'package:tano/core/services/import_service.dart';

/// Answers the lock question without the device UI.
class _Auth extends AuthService {
  _Auth({required this.available});

  final bool available;

  @override
  Future<bool> isAvailable() async => available;
}

/// The round trip the in-memory tests cannot prove: two real encrypted
/// databases, one export, one merge, on the device's own storage.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late SQLiteNotesRepository source;
  late SQLiteNotesRepository target;

  Future<SQLiteNotesRepository> open(String name) async {
    final Directory dir = await Directory(
      p.join(root.path, name),
    ).create(recursive: true);
    return SQLiteNotesRepository(
      databasePath: p.join(dir.path, 'notes.db'),
      documentsDirectory: () async => dir,
      passwordProvider: () async => 'integration-test-pass',
    );
  }

  setUp(() async {
    root = await getTemporaryDirectory();
    source = await open('tano_export_src');
    target = await open('tano_export_dst');
  });

  tearDown(() async {
    for (final String name in <String>['tano_export_src', 'tano_export_dst']) {
      final Directory dir = Directory(p.join(root.path, name));
      if (dir.existsSync()) await dir.delete(recursive: true);
    }
  });

  ImportService importer({required bool canLock}) => ImportService(
    repository: target,
    attachments: AttachmentsStore(),
    auth: _Auth(available: canLock),
    argon2: Argon2Params.fast,
  );

  test('an encrypted export comes back into a fresh database', () async {
    await source.upsertNote(
      Note(id: 'n1', title: 'Alpha', content: 'a', date: '2026-01-01 00:00:00.000'),
    );
    await source.upsertNote(
      Note(
        id: 'n2',
        title: 'Bravo',
        content: 'b',
        date: '2026-01-02 00:00:00.000',
        isLocked: true,
      ),
    );

    final Uint8List bytes = await ExportService(
      argon2: Argon2Params.fast,
    ).build(notes: await source.loadNotes(), password: 'secret123');
    expect(ImportService.isEncrypted(bytes), isTrue);

    final ImportResult first = await importer(
      canLock: true,
    ).import(bytes, password: 'secret123');
    expect(first.added, 2);
    expect(first.skipped, 0);

    final List<Note> restored = await target.loadNotes();
    expect(restored.map((Note n) => n.id), containsAll(<String>['n1', 'n2']));
    expect(restored.firstWhere((Note n) => n.id == 'n2').isLocked, isTrue);

    // Merging the same export twice never duplicates a note.
    final ImportResult second = await importer(
      canLock: true,
    ).import(bytes, password: 'secret123');
    expect(second.added, 0);
    expect(second.skipped, 2);
    expect(await target.loadNotes(), hasLength(2));
  });

  test('a wrong password is refused', () async {
    await source.upsertNote(
      Note(id: 'n1', title: 'Alpha', content: 'a', date: '2026-01-01 00:00:00.000'),
    );
    final Uint8List bytes = await ExportService(
      argon2: Argon2Params.fast,
    ).build(notes: await source.loadNotes(), password: 'secret123');

    await expectLater(
      importer(canLock: true).import(bytes, password: 'wrong-password'),
      throwsA(isA<ImportException>()),
    );
  });

  test('a locked note is stored unlocked when the device cannot lock', () async {
    await source.upsertNote(
      Note(
        id: 'n1',
        title: 'Alpha',
        content: 'a',
        date: '2026-01-01 00:00:00.000',
        isLocked: true,
      ),
    );
    final Uint8List bytes = await ExportService(
      argon2: Argon2Params.fast,
    ).build(notes: await source.loadNotes(), password: 'secret123');

    final ImportResult result = await importer(
      canLock: false,
    ).import(bytes, password: 'secret123');
    expect(result.added, 1);
    expect(result.unlocked, 1);
    expect((await target.loadNotes()).single.isLocked, isFalse);
  });
}