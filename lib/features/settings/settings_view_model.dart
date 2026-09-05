import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortBy', sortBy);
    if (sortBy == 'alpha' || sortBy == 'date') {
      await prefs.setString('secondarySortBy', sortBy);
    }
  }

  Future<String> getSorting() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('sortBy') ?? 'date';
  }

  Future<void> setSortAscending(bool ascending) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sortAscending', ascending);
  }

  Future<bool> getSortAscending() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('sortAscending') ?? true;
  }

  Future<void> resetData() async {
    _isResetting = true;
    notifyListeners();
    final startTime = DateTime.now();
    try {
      // 1. Delete all notes from DB
      await getIt<NotesRepository>().deleteAllNotes();

      // 2. Clear all preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Re-init core controllers to reflect default state
      await Future.wait([
        LocaleController.instance.init(),
        ThemeController.instance.init(),
        LanguageReferencesController.instance.init(),
      ]);

      // 4. Minimum delay for visual feedback
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

  Future<void> developerReset() async {
    _isResetting = true;
    notifyListeners();
    final startTime = DateTime.now();
    try {
      // 1. Delete all notes from DB
      await getIt<NotesRepository>().deleteAllNotes();

      // 2. Clear all preferences (theme, language, sorting, etc.)
      final SharedPreferences prefs = await SharedPreferences.getInstance();
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

  Future<void> checkForUpdates() async {
    final Uri url = Uri.parse('https://github.com/shikamarx/tano'); // Placeholder
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> sendFeedback() async {
    final Uri url = Uri.parse('mailto:feedback@tano.app'); // Placeholder
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }
}
