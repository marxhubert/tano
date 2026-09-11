import 'package:flutter/material.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// Manages the application theme mode (light, dark, or system).
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const String _prefKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  /// Loads the saved theme mode from preferences.
  Future<void> init() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    final String? saved = prefs.getString(_prefKey);
    if (saved == 'light') {
      _themeMode = ThemeMode.light;
    } else if (saved == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  /// Sets and saves the theme mode.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}
