import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/services/installation_key.dart';
import 'package:tano/core/services/local_cipher.dart';

/// Encrypted replacement for [SharedPreferences].
///
/// Values are encrypted with the installation preferences key before reaching
/// [SharedPreferences], so the on-disk file only contains ciphertext. Keys stay
/// readable: they are not sensitive.
///
/// Getters are synchronous after [getInstance], setters are asynchronous,
/// matching the [SharedPreferences] usage in the app.
class SecurePreferences {
  SecurePreferences._(this._prefs, this._key, this._cache);

  static const String _prefix = 'enc:v1:';

  final SharedPreferences _prefs;
  final Uint8List _key;
  final Map<String, Object?> _cache;

  static Future<SecurePreferences> getInstance() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Uint8List key = await _resolveKey();

    final Map<String, Object?> cache = <String, Object?>{};
    final List<String> legacy = <String>[];
    for (final String name in prefs.getKeys()) {
      final Object? raw = prefs.get(name);
      if (raw is String && raw.startsWith(_prefix)) {
        try {
          cache[name] = _decode(
            await LocalCipher.decrypt(
              base64Decode(raw.substring(_prefix.length)),
              key,
            ),
          );
        } catch (_) {
          // Do not silently replace unreadable preferences (including consent)
          // with defaults or overwrite them on a later save.
          throw const FormatException('Encrypted preferences are unavailable');
        }
      } else if (raw != null) {
        // Value written before encryption: keep it, re-encrypt it below.
        cache[name] = raw;
        legacy.add(name);
      }
    }

    final SecurePreferences instance = SecurePreferences._(prefs, key, cache);
    for (final String name in legacy) {
      await instance._write(name, cache[name]);
    }
    return instance;
  }

  // A missing keystore is an error, never permission to use a public key.
  static Future<Uint8List> _resolveKey() =>
      InstallationKey.instance.preferencesKey();

  bool containsKey(String key) => _cache.containsKey(key);

  bool? getBool(String key) {
    final Object? value = _cache[key];
    return value is bool ? value : null;
  }

  String? getString(String key) {
    final Object? value = _cache[key];
    return value is String ? value : null;
  }

  Future<void> setBool(String key, bool value) => _write(key, value);

  Future<void> setString(String key, String value) => _write(key, value);

  Future<void> remove(String key) async {
    if (!await _prefs.remove(key)) {
      throw StateError('Preference removal failed');
    }
    _cache.remove(key);
  }

  Future<void> clear() async {
    if (!await _prefs.clear()) throw StateError('Preference reset failed');
    _cache.clear();
  }

  Future<void> _write(String key, Object? value) async {
    final Uint8List encrypted = await LocalCipher.encrypt(
      Uint8List.fromList(
        utf8.encode(jsonEncode(<String, Object?>{'v': value})),
      ),
      _key,
    );
    if (!await _prefs.setString(key, '$_prefix${base64Encode(encrypted)}')) {
      throw StateError('Preference write failed');
    }
    _cache[key] = value;
  }

  static Object? _decode(Uint8List bytes) =>
      (jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>)['v'];
}
