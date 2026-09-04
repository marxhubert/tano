import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores attachment files on disk under the documents attachments directory
/// and returns the stored file name (which is also persisted on the note).
/// Only the name is linked from the database; the system opens the file on
/// demand.
class AttachmentsStore {
  AttachmentsStore({Future<Directory> Function()? documentsDirectory})
      : _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectory;

  Future<Directory> _dir() async {
    final Directory docs = await _documentsDirectory();
    final Directory dir = Directory(p.join(docs.path, 'attachments'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies [sourcePath] into the attachments directory under a unique file
  /// name and returns that stored name.
  Future<String> import(String sourcePath, String desiredName) async {
    final Directory dir = await _dir();
    final String name = await _uniqueName(dir, desiredName);
    await File(sourcePath).copy(p.join(dir.path, name));
    return name;
  }

  /// Absolute path of a stored attachment, for opening with the system.
  Future<String> pathOf(String name) async {
    final Directory dir = await _dir();
    return p.join(dir.path, name);
  }

  /// Deletes a stored attachment, if present.
  Future<void> remove(String name) async {
    final Directory dir = await _dir();
    final File file = File(p.join(dir.path, name));
    if (await file.exists()) {
      await file.delete();
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
