import 'package:tano/core/services/auth_service.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';

/// Whether a lock change may proceed.
enum LockGateResult {
  /// The change is authorised: the caller may flip the lock.
  granted,

  /// The device has no system credential, so an item must not be locked.
  unavailable,

  /// The system prompt was cancelled or failed.
  refused,
}

/// The one decision behind every lock toggle.
///
/// Locking needs a usable device credential — otherwise the item could never be
/// opened again — while unlocking needs a successful system prompt. The editor
/// and the folder page keep their own feedback; the security decision itself
/// lives here so the two cannot drift apart.
Future<LockGateResult> requestLockChange({required bool isLocked}) async {
  if (!isLocked) {
    if (!await getIt<AuthService>().isAvailable()) {
      return LockGateResult.unavailable;
    }
    return LockGateResult.granted;
  }
  final bool authenticated = await getIt<AuthService>().authenticate(
    reason: AppText.tr('auth_reason'),
  );
  return authenticated ? LockGateResult.granted : LockGateResult.refused;
}
