import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:tano/shared/config/l10n.dart';

/// Gates locked notes behind the device's own authentication.
///
/// The app never stores a password of its own: locked notes are protected by
/// the system credential (biometrics, PIN, passcode or pattern) exposed through
/// [LocalAuthentication].
class AuthService {
  AuthService();

  static AuthService _instance = AuthService();

  /// The app-wide instance.
  static AuthService get instance => _instance;

  /// Replaces the app-wide instance, so tests can fake the system prompt.
  @visibleForTesting
  static set instance(AuthService value) => _instance = value;

  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device has a usable system credential (an enrolled biometric
  /// or a fallback PIN / passcode / pattern), i.e. whether a note can be
  /// protected at all.
  ///
  /// [LocalAuthentication.isDeviceSupported] is exactly that predicate on both
  /// Android (device secure or biometrics enrolled) and iOS
  /// (`deviceOwnerAuthentication`). An unreachable device reports [false]:
  /// better to refuse locking than to lock a note nobody can ever reopen.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (error) {
      debugPrint('AuthService: device capability check failed ($error)');
      return false;
    }
  }

  /// Prompts for the system credential and reports whether it succeeded.
  ///
  /// Fails closed: without any system credential there is nothing to
  /// authenticate against, so a locked note stays locked.
  Future<bool> authenticate({String? reason}) async {
    if (!await isAvailable()) return false;

    try {
      return await _auth.authenticate(
        localizedReason: reason ?? AppText.tr('auth_reason'),
        // Accept the device PIN / passcode / pattern, not only biometrics.
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (error) {
      // Covers rejection, cancelation and lockout.
      debugPrint('AuthService: authentication failed (${error.code.name})');
      return false;
    } catch (error) {
      debugPrint('AuthService: authentication failed ($error)');
      return false;
    }
  }
}
