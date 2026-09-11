import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-GCM helper used to encrypt files on disk.
///
/// Layout of an encrypted payload: `[version:1][nonce:12][ciphertext][mac:16]`.
class LocalCipher {
  LocalCipher._();

  static const int _version = 1;
  static const int _nonceLength = 12;
  static const int _macLength = 16;

  static final AesGcm _algorithm = AesGcm.with256bits();

  /// Encrypts [plaintext] with [key] (32 bytes).
  static Future<Uint8List> encrypt(Uint8List plaintext, Uint8List key) async {
    final List<int> nonce = _algorithm.newNonce();
    final SecretBox box = await _algorithm.encrypt(
      plaintext,
      secretKey: SecretKey(key),
      nonce: nonce,
    );
    final BytesBuilder out = BytesBuilder(copy: false);
    out.addByte(_version);
    out.add(nonce);
    out.add(box.cipherText);
    out.add(box.mac.bytes);
    return out.toBytes();
  }

  /// Decrypts a payload produced by [encrypt].
  static Future<Uint8List> decrypt(Uint8List payload, Uint8List key) async {
    if (payload.length < 1 + _nonceLength + _macLength) {
      throw const FormatException('Encrypted payload is too short');
    }
    if (payload[0] != _version) {
      throw const FormatException('Unsupported encrypted payload version');
    }
    final List<int> nonce = payload.sublist(1, 1 + _nonceLength);
    final List<int> cipherText =
        payload.sublist(1 + _nonceLength, payload.length - _macLength);
    final List<int> mac = payload.sublist(payload.length - _macLength);
    final List<int> clear = await _algorithm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(key),
    );
    return Uint8List.fromList(clear);
  }
}
