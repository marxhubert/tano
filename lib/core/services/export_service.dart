import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/services/local_cipher.dart';

/// Builds `.tano` export containers.
///
/// A cleartext export is a plain ZIP (readable with any unzip tool). An
/// encrypted export is a custom container starting with [magic] and holding the
/// Argon2id salt followed by the AES-GCM payload.
class ExportService {
  ExportService({AttachmentsStore? attachments})
      : _attachments = attachments ?? AttachmentsStore();

  final AttachmentsStore _attachments;

  static const String magic = 'TANO1';
  static const int version = 1;
  static const String manifestName = 'manifest.json';
  static const String attachmentsFolder = 'attachments/';
  static const int saltLength = 16;

  /// Builds the `.tano` bytes for [notes].
  ///
  /// [unlockLockedNotes] clears the locked flag in the manifest (used by a
  /// cleartext export). [password] encrypts the whole archive.
  Future<Uint8List> build({
    required List<Note> notes,
    String? password,
    bool unlockLockedNotes = false,
  }) async {
    final List<Map<String, dynamic>> encoded = notes
        .map((Note note) {
          final Map<String, dynamic> json = note.toJson();
          if (unlockLockedNotes) json['isLocked'] = 0;
          return json;
        })
        .toList();

    final Archive archive = Archive();
    archive.addFile(
      ArchiveFile.string(
        manifestName,
        jsonEncode(<String, dynamic>{'version': version, 'notes': encoded}),
      ),
    );

    final Set<String> names = <String>{};
    for (final Note note in notes) {
      names.addAll(note.attachments);
      final String? cover = note.coverImage;
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
    final Uint8List key = await deriveKey(password, salt);
    final Uint8List encrypted = await LocalCipher.encrypt(zipped, key);

    final BytesBuilder out = BytesBuilder(copy: false);
    out.add(utf8.encode(magic));
    out.addByte(version);
    out.add(salt);
    out.add(encrypted);
    return out.toBytes();
  }

  /// Derives a 32-byte key from [password] and [salt] with Argon2id.
  static Future<Uint8List> deriveKey(String password, List<int> salt) async {
    final Argon2id algorithm = Argon2id(
      parallelism: 4,
      memory: 65536,
      iterations: 3,
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
