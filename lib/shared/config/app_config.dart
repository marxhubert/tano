/// Application configuration and data.
///
/// Centralizes non-linguistic data (application name, author,
/// e-mail address...). Interface strings are handled by [AppText]
/// in `l10n.dart`.
class AppConfig {
  AppConfig._();

  /// Application name.
  static const String appName = 'Tano';

  /// Application name suffix (Tano + Note).
  static const String appNameSuffix = 'Note';

  /// Package name, as declared in `pubspec.yaml`. Part of the Sentry release
  /// string, so it has to stay in sync with that file.
  static const String packageName = 'tano';

  /// Author name.
  static const String authorName = 'Marx Hubert';

  /// Author e-mail address.
  static const String authorEmail = 'shikamarx@gmail.com';

  /// Sentry data source name.
  ///
  /// A DSN is a write-only public key, not a secret: it ships inside the app.
  /// Override it at build time with
  /// `--dart-define=SENTRY_DSN=https://...`, for instance to point a build at
  /// another Sentry project.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://97c35557c83918e734d7117ec75dee10@o4512097538211840.ingest.de.sentry.io/4512097551122512',
  );
}
