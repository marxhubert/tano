import 'package:flutter/foundation.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// Whether the introduction has already been seen.
///
/// The flag lives with the other interface preferences, so the "delete
/// preferences" reset brings the introduction back — which is what a reset is
/// for.
class OnboardingController {
  OnboardingController._();

  static final OnboardingController instance = OnboardingController._();

  static const String _prefKey = 'onboarding_seen';

  /// True until [init] says otherwise.
  ///
  /// The app calls [init] before its first frame. A widget test that pumps the
  /// app directly never gets there, so it stays on the screen it is testing
  /// instead of opening the introduction; a test that does exercise the
  /// introduction sets this state explicitly.
  bool _seen = true;

  bool get seen => _seen;

  Future<void> init() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    _seen = prefs.getBool(_prefKey) ?? false;
  }

  Future<void> markSeen() async {
    _seen = true;
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// Test hook: forces the state without touching the preferences.
  @visibleForTesting
  void debugSetSeen(bool value) {
    _seen = value;
  }
}
