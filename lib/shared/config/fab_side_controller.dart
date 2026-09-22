import 'package:flutter/foundation.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// The FAB side shared by Home, folders and editors, persisted across restarts.
class FabSideController extends ChangeNotifier {
  FabSideController._() : _preferences = SecurePreferences.getInstance;

  @visibleForTesting
  FabSideController.forTesting({
    required Future<SecurePreferences> Function() preferences,
  }) : _preferences = preferences;

  static final FabSideController instance = FabSideController._();
  static const String _key = 'fabOnLeft';

  final Future<SecurePreferences> Function() _preferences;
  Future<void>? _loading;
  Future<void> _writes = Future<void>.value();
  int _choiceRevision = 0;
  bool _onLeft = false;
  bool get onLeft => _onLeft;

  /// Coalesces concurrent page loads. A missing value means right; reading it
  /// never writes a default that could race with the user's first choice.
  Future<void> load() => _loading ??= _read(_choiceRevision).whenComplete(() {
    _loading = null;
  });

  Future<void> _read(int revision) async {
    // A page opening during a choice must not read its older persisted value.
    await _writes;
    final prefs = await _preferences();
    if (revision == _choiceRevision) _apply(prefs.getBool(_key) ?? false);
  }

  Future<void> setOnLeft(bool value) {
    // Even an explicit choice of the current default invalidates an older read.
    _choiceRevision++;
    _apply(value);
    final write = _writes.then((_) async {
      final prefs = await _preferences();
      await prefs.setBool(_key, value);
    });
    // Keep later choices writable after a failure. The caller still receives
    // the original failing future; no storage error is hidden from it.
    _writes = write.catchError((Object _) {});
    return write;
  }

  /// Called after preferences are cleared. Ordering this write after pending
  /// choices prevents an old toggle from restoring the pre-reset side later.
  Future<void> reset() => setOnLeft(false);

  void _apply(bool value) {
    if (_onLeft == value) return;
    _onLeft = value;
    notifyListeners();
  }
}
