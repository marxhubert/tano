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

    /// Author name.
    static const String authorName = 'Marx Hubert';

    /// Author e-mail address.
    static const String authorEmail = 'shikamarx@gmail.com';
}
