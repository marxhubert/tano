import 'package:flutter/material.dart';

/// Paper-card typography shared by note, task, folder and locked bodies.
/// Editorial serif text echoes the site; compact metadata stays in the app's
/// sans-serif family so dates and counts remain easy to scan.
const double cardTitleSize = 14.0;
const double cardDateSize = 10.0;
const double cardContentSize = 12.0;
const double cardContentLineHeight = 1.45;
const double cardMetaSize = 10.0;
const double cardMetaIconSize = 12.0;

TextStyle cardTitleStyle(Color textColor) => TextStyle(
  fontFamily: 'TanoSerif',
  fontSize: cardTitleSize,
  height: 1.2,
  fontWeight: FontWeight.w600,
  color: textColor,
);

/// Keeps small metadata legible against every light and dark paper tint.
Color cardMutedColor(Color textColor) => textColor.withValues(alpha: 0.72);

TextStyle cardDateStyle(Color textColor) => TextStyle(
  fontSize: cardDateSize,
  height: 1.2,
  color: cardMutedColor(textColor),
);

TextStyle cardContentStyle(
  Color textColor, {
  String? fontFamily = 'TanoSerif',
}) => TextStyle(
  fontFamily: fontFamily,
  fontSize: cardContentSize,
  color: textColor.withValues(alpha: 0.85),
  height: cardContentLineHeight,
);

TextStyle cardMetaStyle(Color color) =>
    TextStyle(fontSize: cardMetaSize, height: 1.2, color: color);
