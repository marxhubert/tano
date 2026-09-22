import 'package:flutter/foundation.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// Which side the FAB sits on. A global setting, not a per-page one: Home and
/// every folder read this notifier, so a switch made on one page is already
/// applied on the other, and stays until it is switched back.
class FabSideController extends ChangeNotifier {
  FabSideController._();

  static final FabSideController instance = FabSideController._();

  static const String _key = 'fabOnLeft';

  bool _onLeft = false;
  bool get onLeft => _onLeft;

  /// Reads the stored side. Idempotent, so every page may call it.
  Future<void> load() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    if (!prefs.containsKey(_key)) {
      await prefs.setBool(_key, false);
    }
    _apply(prefs.getBool(_key) ?? false, notify: false);
  }

  Future<void> setOnLeft(bool value) async {
    if (_apply(value)) {
      final SecurePreferences prefs = await SecurePreferences.getInstance();
      await prefs.setBool(_key, value);
    }
  }

  /// Returns whether anything changed.
  bool _apply(bool value, {bool notify = true}) {
    if (_onLeft == value) return false;
    _onLeft = value;
    if (notify) notifyListeners();
    return true;
  }
}
