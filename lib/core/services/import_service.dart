import 'dart:convert';
import 'dart:typed_data';

import 'package:uuid/uuid.dart';
import 'package:tano/core/services/archive_validation.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/services/export_service.dart';
import 'package:tano/core/services/local_cipher.dart';
import 'package:tano/shared/config/service_locator.dart';

/// Outcome of an import, for the user-facing summary.
class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.unlocked,
    required this.attachments,
    this.foldersAdded = 0,
  });

  final int added;
  final int skipped;
  final int unlocked;
  final int attachments;

  /// Folders created by this import. A folder already present under the same
  /// id is skipped, and its notes attach to the existing one.
  final int foldersAdded;
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
  }) : _repository = repository,
       _attachments = attachments ?? getIt<AttachmentsStore>(),
       _auth = auth ?? getIt<AuthService>(),
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
    if (data.length > ArchiveValidation.maxArchiveBytes) {
      throw const ImportException('Export too large');
    }
    final Uint8List zipped = await _openArchive(data, password);

    late final Map<String, Uint8List> files;
    late final List<Note> incoming;
    late final List<Folder> incomingFolders;
    try {
      files = ArchiveValidation.read(zipped);
      final manifest = files[ExportService.manifestName];
      if (manifest == null) throw const FormatException('Missing manifest');
      final decoded = jsonDecode(utf8.decode(manifest));
      if (decoded is! Map<String, dynamic> ||
          ![1, 2, 3].contains(decoded['version']) ||
          decoded['notes'] is! List) {
        throw const FormatException('Unsupported manifest');
      }
      final rows = decoded['notes'] as List;
      if (rows.length > 10000) throw const FormatException('Too many notes');
      incoming = rows
          .map((row) => Note.fromJson(row as Map<String, dynamic>))
          .toList();

      final Object? folderRows = decoded['folders'];
      if (folderRows is List) {
        if (folderRows.length > 10000) {
          throw const FormatException('Too many folders');
        }
        incomingFolders = folderRows
            .map((row) => Folder.fromJson(row as Map<String, dynamic>))
            .toList();
      } else {
        // Manifests 1 and 2 carried no folder list.
        incomingFolders = <Folder>[];
      }

      final folderIds = <String>{};
      for (final Folder folder in incomingFolders) {
        if (folder.id.trim().isEmpty ||
            folder.id.length > 256 ||
            !folderIds.add(folder.id) ||
            folder.isDeleted) {
          throw const FormatException('Invalid folder');
        }
        final String? cover = folder.coverImage;
        if (cover != null) {
          AttachmentsStore.validateName(cover);
          if (!files.containsKey('${ExportService.attachmentsFolder}$cover')) {
            throw const FormatException('Missing attachment');
          }
        }
      }

      for (final note in incoming) {
        if (note.id.trim().isEmpty || note.id.length > 256) {
          throw const FormatException('Invalid note id');
        }
        for (final name in [
          ...note.attachments,
          if (note.coverImage != null) note.coverImage!,
        ]) {
          AttachmentsStore.validateName(name);
          if (!files.containsKey('${ExportService.attachmentsFolder}$name')) {
            throw const FormatException('Missing attachment');
          }
        }
      }
    } catch (_) {
      throw const ImportException('Invalid or unsupported .tano export');
    }
    final existingIds = <String>{
      for (final note in await _repository.loadNotes()) note.id,
      for (final note in await _repository.loadTrashNotes()) note.id,
    };
    final Set<String> existingFolderIds = <String>{};
    if (_repository is FoldersRepository) {
      final FoldersRepository folders = _repository as FoldersRepository;
      existingFolderIds.addAll(
        (await folders.loadFolders()).map((Folder folder) => folder.id),
      );
      existingFolderIds.addAll(
        (await folders.loadTrashFolders()).map((Folder folder) => folder.id),
      );
    }

    final bool canLock = await _auth.isAvailable();
    var unlocked = 0;

    // A folder whose id is already known is not created again: its notes attach
    // to the existing one. A folder arriving twice is deduplicated the same way.
    // A locked folder is unlocked on a device that cannot lock, exactly like a
    // note, so it never becomes unreachable.
    final List<Folder> foldersToInsert = <Folder>[];
    for (var folder in incomingFolders) {
      if (!existingFolderIds.add(folder.id)) continue;
      if (folder.isLocked && !canLock) {
        folder = folder.copyWith(isLocked: false);
        unlocked++;
      }
      foldersToInsert.add(folder);
    }
    final Set<String> archiveFolderIds = <String>{
      for (final Folder folder in incomingFolders) folder.id,
    };

    final pending = <Note>[];
    var skipped = 0;
    for (var note in incoming) {
      if (!existingIds.add(note.id)) {
        skipped++;
        continue;
      }
      if (note.isLocked && !canLock) {
        note = note.copyWith(isLocked: false);
        unlocked++;
      }
      // Only a folder the archive itself carries keeps the note filed. A
      // manifest without folders (v1/v2), or a note pointing elsewhere, lands
      // unfiled instead of attaching to an unrelated local folder.
      if (note.folderId == null || !archiveFolderIds.contains(note.folderId)) {
        note = note.withoutFolder();
      }
      pending.add(note);
    }
    final created = <String>[];
    final names = <String, String>{};
    try {
      Future<void> copyAttachment(String name) async {
        if (names.containsKey(name)) return;
        final bytes = files['${ExportService.attachmentsFolder}$name']!;
        var target = name;
        while (!await _attachments.writeIfAbsent(target, bytes)) {
          target = '${const Uuid().v4()}_$name';
        }
        created.add(target);
        names[name] = target;
      }

      for (final note in pending) {
        for (final name in [
          ...note.attachments,
          if (note.coverImage != null) note.coverImage!,
        ]) {
          await copyAttachment(name);
        }
      }
      for (final folder in foldersToInsert) {
        final String? cover = folder.coverImage;
        if (cover != null) await copyAttachment(cover);
      }

      final toStore = pending
          .map(
            (note) => note.copyWith(
              attachments: note.attachments
                  .map((name) => names[name]!)
                  .toList(),
              coverImage: note.coverImage == null
                  ? null
                  : names[note.coverImage],
            ),
          )
          .toList();
      final List<Folder> foldersToStore = foldersToInsert
          .map(
            (folder) => folder.coverImage == null
                ? folder
                : folder.copyWith(coverImage: names[folder.coverImage]),
          )
          .toList();
      if (_repository is AtomicNoteImporter) {
        // A concurrent collision aborts the complete batch, not a partial import.
        await (_repository as AtomicNoteImporter).insertImportedNotes(
          toStore,
          folders: foldersToStore,
        );
      } else {
        // Compatibility for alternate repositories; production uses SQLite's
        // atomic implementation. Such adapters must provide atomic imports.
        if (_repository is FoldersRepository) {
          final FoldersRepository folders = _repository as FoldersRepository;
          for (final folder in foldersToStore) {
            await folders.upsertFolder(folder);
          }
        }
        for (final note in toStore) {
          await _repository.upsertNote(note);
        }
      }
    } catch (_) {
      if (_repository is AtomicNoteImporter) {
        for (final name in created) {
          await _attachments.remove(name);
        }
      }
      rethrow;
    }
    final added = pending.length;
    final attachments = created.length;

    return ImportResult(
      added: added,
      skipped: skipped,
      unlocked: unlocked,
      attachments: attachments,
      foldersAdded: foldersToInsert.length,
    );
  }

  Future<Uint8List> _openArchive(Uint8List data, String? password) async {
    // A cleartext export is a plain ZIP.
    if (!isEncrypted(data)) return data;

    if (data[ExportService.magic.length] != ExportService.version) {
      throw const ImportException('Unsupported export version');
    }
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
    final Uint8List key = await ExportService.deriveKey(
      password,
      salt,
      params: _argon2,
    );
    try {
      return await LocalCipher.decrypt(payload, key);
    } catch (_) {
      throw const ImportException('Wrong password or corrupted export');
    }
  }
}
