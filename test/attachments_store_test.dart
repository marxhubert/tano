import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/repositories/attachments_store.dart';

void main() {
  late Directory tempDir;
  late AttachmentsStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tano_attachments_test');
    store = AttachmentsStore(documentsDirectory: () async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('import copies the file and returns its name', () async {
    final File source = File('${tempDir.path}/src.txt');
    await source.writeAsString('hello');

    final String name = await store.import(source.path, 'note.txt');
    expect(name, 'note.txt');

    final String path = await store.pathOf(name);
    expect(await File(path).readAsString(), 'hello');
  });

  test('import makes a unique name when the name already exists', () async {
    final File a = File('${tempDir.path}/a.txt');
    final File b = File('${tempDir.path}/b.txt');
    await a.writeAsString('1');
    await b.writeAsString('2');

    final String first = await store.import(a.path, 'note.txt');
    final String second = await store.import(b.path, 'note.txt');

    expect(first, 'note.txt');
    expect(second, 'note (1).txt');
  });

  test('remove deletes the stored file', () async {
    final File source = File('${tempDir.path}/src.txt');
    await source.writeAsString('x');

    final String name = await store.import(source.path, 'note.txt');
    await store.remove(name);

    expect(await File(await store.pathOf(name)).exists(), isFalse);
  });
}
