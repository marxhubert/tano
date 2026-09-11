import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:tano/core/services/installation_key.dart';
import 'package:tano/core/services/local_cipher.dart';

/// Stores attachments and cover images **encrypted** on disk under the
/// documents `attachments` directory.
///
/// Only the stored file name is persisted on the note. The plaintext is never
/// written to that directory: it is materialized on demand into the cache for
/// the system viewer or image widgets.
class AttachmentsStore {
  AttachmentsStore({
    Future<Directory> Function()? documentsDirectory,
    Future<Directory> Function()? cacheDirectory,
    Future<Uint8List> Function()? keyProvider,
  })  : _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory,
        _cacheDirectory = cacheDirectory ?? getTemporaryDirectory,
        _keyProvider = keyProvider ?? InstallationKey.instance.filesKey;

  final Future<Directory> Function() _documentsDirectory;
  final Future<Directory> Function() _cacheDirectory;
  final Future<Uint8List> Function() _keyProvider;

  /// Plaintext copies materialized on demand, keyed by stored name.
  final Map<String, String> _materialized = <String, String>{};

  Future<Directory> _dir() async {
    final Directory docs = await _documentsDirectory();
    final Directory dir = Directory(p.join(docs.path, 'attachments'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Encrypts [sourcePath] into the attachments directory under a unique file
  /// name and returns that stored name.
  Future<String> import(String sourcePath, String desiredName) async {
    final Directory dir = await _dir();
    final String name = await _uniqueName(dir, desiredName);
    final Uint8List clear = await File(sourcePath).readAsBytes();
    final Uint8List encrypted = await LocalCipher.encrypt(
      clear,
      await _keyProvider(),
    );
    await File(p.join(dir.path, name)).writeAsBytes(encrypted, flush: true);
    return name;
  }

  /// Absolute path of the stored (encrypted) attachment.
  Future<String> pathOf(String name) async {
    final Directory dir = await _dir();
    return p.join(dir.path, name);
  }

  /// Decrypts [name] into the cache and returns the plaintext path, for the
  /// system viewer or image widgets. The copy is reused until [remove].
  Future<String> materialize(String name) async {
    final String? cached = _materialized[name];
    if (cached != null && await File(cached).exists()) return cached;

    final Directory dir = await _dir();
    final Uint8List encrypted =
        await File(p.join(dir.path, name)).readAsBytes();
    final Uint8List clear = await LocalCipher.decrypt(
      encrypted,
      await _keyProvider(),
    );

    final Directory cache = Directory(
      p.join((await _cacheDirectory()).path, 'tano_attachments'),
    );
    if (!await cache.exists()) {
      await cache.create(recursive: true);
    }
    final File file = File(p.join(cache.path, name));
    await file.writeAsBytes(clear, flush: true);
    _materialized[name] = file.path;
    return file.path;
  }

  /// Deletes the stored attachment and any materialized plaintext copy.
  Future<void> remove(String name) async {
    final Directory dir = await _dir();
    final File file = File(p.join(dir.path, name));
    if (await file.exists()) {
      await file.delete();
    }
    final String? temp = _materialized.remove(name);
    if (temp != null) {
      final File tempFile = File(temp);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  Future<String> _uniqueName(Directory dir, String desiredName) async {
    String candidate = _sanitize(desiredName);
    if (!await File(p.join(dir.path, candidate)).exists()) return candidate;

    final String ext = p.extension(candidate);
    final String base = ext.isEmpty
        ? candidate
        : candidate.substring(0, candidate.length - ext.length);
    int i = 1;
    while (await File(p.join(dir.path, candidate)).exists()) {
      candidate = '$base ($i)$ext';
      i++;
    }
    return candidate;
  }

  /// Keeps only the base name so a picked path cannot escape the directory.
  String _sanitize(String name) {
    final String base = p.basename(name);
    return base.trim().isEmpty ? 'fichier' : base;
  }
}
