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

  test('the test error is not sent while the SDK is off', () async {
    // The Labs button must say so rather than fail silently.
    expect(CrashReports.isInitialised, isFalse);
    expect(await CrashReports.sendTestError(), isFalse);
  });

  test('the test error keeps a readable type through the scrubber', () {
    final SentryEvent event = SentryEvent(
      exceptions: <SentryException>[
        SentryException(type: 'TanoLabsTestException', value: 'private detail'),
      ],
    );
    final SentryEvent? scrubbed = CrashReports.scrub(event, Hint());
    expect(scrubbed!.exceptions!.single.type, 'TanoLabsTestException');
    expect(scrubbed.exceptions!.single.value, isNull);
  });

  test('the consent key is the one the settings screen writes', () async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    await prefs.setBool(CrashReports.preferenceKey, true);
    expect(await CrashReports.hasConsent(), isTrue);

    await prefs.setBool(CrashReports.preferenceKey, false);
    expect(await CrashReports.hasConsent(), isFalse);
  });
  test(
    'free-form messages, exception values, paths and contexts are stripped',
    () {
      final event = SentryEvent(
        message: SentryMessage('private note'),
        serverName: 'personal phone',
        tags: {'note': 'private'},
        exceptions: [
          SentryException(
            type: 'FormatException',
            value: 'private note',
            stackTrace: SentryStackTrace(
              frames: [
                SentryStackFrame(
                  absPath: '/Users/private/file',
                  function: 'parse',
                  vars: {'note': 'private'},
                ),
              ],
            ),
          ),
        ],
      );
      final result = CrashReports.scrub(event, Hint())!;
      expect(result.message, isNull);
      expect(result.serverName, isNull);
      expect(result.tags?.keys ?? [], isNot(contains('note')));
      expect(result.exceptions!.single.value, isNull);
      expect(
        result.exceptions!.single.stackTrace!.frames.single.function,
        'parse',
      );
      expect(result.toJson().toString(), isNot(contains('private')));
    },
  );
  test(
    'keeps diagnostic device and OS fields but strips personal identifiers',
    () {
      final event = SentryEvent(
        contexts: Contexts(
          device: SentryDevice(
            model: 'Pixel 8',
            manufacturer: 'Google',
            name: 'Private phone',
            deviceUniqueIdentifier: 'secret-id',
          ),
          operatingSystem: SentryOperatingSystem(
            name: 'Android',
            version: '16',
            rawDescription: 'private dump',
          ),
        ),
      );
      final result = CrashReports.scrub(event, Hint(), countryCode: 'MU')!;
      expect(result.contexts.device!.model, 'Pixel 8');
      expect(result.contexts.device!.name, isNull);
      expect(result.contexts.device!.deviceUniqueIdentifier, isNull);
      expect(result.contexts.operatingSystem!.version, '16');
      expect(result.contexts.operatingSystem!.rawDescription, isNull);
      expect(result.tags, {'device_region': 'MU'});
      expect(result.user, isNull);
    },
  );
}
