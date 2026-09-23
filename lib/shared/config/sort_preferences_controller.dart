import 'package:flutter/foundation.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// The one owner of the sorting preference.
///
/// Home, Folder and Settings used to read and write the same three secure
/// preference keys independently. Keeping them in one controller means a change
/// made in Settings reaches an open page without that page re-reading the keys.
class SortPreferencesController extends ChangeNotifier {
  SortPreferencesController._();

  static final SortPreferencesController instance =
      SortPreferencesController._();

  static const String byKey = 'sortBy';
  static const String secondaryByKey = 'secondarySortBy';
  static const String ascendingKey = 'sortAscending';

  /// The criterion used before the user chooses one.
  static const String defaultBy = 'date';

  String _by = defaultBy;
  String _secondaryBy = defaultBy;
  bool _ascending = true;

  String get by => _by;
  String get secondaryBy => _secondaryBy;
  bool get ascending => _ascending;

  /// Reads the stored preference. Equal values do not notify.
  Future<void> load() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    final String by = prefs.getString(byKey) ?? defaultBy;
    final String secondary = prefs.getString(secondaryByKey) ?? defaultBy;
    final bool ascending = prefs.getBool(ascendingKey) ?? true;
    if (by == _by && secondary == _secondaryBy && ascending == _ascending) {
      return;
    }
    _by = by;
    _secondaryBy = secondary;
    _ascending = ascending;
    notifyListeners();
  }

  /// Stores the main criterion. Title and date have a natural tie-break, so
  /// they also become the secondary one, exactly as the settings screen expects.
  Future<void> setBy(String value) async {
    if (_by == value) return;
    _by = value;
    if (value == 'alpha' || value == 'date') {
      _secondaryBy = value;
    }
    notifyListeners();
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setString(byKey, _by);
    await prefs.setString(secondaryByKey, _secondaryBy);
  }

  Future<void> setAscending(bool value) async {
    if (_ascending == value) return;
    _ascending = value;
    notifyListeners();
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setBool(ascendingKey, value);
  }
}
