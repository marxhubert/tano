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
  if (tablet) return isList ? 3 : 4;
  return isList ? 1 : 2;
}

/// A landscape window is too short for the big title line: the page puts the
/// title, with its metadata in front of it, on the app bar instead. Phones and
/// tablets alike.
bool condensedHeader(Size viewport) => viewport.width > viewport.height;

/// A landscape *phone* reaches both edges: the page content it shows is flush.
/// A landscape tablet keeps a margin, so its chrome can line up with the cards.
bool flushSidePadding(Size viewport) =>
    viewport.width > viewport.height && viewport.shortestSide < 600;

/// A tablet window: a shortest side of at least 600 logical pixels.
bool tabletViewport(Size viewport) => viewport.shortestSide >= 600;

/// A tablet, or a phone held landscape: the chrome takes its compact form — an
/// anchored FAB that never nudges, a condensed title, panel-shaped menus.
bool compactChrome(Size viewport) =>
    viewport.width > viewport.height || tabletViewport(viewport);

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
