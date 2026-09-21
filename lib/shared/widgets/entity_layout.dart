import 'package:flutter/widgets.dart';

/// Card density follows the current window, not the physical device. A tablet
/// window has a shortest side of at least 600 logical pixels; at 1440 pixels
/// wide, both layouts use the large-screen density. Resizing a window or
/// rotating a device therefore applies the same policy on every card screen.
int entityColumnCount(Size viewport, {required bool isList}) {
  if (viewport.width >= 1440) return 5;

  final bool landscape = viewport.width > viewport.height;
  final bool tablet = viewport.shortestSide >= 600;
  if (tablet && landscape) return isList ? 4 : 5;
  // A landscape phone is wide but short: four tiles fit the documents, on Home
  // and in a folder alike.
  if (landscape && !tablet) return isList ? 2 : 4;
  if (tablet) return isList ? 2 : 3;
  return isList ? 1 : 2;
}

/// A landscape phone is too short for the big title line: the page puts the
/// title, with its metadata in front of it, on the app bar instead.
bool condensedHeader(Size viewport) =>
    viewport.width > viewport.height && viewport.shortestSide < 600;

/// Folder cards are denser than document cards, and the folder group stays a
/// grid whatever layout the documents use: three across a phone, five once the
/// window is landscape or a tablet, seven on a tablet held landscape and up.
int folderColumnCount(Size viewport) {
  if (viewport.width >= 1440) return 7;

  final bool landscape = viewport.width > viewport.height;
  final bool tablet = viewport.shortestSide >= 600;
  if (tablet && landscape) return 7;
  if (tablet || landscape) return 5;
  return 3;
}
