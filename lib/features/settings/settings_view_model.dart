import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/config/language_references_controller.dart';
import 'package:tano/shared/config/service_locator.dart';

class SettingsViewModel extends ChangeNotifier {
  PackageInfo? _packageInfo;
  bool _bugReportEnabled = false;
  bool _isResetting = false;

  PackageInfo? get packageInfo => _packageInfo;
  bool get bugReportEnabled => _bugReportEnabled;
  bool get isResetting => _isResetting;

  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    notifyListeners();
  }

  void setBugReportEnabled(bool value) {
    _bugReportEnabled = value;
    notifyListeners();
  }

  Future<void> setSorting(String sortBy) async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setString('sortBy', sortBy);
    if (sortBy == 'alpha' || sortBy == 'date') {
      await prefs.setString('secondarySortBy', sortBy);
    }
  }

  Future<String> getSorting() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    return prefs.getString('sortBy') ?? 'date';
  }

  Future<void> setSortAscending(bool ascending) async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setBool('sortAscending', ascending);
  }

  Future<bool> getSortAscending() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    return prefs.getBool('sortAscending') ?? true;
  }

  Future<void> performHardReset({
    required bool deleteData,
    required bool deletePrefs,
  }) async {
    _isResetting = true;
    notifyListeners();
    final startTime = DateTime.now();
    try {
      if (deleteData) {
        await getIt<NotesRepository>().deleteAllNotes();
        // Ensure we don't auto-seed fixtures on next load
        final SecurePreferences prefs = await SecurePreferences.getInstance();
        await prefs.setBool('database_initial_seed_done', true);
      }

      if (deletePrefs) {
        final SecurePreferences prefs = await SecurePreferences.getInstance();
        await prefs.clear();

        // Re-init core controllers to reflect default state
        await Future.wait([
          LocaleController.instance.init(),
          ThemeController.instance.init(),
          LanguageReferencesController.instance.init(),
        ]);
      }

      // Minimum delay for visual feedback
      final elapsed = DateTime.now().difference(startTime);
      const minDuration = Duration(milliseconds: 1200);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    } finally {
      _isResetting = false;
      notifyListeners();
    }
  }

  Future<void> resetData() async {
    await performHardReset(deleteData: true, deletePrefs: true);
  }

  Future<void> developerReset() async {
    _isResetting = true;
    notifyListeners();
    final startTime = DateTime.now();
    try {
      // 1. Delete all notes from DB
      await getIt<NotesRepository>().deleteAllNotes();

      // 2. Clear all preferences (theme, language, sorting, etc.)
      final SecurePreferences prefs = await SecurePreferences.getInstance();
      await prefs.clear();

      // 3. Re-seed fixtures
      await getIt<NotesRepository>().seedFixtures();

      // 4. Re-init core controllers to reflect default state
      await Future.wait([
        LocaleController.instance.init(),
        ThemeController.instance.init(),
        LanguageReferencesController.instance.init(),
      ]);

      // 5. Ensure the spinner lasts at least 1.2 seconds
      final elapsed = DateTime.now().difference(startTime);
      const minDuration = Duration(milliseconds: 1200);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    } finally {
      _isResetting = false;
      notifyListeners();
    }
  }
}
