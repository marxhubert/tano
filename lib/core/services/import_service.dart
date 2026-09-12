import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/notes_json_codec.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/services/export_service.dart';
import 'package:tano/core/services/local_cipher.dart';

/// Outcome of an import, for the user-facing summary.
class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.unlocked,
    required this.attachments,
  });

  final int added;
  final int skipped;
  final int unlocked;
  final int attachments;
}

/// Raised when an export cannot be opened.
class ImportException implements Exception {
  const ImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Restores notes and attachments from a `.tano` export.
///
/// Merges only: existing notes are never replaced or deleted, a note whose id
/// already exists is ignored.
class ImportService {
  ImportService({
    required NotesRepository repository,
    AttachmentsStore? attachments,
    AuthService? auth,
    Argon2Params argon2 = const Argon2Params(),
  })  : _repository = repository,
        _attachments = attachments ?? AttachmentsStore(),
        _auth = auth ?? AuthService.instance,
        _argon2 = argon2;

  final NotesRepository _repository;
  final AttachmentsStore _attachments;
  final AuthService _auth;
  final Argon2Params _argon2;

  /// Whether [data] is an encrypted container.
  static bool isEncrypted(Uint8List data) {
    final List<int> magic = utf8.encode(ExportService.magic);
    if (data.length < magic.length + 1) return false;
    for (int i = 0; i < magic.length; i++) {
      if (data[i] != magic[i]) return false;
    }
    return true;
  }

  /// Merges the export in [data] into the repository.
  Future<ImportResult> import(Uint8List data, {String? password}) async {
    final Uint8List zipped = await _openArchive(data, password);

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(zipped);
    } catch (_) {
      throw const ImportException('Not a valid .tano export');
    }

    ArchiveFile? manifest;
    for (final ArchiveFile file in archive.files) {
      if (file.name == ExportService.manifestName) {
        manifest = file;
        break;
      }
    }
    final Uint8List? manifestBytes = manifest?.readBytes();
    if (manifestBytes == null) {
      throw const ImportException('Export is missing its manifest');
    }

    final List<Note> incoming = decodeNotes(utf8.decode(manifestBytes));
    final Set<String> existingIds = (await _repository.loadNotes())
        .map((Note note) => note.id)
        .toSet();
    final bool canLock = await _auth.isAvailable();

    int added = 0;
    int skipped = 0;
    int unlocked = 0;
    for (final Note note in incoming) {
      if (existingIds.contains(note.id)) {
        skipped++;
        continue;
      }
      Note toStore = note;
      if (note.isLocked && !canLock) {
        toStore = note.copyWith(isLocked: false);
        unlocked++;
      }
      await _repository.upsertNote(toStore);
      added++;
    }

    int attachments = 0;
    for (final ArchiveFile file in archive.files) {
      if (!file.name.startsWith(ExportService.attachmentsFolder)) continue;
      final String name = file.name.substring(
        ExportService.attachmentsFolder.length,
      );
      if (name.isEmpty) continue;
      final Uint8List? bytes = file.readBytes();
      if (bytes == null) continue;
      if (await _attachments.writeIfAbsent(name, bytes)) attachments++;
    }

    return ImportResult(
      added: added,
      skipped: skipped,
      unlocked: unlocked,
      attachments: attachments,
    );
  }

  Future<Uint8List> _openArchive(Uint8List data, String? password) async {
    // A cleartext export is a plain ZIP.
    if (!isEncrypted(data)) return data;

    if (password == null || password.isEmpty) {
      throw const ImportException('This export is encrypted');
    }
    final int saltStart = utf8.encode(ExportService.magic).length + 1;
    if (data.length < saltStart + ExportService.saltLength) {
      throw const ImportException('Corrupted export');
    }
    final List<int> salt = data.sublist(
      saltStart,
      saltStart + ExportService.saltLength,
    );
    final Uint8List payload = data.sublist(
      saltStart + ExportService.saltLength,
    );
    final Uint8List key =
        await ExportService.deriveKey(password, salt, params: _argon2);
    try {
      return await LocalCipher.decrypt(payload, key);
    } catch (_) {
      throw const ImportException('Wrong password or corrupted export');
    }
  }
}
