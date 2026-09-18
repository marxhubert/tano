import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/feedback_controller.dart';
import 'package:tano/shared/config/onboarding_controller.dart';
import 'package:tano/shared/config/search_history_controller.dart';
import 'package:tano/shared/config/text_scale_controller.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/config/language_references_controller.dart';
import 'package:tano/core/services/crash_reports.dart';
import 'package:tano/shared/config/service_locator.dart';

class SettingsViewModel extends ChangeNotifier {
  /// [applyConsent] hands the new consent to the crash reporting SDK. It is
  /// injected so that tests never reach the network nor the SDK.
  SettingsViewModel({Future<void> Function(bool consent)? applyConsent})
    : _applyConsent = applyConsent ?? CrashReports.apply;

  final Future<void> Function(bool consent) _applyConsent;

  PackageInfo? _packageInfo;
  bool _bugReportEnabled = false;
  bool _isResetting = false;

  PackageInfo? get packageInfo => _packageInfo;
  bool get bugReportEnabled => _bugReportEnabled;
  bool get isResetting => _isResetting;

  Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _bugReportEnabled = await CrashReports.hasConsent();
    notifyListeners();
  }

  /// The switch is the one and only consent gate: it is persisted here and
  /// applied to the SDK straight away.
  Future<void> setBugReportEnabled(bool value) async {
    if (_bugReportEnabled == value) return;
    _bugReportEnabled = value;
    notifyListeners();

    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setBool(CrashReports.preferenceKey, value);
    await _applyConsent(value);
  }

  /// Forgets the consent and stops the SDK when the preferences are wiped.
  Future<void> _revokeConsent() async {
    if (!_bugReportEnabled) return;
    _bugReportEnabled = false;
    notifyListeners();
    await _applyConsent(false);
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
        final NotesRepository repository = getIt<NotesRepository>();
        await repository.deleteAllNotes();
        // A hard reset takes everything: the folders and the files on disk go
        // with the notes, or the app would leave orphans behind.
        if (repository is FoldersRepository) {
          await (repository as FoldersRepository).deleteAllFolders();
        }
        await getIt<AttachmentsStore>().deleteAll();
      }

      if (deletePrefs) {
        final SecurePreferences prefs = await SecurePreferences.getInstance();
        await prefs.clear();
        // The consent lived in those preferences: it goes with them.
        await _revokeConsent();

        // Re-init core controllers to reflect default state
        await Future.wait([
          LocaleController.instance.init(),
          ThemeController.instance.init(),
          LanguageReferencesController.instance.init(),
          OnboardingController.instance.init(),
          TextScaleController.instance.init(),
          FeedbackController.instance.init(),
          SearchHistoryController.instance.init(),
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

  /// Wipes the data and the preferences without asking, so a fresh first launch
  /// can be replayed — the introduction included — while developing.
  Future<void> developerReset() =>
      performHardReset(deleteData: true, deletePrefs: true);
}
