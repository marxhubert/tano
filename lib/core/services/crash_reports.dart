import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tano/shared/config/app_config.dart';
import 'package:tano/shared/config/secure_preferences.dart';

/// Anonymous crash reporting, gated by the "allow bug report" switch.
///
/// Nothing is initialised and nothing leaves the device until that switch is
/// on: the consent is read before `runApp`, and the SDK is closed as soon as
/// the switch goes back off. The configuration is deliberately bare — no
/// personal data, no stable identifier, no performance trace, no session
/// replay, no log and not a single breadcrumb.
///
/// See `docs/observabilite.md` and `docs/confidentialite.md`.
class CrashReports {
  CrashReports._();

  /// Preference holding the consent, shared with `SettingsViewModel`.
  static const String preferenceKey = 'bugReportEnabled';

  static bool _initialised = false;

  /// Whether the SDK has been initialised in this process.
  static bool get isInitialised => _initialised;

  /// Reads the stored consent. Called before `runApp`.
  static Future<bool> hasConsent() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    return prefs.getBool(preferenceKey) ?? false;
  }

  /// Applies a consent that changed while the app was running.
  static Future<void> apply(bool consent) async {
    if (consent) {
      await start();
    } else {
      await stop();
    }
  }

  /// Initialises the SDK. Pass [appRunner] on the cold start path, where the
  /// SDK has to wrap the whole application.
  static Future<void> start({VoidCallback? appRunner}) async {
    if (_initialised) return;
    _initialised = true;
    try {
      await SentryFlutter.init(_configure, appRunner: appRunner);
    } catch (error) {
      // Crash reporting must never keep the app from starting.
      _initialised = false;
      debugPrint('CrashReports: the SDK did not start ($error)');
      if (appRunner != null) appRunner();
    }
  }

  /// Stops the SDK and flushes what is already queued.
  static Future<void> stop() async {
    if (!_initialised) return;
    _initialised = false;
    try {
      await Sentry.close();
    } catch (error) {
      debugPrint('CrashReports: the SDK did not close cleanly ($error)');
    }
  }

  static Future<void> _configure(SentryFlutterOptions options) async {
    options.dsn = AppConfig.sentryDsn;

    final PackageInfo info = await PackageInfo.fromPlatform();
    // Same shape as the release the dart plugin uploads symbols for.
    options.release = '${AppConfig.packageName}@${info.version}';
    options.dist = info.buildNumber;

    // Nothing that points at the person or the device.
    options.sendDefaultPii = false;
    options.maxBreadcrumbs = 0;
    options.beforeBreadcrumb = (_, _) => null;
    options.beforeSend = scrub;

    // No tracing, profiling, replay, log nor session tracking.
    options.tracesSampleRate = null;
    options.enableLogs = false;
    options.replay.sessionSampleRate = 0.0;
    options.replay.onErrorSampleRate = 0.0;
    options.enableAutoNativeBreadcrumbs = false;
    options.attachScreenshot = false;
    options.enableWatchdogTerminationTracking = false;
    options.enableAppHangTracking = false;
    options.debug = false;
  }

  /// Defence in depth: whatever an integration adds later, an event never
  /// leaves with a user, a request (which carries the IP) or a breadcrumb.
  @visibleForTesting
  static SentryEvent? scrub(SentryEvent event, Hint hint) {
    event.user = null;
    event.request = null;
    event.breadcrumbs = null;
    return event;
  }
}
