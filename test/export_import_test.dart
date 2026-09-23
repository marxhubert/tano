import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/services/export_service.dart';
import 'package:tano/core/services/import_service.dart';

class _FakeAuth extends AuthService {
  _FakeAuth({this.available = false});

  final bool available;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({String? reason}) async => available;
}

class _InMemoryRepository implements NotesRepository {
  _InMemoryRepository([List<Note>? notes]) : notes = notes ?? <Note>[];

  final List<Note> notes;

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

Note _note({
  String id = 'a',
  String title = 'Alpha',
  String content = 'hello',
  bool isLocked = false,
  List<String> attachments = const <String>[],
}) {
  return Note(
    id: id,
    title: title,
    content: content,
    date: '2026-01-01 00:00:00.000',
    isLocked: isLocked,
    attachments: attachments,
  );
}

void main() {
  late Directory sourceDir;
  late Directory targetDir;
  late _InMemoryRepository repository;
  late AttachmentsStore sourceAttachments;
  late AttachmentsStore targetAttachments;
  final Uint8List key = Uint8List.fromList(List<int>.filled(32, 9));

  AttachmentsStore makeStore(Directory dir) => AttachmentsStore(
    documentsDirectory: () async => dir,
    cacheDirectory: () async => dir,
    keyProvider: () async => key,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sourceDir = await Directory.systemTemp.createTemp('tano_export_src');
    targetDir = await Directory.systemTemp.createTemp('tano_export_dst');
    repository = _InMemoryRepository();
    sourceAttachments = makeStore(sourceDir);
    targetAttachments = makeStore(targetDir);
  });

  test(
    'attachment collisions preserve both contents and remap the imported note',
    () async {
      await sourceAttachments.writeIfAbsent(
        'same.txt',
        Uint8List.fromList([1, 2]),
      );
      await targetAttachments.writeIfAbsent(
        'same.txt',
        Uint8List.fromList([9]),
      );
      final data = await ExportService(attachments: sourceAttachments).build(
        notes: [
          _note(attachments: ['same.txt']),
        ],
      );
      await ImportService(
        repository: repository,
        attachments: targetAttachments,
        auth: _FakeAuth(),
      ).import(data);
      final name = repository.notes.single.attachments.single;
      expect(name, isNot('same.txt'));
      expect(await targetAttachments.read('same.txt'), [9]);
      expect(await targetAttachments.read(name), [1, 2]);
    },
  );

  tearDown(() async {
    for (final Directory dir in <Directory>[sourceDir, targetDir]) {
      if (await dir.exists()) await dir.delete(recursive: true);
    }
  });

  // Cheap Argon2id parameters: the production cost times the tests out.
  ExportService exporter() =>
      ExportService(attachments: sourceAttachments, argon2: Argon2Params.fast);
  ImportService importer({bool canLock = false}) => ImportService(
    repository: repository,
    attachments: targetAttachments,
    auth: _FakeAuth(available: canLock),
    argon2: Argon2Params.fast,
  );

  test(
    'cleartext export is a plain ZIP and round-trips notes + attachments',
    () async {
      final File file = File('${sourceDir.path}/src.txt')
        ..writeAsStringSync('attachment bytes');
      final String name = await sourceAttachments.import(file.path, 'src.txt');

      final Uint8List bytes = await exporter().build(
        notes: <Note>[
          _note(attachments: <String>[name]),
        ],
      );

      // Plain ZIP magic "PK".
      expect(bytes.sublist(0, 2), <int>[0x50, 0x4B]);
      expect(ImportService.isEncrypted(bytes), isFalse);

      final ImportResult result = await importer().import(bytes);
      expect(result.added, 1);
      expect(result.attachments, 1);

      final List<Note> imported = await repository.loadNotes();
      expect(imported.single.title, 'Alpha');
      expect(imported.single.attachments, contains(name));
      expect(
        utf8.decode(await targetAttachments.read(name)),
        'attachment bytes',
      );
    },
  );

  test('encrypted export needs the right password', () async {
    final Uint8List bytes = await exporter().build(
      notes: <Note>[_note()],
      password: 'secret123',
    );
    expect(ImportService.isEncrypted(bytes), isTrue);

    await expectLater(
      importer().import(bytes),
      throwsA(isA<ImportException>()),
    );
    await expectLater(
      importer().import(bytes, password: 'wrong'),
      throwsA(isA<ImportException>()),
    );

    final ImportResult result = await importer().import(
      bytes,
      password: 'secret123',
    );
    expect(result.added, 1);
    expect((await repository.loadNotes()).single.title, 'Alpha');
  });

  test('merge skips notes whose id already exists', () async {
    await repository.upsertNote(_note(id: 'a', title: 'Existing'));
    final Uint8List bytes = await exporter().build(
      notes: <Note>[
        _note(id: 'a', title: 'Imported a'),
        _note(id: 'b', title: 'Imported b'),
      ],
    );

    final ImportResult result = await importer().import(bytes);
    expect(result.added, 1);
    expect(result.skipped, 1);

    final List<String> titles = (await repository.loadNotes())
        .map((Note n) => n.title)
        .toList();
    expect(titles, containsAll(<String>['Existing', 'Imported b']));
    expect(titles, isNot(contains('Imported a')));
  });

  test('cleartext export refuses to include a locked note', () async {
    expect(
      () => exporter().build(notes: <Note>[_note(isLocked: true)]),
      throwsA(isA<ExportException>()),
    );
  });

  test(
    'locked notes are unlocked on import when the device cannot lock',
    () async {
      final Uint8List bytes = await exporter().build(
        notes: <Note>[_note(isLocked: true)],
        password: 'secret123',
      );
      final ImportResult result = await importer(
        canLock: false,
      ).import(bytes, password: 'secret123');
      expect(result.unlocked, 1);
      expect((await repository.loadNotes()).single.isLocked, isFalse);
    },
  );

  test('locked notes stay locked on import when the device can lock', () async {
    final Uint8List bytes = await exporter().build(
      notes: <Note>[_note(isLocked: true)],
      password: 'secret123',
    );
    final ImportResult result = await importer(
      canLock: true,
    ).import(bytes, password: 'secret123');
    expect(result.unlocked, 0);
    expect((await repository.loadNotes()).single.isLocked, isTrue);
  });
  test('duplicate ids in an import never overwrite the first note', () async {
    final bytes = await exporter().build(
      notes: [
        _note(id: 'same', title: 'First'),
        _note(id: 'same', title: 'Second'),
      ],
    );
    final result = await importer().import(bytes);
    expect(result.added, 1);
    expect(result.skipped, 1);
    expect(repository.notes.single.title, 'First');
  });

  test('an import cannot overwrite a note in the trash', () async {
    repository.notes.add(
      _note(id: 'trashed', title: 'Keep').copyWith(isDeleted: true),
    );
    final bytes = await exporter().build(
      notes: [_note(id: 'trashed', title: 'Replace')],
    );
    final result = await importer().import(bytes);
    expect(result.added, 0);
    expect(repository.notes.single.title, 'Keep');
    expect(repository.notes.single.isDeleted, isTrue);
  });

  test('unsupported encrypted container versions are rejected', () async {
    final bytes = await exporter().build(
      notes: [_note()],
      password: 'secret123',
    );
    bytes[ExportService.magic.length] = 99;
    await expectLater(
      importer().import(bytes, password: 'secret123'),
      throwsA(isA<ImportException>()),
    );
    expect(repository.notes, isEmpty);
  });
}
