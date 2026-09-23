import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/repositories/attachments_store.dart';

void main() {
  late Directory tempDir;
  late AttachmentsStore store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tano_attachments_test');
    store = AttachmentsStore(
      documentsDirectory: () async => tempDir,
      cacheDirectory: () async => tempDir,
      keyProvider: () async => Uint8List.fromList(List<int>.filled(32, 7)),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('import encrypts the file and materialize decrypts it', () async {
    final File source = File('${tempDir.path}/src.txt');
    await source.writeAsString('hello');

    final String name = await store.import(source.path, 'note.txt');
    expect(name, 'note.txt');

    // The stored file must not be readable as plaintext.
    final String storedPath = await store.pathOf(name);
    final List<int> onDisk = await File(storedPath).readAsBytes();
    expect(String.fromCharCodes(onDisk), isNot('hello'));

    // The plaintext is only materialized on demand.
    final String plainPath = await store.materialize(name);
    expect(await File(plainPath).readAsString(), 'hello');
  });

  test('materialize reuses the decrypted copy', () async {
    final File source = File('${tempDir.path}/src2.txt');
    await source.writeAsString('payload');
    final String name = await store.import(source.path, 'note2.txt');

    final String first = await store.materialize(name);
    final String second = await store.materialize(name);
    expect(first, second);
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

  test('remove deletes the stored file and the materialized copy', () async {
    final File source = File('${tempDir.path}/src.txt');
    await source.writeAsString('x');

    final String name = await store.import(source.path, 'note.txt');
    final String plainPath = await store.materialize(name);
    expect(await File(plainPath).exists(), isTrue);

    await store.remove(name);

    expect(await File(await store.pathOf(name)).exists(), isFalse);
    expect(await File(plainPath).exists(), isFalse);
  });
  test('an old materialized copy is swept after its viewing window', () async {
    final File source = File('${tempDir.path}/src3.txt');
    await source.writeAsString('secret');
    final String name = await store.import(source.path, 'note3.txt');
    final String plain = await store.materialize(name);

    // Age the plaintext beyond the shelf life, then sweep.
    await File(plain).setLastModified(
      DateTime.now().subtract(AttachmentsStore.materializedTtl * 2),
    );
    await store.clearExpiredMaterialized();

    expect(await File(plain).exists(), isFalse);
  });

  test('a fresh materialized copy survives the sweep', () async {
    final File source = File('${tempDir.path}/src4.txt');
    await source.writeAsString('fresh');
    final String name = await store.import(source.path, 'note4.txt');
    final String plain = await store.materialize(name);

    await store.clearExpiredMaterialized();

    expect(await File(plain).exists(), isTrue);
  });

  test('untrusted names cannot escape the attachment store', () async {
    for (final name in [
      '../outside',
      '/tmp/outside',
      r'..\outside',
      '.',
      '..',
    ]) {
      await expectLater(
        store.writeIfAbsent(name, Uint8List(1)),
        throwsA(isA<FormatException>()),
      );
      await expectLater(store.read(name), throwsA(isA<FormatException>()));
      await expectLater(store.remove(name), throwsA(isA<FormatException>()));
    }
  });

  test('reset removes plaintext left by a previous process', () async {
    await store.writeIfAbsent('private.txt', Uint8List.fromList([1, 2, 3]));
    final plain = await store.materialize('private.txt');
    final restarted = AttachmentsStore(
      documentsDirectory: () async => tempDir,
      cacheDirectory: () async => tempDir,
      keyProvider: () async => Uint8List(32),
    );
    await restarted.deleteAll();
    expect(await File(plain).exists(), isFalse);
  });
}
