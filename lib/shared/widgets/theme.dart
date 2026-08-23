import 'package:flutter/material.dart';

// --- Identité Visuelle (30%) ---
const Color tanoTeal = Color(0xFF009688);
const Color tanoAmber = Color(0xFFFF9800);
const Color tanoAmberDark = Color(0xFFFFB74D);

// --- Fonds (60%) ---
const Color lightBackground = Color(0xFFF8F9FA);
const Color darkBackground = Color(0xFF121212);

// --- Palette des États (Tickets) ---
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
  static const menthe = (light: Color(0xFFE0F2F1), dark: Color(0xFF004D40));
  static const citron = (light: Color(0xFFFFF9C4), dark: Color(0xFF827717));
  static const peche = (light: Color(0xFFFFE0B2), dark: Color(0xFFBF360C));
  static const lavande = (light: Color(0xFFF3E5F5), dark: Color(0xFF4A148C));
  static const rose = (light: Color(0xFFFFEBEE), dark: Color(0xFF880E4F));
  static const azur = (light: Color(0xFFE1F5FE), dark: Color(0xFF01579B));
  static const sable = (light: Color(0xFFF5F5DC), dark: Color(0xFF3E2723));
  static const sauge = (light: Color(0xFFF1F8E9), dark: Color(0xFF1B5E20));
  static const bonbon = (light: Color(0xFFFCE4EC), dark: Color(0xFFAD1457));
  static const nuage = (light: Color(0xFFECEFF1), dark: Color(0xFF263238));

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

// --- Dimensions & Layout ---
const double appPaddingLarge = 18.0;
const double appPaddingMedium = 12.0;
const double appPaddingSmall = 6.0;
const double appBorderRadius = 12.0;
const double sectionBorderRadius = 24.0;

/// Helper to get the correct text color based on background luminance.
Color getTextColor(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.light
      ? Colors.black87
      : Colors.white;
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

/// Helper to get an even more subtle version of the note color for the page background.
Color getImmersiveBackgroundColor(Color noteColor, {bool isDark = false}) {
  if (isDark) {
    // Mix the deep hue with the dark background to dim it further
    return Color.lerp(noteColor, darkBackground, 0.7)!;
  }
  // Mix the pastel hue with white to make it even lighter
  return Color.lerp(noteColor, Colors.white, 0.7)!;
}

/// Dynamic surface color for bars and background.
Color barColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? darkBackground
      : lightBackground;
}

/// "Paper" background of the note editor.
Color editorBackground(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF1E1E1E) // Slightly lighter than background for depth
      : Colors.white;
}

/// Primary text color.
Color primaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade300
      : const Color(0xFF212121);
}

/// Muted text color.
Color mutedTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade500
      : Colors.black54;
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
