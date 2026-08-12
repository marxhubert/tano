import 'package:flutter/material.dart';

/// Blue-grey surface used for the bars and the scaffold background.
Color barColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.blueGrey.shade900
      : Colors.blueGrey.shade50;
}

/// "Paper" background of the note editor.
Color editorBackground(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.blueGrey.shade900
      : Colors.white;
}

/// Primary text color (logo, dialog body, dates).
Color primaryTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade300
      : Colors.black87;
}

/// Muted text color (dates, secondary information).
Color mutedTextColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.grey.shade400
      : Colors.black;
}

/// Subtle fill for the search bar and similar chips.
Color chipFillColor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? Colors.white12
      : Colors.black12;
}
