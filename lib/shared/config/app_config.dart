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

  // --- Identity -------------------------------------------------------------
  //
  // This repository is public, so nothing personal is written here: whoever
  // builds the app supplies its own identity, and a build that supplies none
  // shows no author and no support link at all.
  //
  //   flutter build apk --dart-define=AUTHOR_NAME=… --dart-define=AUTHOR_EMAIL=…
  //
  // Better: keep them in a local file the repository ignores and let the tool
  // read it, so one file carries the whole identity. `identity.json.dist` is the
  // versioned template; copy it and fill it in.
  //
  //   cp identity.json.dist identity.json
  //   flutter build apk --dart-define-from-file=identity.json

  /// Author name. Empty when the build sets none.
  static const String authorName = String.fromEnvironment('AUTHOR_NAME');

  /// Author e-mail address. Empty when the build sets none.
  static const String authorEmail = String.fromEnvironment('AUTHOR_EMAIL');

  /// The author's GitHub account. The sponsorship page is derived from it.
  static const String githubAccount = String.fromEnvironment('GITHUB_ACCOUNT');

  /// GitHub Sponsors page, or an empty string when no account is configured.
  static String get sponsorUrl =>
      githubAccount.isEmpty ? '' : 'https://github.com/sponsors/$githubAccount';

  /// "Buy Me a Coffee" page. Empty when the build sets none.
  static const String coffeeUrl = String.fromEnvironment('COFFEE_URL');

  /// PayPal page. Empty when the build sets none.
  static const String paypalUrl = String.fromEnvironment('PAYPAL_URL');

  /// The year of the moment. Every notice that carries one reads it here, so the
  /// app never shows a year it has outgrown.
  static int get year => DateTime.now().year;

  // --- The addresses the app opens, minus the personal ones -----------------
  /// The Malagasy word look-up used by the language references page.
  static const String malagasyWordUrl = 'https://malagasyword.org/bins/teny2/';

  // --- The names of the support services ------------------------------------
  /// Brand names: the same in every language, so they stay out of [AppText].
  static const String coffeeName = 'Buy Me a Coffee';
  static const String sponsorName = 'GitHub Sponsors';
  static const String paypalName = 'PayPal';

  /// Sentry data source name.
  ///
  /// A DSN is a write-only public key, not a secret: it ships inside the app.
  /// Override it at build time with
  /// `--dart-define=SENTRY_DSN=https://...`, for instance to point a build at
  /// another Sentry project.
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
}
