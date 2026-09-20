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
  if (tablet || landscape) return isList ? 2 : 3;
  return isList ? 1 : 2;
}
