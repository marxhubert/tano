import 'package:flutter/foundation.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// The one source of truth for the document view — the grid/list control.
///
/// Home and a folder both read it instead of keeping their own copy, so a
/// switch made inside a folder is already applied when Home comes back: both
/// pages listen to this notifier. The choice is written through to the
/// preferences, so it also survives a restart.
class ViewLayoutController extends ChangeNotifier {
  ViewLayoutController._();

  static final ViewLayoutController instance = ViewLayoutController._();

  static const String _key = 'viewLayout';
  static const String _defaultLayout = 'gridlist';

  String _layout = _defaultLayout;
  String get layout => _layout;

  /// Reads the stored layout. Idempotent, so every page may call it.
  Future<void> load() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    if (!prefs.containsKey(_key)) {
      await prefs.setString(_key, _defaultLayout);
    }
    _apply(prefs.getString(_key) ?? _defaultLayout, notify: false);
  }

  Future<void> setLayout(String layout) async {
    if (_apply(layout)) {
      final SecurePreferences prefs = await SecurePreferences.getInstance();
      await prefs.setString(_key, layout);
    }
  }

  /// Returns whether anything changed.
  bool _apply(String layout, {bool notify = true}) {
    if (_layout == layout) return false;
    _layout = layout;
    if (notify) notifyListeners();
    return true;
  }
}
