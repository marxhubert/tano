import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/services/archive_validation.dart';
import 'package:tano/core/services/local_cipher.dart';

/// Builds `.tano` export containers.
///
/// A cleartext export is a plain ZIP (readable with any unzip tool). An
/// encrypted export is a custom container starting with [magic] and holding the
/// Argon2id salt followed by the AES-GCM payload.
/// Argon2id cost parameters for encrypted exports.
///
/// The production defaults are deliberately strong; [fast] keeps derivation
/// near-instant so tests do not blow their timeout in CI.
class Argon2Params {
  const Argon2Params({
    this.parallelism = 4,
    this.memory = 65536,
    this.iterations = 3,
  });

  final int parallelism;
  final int memory;
  final int iterations;

  static const Argon2Params fast = Argon2Params(
    parallelism: 1,
    memory: 256,
    iterations: 1,
  );
}

/// Raised when an export cannot be produced for a safety or format reason.
class ExportException implements Exception {
  const ExportException(this.message);

  final String message;

  @override
  String toString() => 'ExportException: $message';
}

class ExportService {
  ExportService({
    AttachmentsStore? attachments,
    Argon2Params argon2 = const Argon2Params(),
  }) : _attachments = attachments ?? AttachmentsStore(),
       _argon2 = argon2;

  final AttachmentsStore _attachments;
  final Argon2Params _argon2;

  static const String magic = 'TANO1';

  /// Version of the encrypted container, not of the manifest.
  static const int version = 1;

  /// Current manifest version: notes and their attachments, plus the folders
  /// that hold them. The importer still accepts the older 1 (notes) and 2
  /// (notes + tasks) manifests.
  static const int manifestVersion = 3;

  static const String manifestName = 'manifest.json';
  static const String attachmentsFolder = 'attachments/';
  static const int saltLength = 16;

  /// Builds the `.tano` bytes for [notes] and their [folders].
  ///
  /// [password] encrypts the whole archive. A cleartext export (no password)
  /// is refused as soon as a locked note or folder is selected, so protected
  /// content never reaches an unprotected file. Folders carry their lock flag
  /// and, when present, their cover attachment.
  Future<Uint8List> build({
    required List<Note> notes,
    List<Folder> folders = const <Folder>[],
    String? password,
  }) async {
    // Refuse what the importer would reject anyway, so the user is never left
    // with a backup that cannot be restored.
    if (notes.length > ArchiveValidation.maxNotes) {
      throw const ExportException(
        'Too many notes for a single .tano export.',
      );
    }
    if (password == null &&
        (notes.any((Note note) => note.isLocked) ||
            folders.any((Folder folder) => folder.isLocked))) {
      throw const ExportException(
        'Locked content cannot be written to a cleartext export.',
      );
    }
    final List<Map<String, dynamic>> encoded = notes
        .map((Note note) => note.toJson())
        .toList();

    final Archive archive = Archive();
    archive.addFile(
      ArchiveFile.string(
        manifestName,
        jsonEncode(<String, dynamic>{
          'version': manifestVersion,
          'notes': encoded,
          'folders': folders
              .map((Folder folder) => folder.toJson())
              .toList(),
        }),
      ),
    );

    final Set<String> names = <String>{};
    for (final Note note in notes) {
      names.addAll(note.attachments);
      final String? cover = note.coverImage;
      if (cover != null) names.add(cover);
    }
    for (final Folder folder in folders) {
      final String? cover = folder.coverImage;
      if (cover != null) names.add(cover);
    }
    for (final String name in names) {
      final Uint8List bytes = await _attachments.read(name);
      archive.addFile(
        ArchiveFile('$attachmentsFolder$name', bytes.length, bytes),
      );
    }

    final Uint8List zipped = ZipEncoder().encodeBytes(archive);
    if (password == null) return zipped;

    final List<int> salt = _randomBytes(saltLength);
    final Uint8List key = await deriveKey(password, salt, params: _argon2);
    final Uint8List encrypted = await LocalCipher.encrypt(zipped, key);

    final BytesBuilder out = BytesBuilder(copy: false);
    out.add(utf8.encode(magic));
    out.addByte(version);
    out.add(salt);
    out.add(encrypted);
    return out.toBytes();
  }

  /// Derives a 32-byte key from [password] and [salt] with Argon2id.
  static Future<Uint8List> deriveKey(
    String password,
    List<int> salt, {
    Argon2Params params = const Argon2Params(),
  }) async {
    final Argon2id algorithm = Argon2id(
      parallelism: params.parallelism,
      memory: params.memory,
      iterations: params.iterations,
      hashLength: 32,
    );
    final SecretKey secret = await algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    return Uint8List.fromList(await secret.extractBytes());
  }

  static List<int> _randomBytes(int length) {
    final Random random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
