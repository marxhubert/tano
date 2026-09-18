import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// The two ways the app can answer a gesture: a haptic tick and a sound.
///
/// Both are opt-in switches, and every call site goes through [tap] or
/// [impact] so a screen never talks to the platform channels directly.
class FeedbackController extends ChangeNotifier {
  FeedbackController._();

  static final FeedbackController instance = FeedbackController._();

  static const String hapticsKey = 'feedbackHaptics';
  static const String soundKey = 'feedbackSound';

  bool _haptics = true;
  bool _sound = false;

  bool get haptics => _haptics;
  bool get sound => _sound;

  Future<void> init() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    _haptics = prefs.getBool(hapticsKey) ?? true;
    _sound = prefs.getBool(soundKey) ?? false;
    notifyListeners();
  }

  Future<void> setHaptics(bool value) async {
    if (_haptics == value) return;
    _haptics = value;
    notifyListeners();
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setBool(hapticsKey, value);
  }

  Future<void> setSound(bool value) async {
    if (_sound == value) return;
    _sound = value;
    notifyListeners();
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setBool(soundKey, value);
  }

  /// A light tick for a choice: a bookmark, a selection.
  Future<void> tap() async {
    if (_sound) await SystemSound.play(SystemSoundType.click);
    if (_haptics) await HapticFeedback.selectionClick();
  }

  /// A firmer tick for something that changes the lists: a move, a delete.
  Future<void> impact() async {
    if (_sound) await SystemSound.play(SystemSoundType.click);
    if (_haptics) await HapticFeedback.lightImpact();
  }

  /// A clear tick for a state change the user asked for: a lock, an unlock.
  Future<void> success() async {
    if (_sound) await SystemSound.play(SystemSoundType.click);
    if (_haptics) await HapticFeedback.mediumImpact();
  }
}