import 'package:flutter/material.dart';

/// Tap group shared by the FAB and the theme toggle, so tapping the toggle does
/// not dismiss an open FAB menu.
const Object fabTapGroup = Object();

// --- Identité Visuelle (30%) ---
const Color tanoTeal = Color(0xFF0F766E);
const Color tanoAmber = Color(0xFFB06A0C);
const Color tanoAmberDark = Color(0xFFDFA14A);

// --- Fonds (60%) ---
const Color lightBackground = Color(0xFFF2EBDC);
const Color darkBackground = Color(0xFF18140E);

/// The content column, as on the site: whatever the window, the page keeps the
/// same readable width and the rest stays paper.
const double appContentMaxWidth = 1080.0;

// --- Palette des États (Tickets) ---
/// The app has a single red. `error` carries both meanings: a real error, and a
/// destructive action ("delete", "empty the bin", "delete the selection"). The
/// light variant is the one read on the dark background and on the teal bars.
class TanoStates {
  static const neutral = (light: Color(0xFF90A4AE), dark: Color(0xFF78909C));
  static const action = (light: Color(0xFF009688), dark: Color(0xFF4DB6AC));
  static const success = (light: Color(0xFF4CAF50), dark: Color(0xFF81C784));
  static const warning = (light: Color(0xFFFF9800), dark: Color(0xFFFFB74D));
  static const error = (light: Color(0xFFE53935), dark: Color(0xFFE57373));
  static const purple = (light: Color(0xFF9C27B0), dark: Color(0xFFBA68C8));
  static const yellow = (light: Color(0xFFFBC02D), dark: Color(0xFFFDD835));
  static const reference = (light: Color(0xFF2196F3), dark: Color(0xFF64B5F6));
  static const subtle = (light: Color(0xFFB0BEC5), dark: Color(0xFF90A4AE));
  static const archive = (light: Color(0xFF78909C), dark: Color(0xFF546E7A));

  static Color get(BuildContext context, Color Function(bool isDark) picker) {
    return picker(Theme.of(context).brightness == Brightness.dark);
  }
}

// --- Palette Pastel (Notes) ---
class TanoPastels {
  static const menthe = (light: Color(0xFFE9F0E4), dark: Color(0xFF202A22));
  static const citron = (light: Color(0xFFF7EFD2), dark: Color(0xFF302A19));
  static const peche = (light: Color(0xFFF5E4D4), dark: Color(0xFF32241C));
  static const lavande = (light: Color(0xFFEEE7F0), dark: Color(0xFF29212E));
  static const rose = (light: Color(0xFFF5E4DF), dark: Color(0xFF312020));
  static const azur = (light: Color(0xFFE7ECED), dark: Color(0xFF1F282B));
  static const sable = (light: Color(0xFFF1E6CF), dark: Color(0xFF2C2518));
  static const sauge = (light: Color(0xFFE8EBD9), dark: Color(0xFF252A1D));
  static const bonbon = (light: Color(0xFFF2E1E5), dark: Color(0xFF2E2027));
  static const nuage = (light: Color(0xFFFFFDF6), dark: Color(0xFF221C14));

  static List<({Color light, Color dark, String name})> get all => [
    (light: menthe.light, dark: menthe.dark, name: 'menthe'),
    (light: citron.light, dark: citron.dark, name: 'citron'),
    (light: peche.light, dark: peche.dark, name: 'peche'),
    (light: lavande.light, dark: lavande.dark, name: 'lavande'),
    (light: rose.light, dark: rose.dark, name: 'rose'),
    (light: azur.light, dark: azur.dark, name: 'azur'),
    (light: sable.light, dark: sable.dark, name: 'sable'),
    (light: sauge.light, dark: sauge.dark, name: 'sauge'),
    (light: bonbon.light, dark: bonbon.dark, name: 'bonbon'),
    (light: nuage.light, dark: nuage.dark, name: 'nuage'),
  ];
}

/// The three durations the app moves in: a fade, a change of shape, and a move
/// the eye can follow. Everything else — a wait, a snackbar, the spinner — is a
/// duration in time rather than a motion, and keeps its own value.
class TanoMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 450);
}

// --- Dimensions & Layout ---
const double appPaddingLarge = 18.0;
const double appPaddingMedium = 12.0;
const double appPaddingSmall = 6.0;

/// The two gaps the code writes most, which the trio above does not cover:
/// a tight one between two lines or around an icon, a wide one as the inner
/// margin of a card or a list.
const double appPaddingTight = 8.0;
const double appPaddingWide = 16.0;

/// The rhythm between two blocks of a screen. The About footer, for instance,
/// is four of those.
const double sectionGap = 24.0;
const double appBorderRadius = 12.0;
const double sectionBorderRadius = 24.0;

/// Pill radius of the full-width buttons (reset, confirm).
const double pillRadius = 55.0;

/// Radius of a settings card.
const double settingsCardRadius = 8.0;

/// The app's type scale, outside the cards.
///
/// The cards have their own micro scale in `card_typography.dart`; everything
/// else reads from here, so a size is never invented twice. Changing a value
/// below moves every screen that uses it.
///
/// The splash keeps its own literals: its sizes are baked into the generated
/// PNGs (`tool/generate_splash_logo.dart`), so they only move together.
class TanoText {
  /// Page title ("À propos", a folder name…).
  static const double pageTitle = 28.0;

  /// Label of an action in an action sheet.
  static const double sheetAction = 20.0;

  /// « TanoNote », in a dialog.
  static const double wordmark = 18.0;

  /// Title of a row: a setting, an action, a menu entry.
  static const double listTitle = 17.0;

  /// Body copy: paragraphs, dialog content.
  static const double body = 17.0;

  /// Secondary label: tile subtitles, dialog footnotes.
  static const double label = 15.0;

  /// Smallest text: mentions, counters, and the metadata line of a header.
  static const double tiny = 12.0;

  /// Counter drawn on a bar ("/12").
  static const double badge = 10.0;
}

/// Helper to get the correct text color based on background luminance.
Color getTextColor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.light
      ? const Color(0xFF241F18)
      : const Color(0xFFEFE4D0);
}

/// Helper to get a subtle border color based on the background.
Color getBorderColor(Color background, {bool isDark = false}) {
  if (background == Colors.white ||
      background == darkBackground ||
      background == const Color(0xFF1E1E1E)) {
    return isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
  }

  // Light mode: make the border slightly darker
  // Dark mode: make the border slightly lighter
  return Color.lerp(background, isDark ? Colors.white : Colors.black, 0.12)!;
}

/// Border colour shared by the cards, the cover rules and the app bar:
/// light in dark mode, dark in light mode.
Color cardBorderColor(bool isDark) =>
    isDark ? const Color(0xFF3A3122) : const Color(0xFFD9CBB0);

/// Every route uses the hero paper; category colors belong to cards only.
Color getImmersiveBackgroundColor(Color noteColor, {bool isDark = false}) =>
    isDark ? darkBackground : lightBackground;

/// Dynamic surface color for bars and background.
Color barColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? darkBackground
      : lightBackground;
}

/// "Paper" background of the note editor.
Color editorBackground(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF221C14)
      : const Color(0xFFFFFDF6);
}

/// Primary text color.
Color primaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFEFE4D0)
      : const Color(0xFF241F18);
}

/// Muted text color.
Color mutedTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFB1A288)
      : const Color(0xFF6F6553);
}

/// Subtle fill for inputs and chips.
Color chipFillColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white.withValues(alpha: 0.05)
      : Colors.black.withValues(alpha: 0.05);
}

/// Helper for category-based colors (States or Pastels).
Color themeCategory(
  String value,
  bool withShade, {
  Brightness brightness = Brightness.light,
}) {
  final bool isDark = brightness == Brightness.dark;

  if (!withShade) {
    // --- State colors (Strong colors for borders/status) ---
    switch (value) {
      case 'neutral':
      case 'nuage':
        return isDark ? TanoStates.neutral.dark : TanoStates.neutral.light;
      case 'action':
      case 'menthe':
        return isDark ? TanoStates.action.dark : TanoStates.action.light;
      case 'success':
      case 'sauge':
        return isDark ? TanoStates.success.dark : TanoStates.success.light;
      case 'warning':
      case 'peche':
        return isDark ? TanoStates.warning.dark : TanoStates.warning.light;
      case 'error':
      case 'rose':
        return isDark ? TanoStates.error.dark : TanoStates.error.light;
      case 'purple':
      case 'lavande':
        return isDark ? TanoStates.purple.dark : TanoStates.purple.light;
      case 'yellow':
      case 'citron':
        return isDark ? TanoStates.yellow.dark : TanoStates.yellow.light;
      case 'reference':
      case 'azur':
        return isDark ? TanoStates.reference.dark : TanoStates.reference.light;
      case 'subtle':
      case 'sable':
        return isDark ? TanoStates.subtle.dark : TanoStates.subtle.light;
      case 'archive':
        return isDark ? TanoStates.archive.dark : TanoStates.archive.light;
      default:
        return Colors.grey.shade600;
    }
  }

  // --- Pastel colors (Subtle backgrounds) ---
  switch (value) {
    case 'action':
    case 'menthe':
      return isDark ? TanoPastels.menthe.dark : TanoPastels.menthe.light;
    case 'yellow':
    case 'citron':
      return isDark ? TanoPastels.citron.dark : TanoPastels.citron.light;
    case 'warning':
    case 'peche':
      return isDark ? TanoPastels.peche.dark : TanoPastels.peche.light;
    case 'purple':
    case 'lavande':
      return isDark ? TanoPastels.lavande.dark : TanoPastels.lavande.light;
    case 'error':
    case 'rose':
      return isDark ? TanoPastels.rose.dark : TanoPastels.rose.light;
    case 'reference':
    case 'azur':
      return isDark ? TanoPastels.azur.dark : TanoPastels.azur.light;
    case 'subtle':
    case 'sable':
      return isDark ? TanoPastels.sable.dark : TanoPastels.sable.light;
    case 'success':
    case 'sauge':
      return isDark ? TanoPastels.sauge.dark : TanoPastels.sauge.light;
    case 'bonbon':
      return isDark ? TanoPastels.bonbon.dark : TanoPastels.bonbon.light;
    case 'neutral':
    case 'archive':
    case 'nuage':
    default:
      return isDark ? TanoPastels.nuage.dark : TanoPastels.nuage.light;
  }
}

/// Site palette, shared by paper decoration and translucent navigation.
Color paperRuleColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF2B2417)
    : const Color(0xFFE6DAC2);
Color paperSecondary(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF1F1A12)
    : const Color(0xFFEAE0CB);
Color accentColor(BuildContext context) =>
    Theme.of(context).colorScheme.primary;
Color amberColor(BuildContext context) =>
    Theme.of(context).colorScheme.secondary;

ThemeData tanoTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final paper = dark ? darkBackground : lightBackground;
  final card = dark ? const Color(0xFF221C14) : const Color(0xFFFFFDF6);
  final ink = dark ? const Color(0xFFEFE4D0) : const Color(0xFF241F18);
  final muted = dark ? const Color(0xFFB1A288) : const Color(0xFF6F6553);
  final rule = cardBorderColor(dark);
  final scheme = ColorScheme.fromSeed(
    seedColor: tanoTeal,
    brightness: brightness,
    primary: dark ? const Color(0xFF5CC9BD) : tanoTeal,
    onPrimary: dark ? const Color(0xFF10241F) : const Color(0xFFFDFAF2),
    secondary: dark ? tanoAmberDark : tanoAmber,
    surface: card,
    onSurface: ink,
    onSurfaceVariant: muted,
    outline: rule,
    outlineVariant: rule,
  );
  final base = ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    useMaterial3: true,
  );
  return base.copyWith(
    scaffoldBackgroundColor: paper,
    canvasColor: paper,
    textTheme: base.textTheme.apply(bodyColor: ink, displayColor: ink),
    dividerColor: rule,
    appBarTheme: AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: rule),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: rule),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      hintStyle: TextStyle(color: muted),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.secondary.withValues(alpha: .25),
      selectionHandleColor: scheme.primary,
    ),
  );
}
