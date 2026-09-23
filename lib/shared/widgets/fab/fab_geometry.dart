import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tano/shared/widgets/entity_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Pure geometry for the FAB's current mode and viewport.
///
/// Positioning uses the same edge gaps as `FlushFabLocation`. The measured menu
/// height is only an input: resolving geometry never schedules a frame or changes
/// widget state.
@immutable
class FabGeometry {
  const FabGeometry._({
    required this.expandedWidth,
    required this.width,
    required this.barHeight,
    required this.menuHeight,
    required this.maxMenuHeight,
    required this.radius,
    required this.offset,
  });

  factory FabGeometry.resolve({
    required MediaQueryData media,
    required bool expanded,
    required bool menuOpen,
    required bool compactBar,
    required bool onLeft,
    required double menuHeight,
  }) {
    final compact = compactChrome(media.size);
    final keyboardOpen = media.viewInsets.bottom > 0;
    final effectiveExpanded = expanded || menuOpen;
    final wide = menuOpen || keyboardOpen;
    final sideInset = math.max(media.padding.left, media.padding.right);
    final safeWidth = math.max(0.0, media.size.width - sideInset * 2);
    // Every compact window — a landscape phone, a tablet — opens no wider than
    // a portrait phone: the bar keeps the phone's proportions instead of
    // stretching over the window.
    final widthCeiling = compactChrome(media.size)
        ? phonePortraitWidth
        : appContentMaxWidth;
    final contentWidth = math.min(
      math.min(compact ? media.size.shortestSide : safeWidth, safeWidth),
      widthCeiling,
    );
    final horizontalGap = compact
        ? (tabletViewport(media.size) ? 24.0 : 12.0)
        : 24.0;
    final nudge = !compact && wide ? 12.0 : 0.0;
    final maxExpandedWidth = math.max(0.0, safeWidth - horizontalGap + nudge);
    final expandedWidth = (contentWidth - (wide ? 24.0 : 48.0))
        .clamp(math.min(64.0, maxExpandedWidth), maxExpandedWidth)
        .toDouble();
    final restWidth = math.min(64.0, math.max(0.0, safeWidth - horizontalGap));
    final barHeight = compactBar && keyboardOpen ? 48.0 : 64.0;
    final offset = Offset(
      effectiveExpanded ? (onLeft ? -nudge : nudge) : 0.0,
      compact ? 0.0 : (menuOpen ? 8.0 : (keyboardOpen ? 12.0 : 0.0)),
    );

    // The keyboard already covers the bottom safe area. Subtracting both would
    // reserve that area twice and unnecessarily shrink the menu.
    final bottomInset = math.max(
      media.viewInsets.bottom,
      media.viewPadding.bottom,
    );
    final bottomGap = compact
        ? (tabletViewport(media.size) ? 24.0 : 12.0)
        : 20.0;
    final paintedBottom =
        media.size.height - bottomInset - bottomGap + offset.dy;
    // A second-degree menu never takes more than two thirds of the screen: its
    // list scrolls inside that.
    final double room =
        paintedBottom - media.viewPadding.top - kToolbarHeight - barHeight;
    final double ceiling = media.size.height * (3 / 5);
    final maxMenuHeight = math.max(0.0, room < ceiling ? room : ceiling);

    return FabGeometry._(
      expandedWidth: expandedWidth,
      width: effectiveExpanded ? expandedWidth : restWidth,
      barHeight: barHeight,
      menuHeight: menuOpen ? menuHeight.clamp(0.0, maxMenuHeight) : 0.0,
      maxMenuHeight: maxMenuHeight,
      radius: menuOpen
          ? (compact
                ? BorderRadius.circular(24)
                : const BorderRadius.vertical(
                    top: Radius.circular(24),
                    bottom: Radius.circular(55),
                  ))
          : BorderRadius.circular(55),
      offset: offset,
    );
  }

  final double expandedWidth;
  final double width;
  final double barHeight;
  final double menuHeight;

  /// Can be zero in a short viewport with the keyboard open. The renderer must
  /// constrain the whole menu, including its header, instead of imposing a
  /// minimum header height that would overflow the available space.
  final double maxMenuHeight;

  final BorderRadius radius;
  final Offset offset;

  double get height => barHeight + menuHeight;
}
