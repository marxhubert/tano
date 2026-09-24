import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Raised when a freshly generated installation key could not be persisted.
///
/// Continuing with an unpersisted key would silently re-encrypt data with a
/// key that vanishes on the next launch.
class InstallationKeyException implements Exception {
  const InstallationKeyException(this.message);

  final String message;

  @override
  String toString() => 'InstallationKeyException: $message';
}

/// Owns the per-installation encryption keys.
///
/// The keys are generated on first launch and stored in the OS secure storage
/// (iOS Keychain / Android Keystore), so they are never shown to the user and
/// never leave the device. A copy of the database is therefore useless on
/// another device: that device has a different key. Portability goes through
/// export/import only.
class InstallationKey {
  InstallationKey({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              // Never migrated to another device, never synced to iCloud.
              accessibility: KeychainAccessibility.first_unlock_this_device,
            ),
          );

  /// App-wide instance.
  static final InstallationKey instance = InstallationKey();

  static const String _databaseKeyName = 'tano.key.database.v1';
  static const String _filesKeyName = 'tano.key.files.v1';
  static const String _preferencesKeyName = 'tano.key.preferences.v1';

  final FlutterSecureStorage _storage;
  final Map<String, String> _cache = <String, String>{};

  /// Passphrase used by SQLCipher to encrypt the notes database.
  Future<String> databasePassphrase() => _value(_databaseKeyName);

  /// 32-byte key used to encrypt attachments and cover images.
  Future<Uint8List> filesKey() async =>
      base64Decode(await _value(_filesKeyName));

  /// 32-byte key used to encrypt preference values.
  Future<Uint8List> preferencesKey() async =>
      base64Decode(await _value(_preferencesKeyName));

  final Map<String, Future<String>> _pending = {};

  Future<String> _value(String name) => _pending.putIfAbsent(
    name,
    () => _readOrCreate(name).whenComplete(() {
      _pending.remove(name);
    }),
  );

  Future<String> _readOrCreate(String name) async {
    final String? cached = _cache[name];
    if (cached != null) return cached;

    final String? stored = await _storage.read(key: name);
    if (stored != null) {
      _cache[name] = stored;
      return stored;
    }

    // First launch: generate the key, then read it back. A write that did not
    // land (unsupported platform, locked keystore) must fail loudly here:
    // caching the key anyway would let this session encrypt data with a key
    // the next launch cannot reproduce.
    final String created = _randomBase64Key();
    await _storage.write(key: name, value: created);
    final String? persisted = await _storage.read(key: name);
    if (persisted != created) {
      throw const InstallationKeyException(
        'Secure storage did not persist the installation key.',
      );
    }
    _cache[name] = created;
    return created;
  }

  /// 32 cryptographically secure random bytes, base64 encoded.
  static String _randomBase64Key() {
    final Random random = Random.secure();
    final Uint8List bytes = Uint8List(32);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }
}
