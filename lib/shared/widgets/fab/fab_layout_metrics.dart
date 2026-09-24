import 'package:flutter/widgets.dart';
import 'package:tano/shared/widgets/entity_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Spacing and column geometry shared by the FAB's location and its pure
/// geometry.
///
/// `FlushFabLocation` positions the button and `FabGeometry.resolve` sizes it;
/// both must agree on where the content column sits and how far the button
/// stays from its edge. The numbers used to be duplicated in the two files and
/// could drift apart.

/// Distance between the FAB and the edge of its content column.
double fabHorizontalGap(Size viewport) => compactChrome(viewport)
    ? (tabletViewport(viewport) ? 24.0 : 12.0)
    : 24.0;

/// Distance between the FAB and the bottom edge on a compact window.
double fabBottomGap(Size viewport) =>
    compactChrome(viewport) ? (tabletViewport(viewport) ? 24.0 : 12.0) : 20.0;

/// The content column for [viewport]: its left edge and its width, safe side
/// insets excluded and capped at [appContentMaxWidth].
({double left, double width}) fabContentColumn(Size viewport, EdgeInsets safe) {
  final double sideInset = safe.left > safe.right ? safe.left : safe.right;
  final double available = viewport.width - sideInset * 2;
  final double width = available < appContentMaxWidth
      ? available
      : appContentMaxWidth;
  return (left: (viewport.width - width) / 2, width: width);
}
