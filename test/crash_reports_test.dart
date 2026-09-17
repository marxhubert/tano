import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/services/crash_reports.dart';
import 'package:tano/features/settings/settings_view_model.dart';
import 'package:tano/shared/config/secure_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.marxhubert.tanonote',
      version: '0.8.4',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  test('no consent is stored by default', () async {
    expect(await CrashReports.hasConsent(), isFalse);
    expect(CrashReports.isInitialised, isFalse);
  });

  test(
    'the switch persists the consent in the encrypted preferences',
    () async {
      final SettingsViewModel viewModel = SettingsViewModel(
        applyConsent: (bool _) async {},
      );
      await viewModel.init();
      expect(viewModel.bugReportEnabled, isFalse);

      await viewModel.setBugReportEnabled(true);
      expect(viewModel.bugReportEnabled, isTrue);
      expect(await CrashReports.hasConsent(), isTrue);

      // A fresh view model reads it back, so the choice survives a restart.
      final SettingsViewModel reloaded = SettingsViewModel(
        applyConsent: (bool _) async {},
      );
      await reloaded.init();
      expect(reloaded.bugReportEnabled, isTrue);
    },
  );

  test('the switch hands the consent to the SDK', () async {
    final List<bool> applied = <bool>[];
    final SettingsViewModel viewModel = SettingsViewModel(
      applyConsent: (bool consent) async => applied.add(consent),
    );
    await viewModel.init();

    await viewModel.setBugReportEnabled(true);
    await viewModel.setBugReportEnabled(false);
    expect(applied, <bool>[true, false]);

    // Setting the same value twice does not touch the SDK again.
    await viewModel.setBugReportEnabled(false);
    expect(applied, <bool>[true, false]);
  });

  test('an event never carries a user, a request nor a breadcrumb', () {
    final SentryEvent event = SentryEvent(
      user: SentryUser(id: 'installation-id', ipAddress: '1.2.3.4'),
      request: SentryRequest(
        url: 'https://example.com',
        headers: <String, String>{'User-Agent': 'test'},
      ),
      breadcrumbs: <Breadcrumb>[Breadcrumb(message: 'opened a note')],
      serverName: 'phone',
    );

    final SentryEvent? scrubbed = CrashReports.scrub(event, Hint());

    expect(scrubbed, isNotNull);
    expect(scrubbed!.user, isNull);
    expect(scrubbed.request, isNull);
    expect(scrubbed.breadcrumbs, isNull);
    expect(scrubbed.message, event.message);
  });

  test('the consent key is the one the settings screen writes', () async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setBool(CrashReports.preferenceKey, true);
    expect(await CrashReports.hasConsent(), isTrue);

    await prefs.setBool(CrashReports.preferenceKey, false);
    expect(await CrashReports.hasConsent(), isFalse);
  });
}
