import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Pinned marker shown first in a card's metadata row.
///
/// Material Symbols pin, rotated -90 degrees, at the normal weight.
Widget buildPinnedMarker(Color color) {
  return RotatedBox(
    quarterTurns: -1,
    child: Icon(
      Symbols.push_pin,
      size: 14,
      weight: 400,
      color: color,
    ),
  );
}
