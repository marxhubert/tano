import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/fab/fab_geometry.dart';

FabGeometry geometry({
  Size size = const Size(390, 844),
  EdgeInsets padding = EdgeInsets.zero,
  EdgeInsets viewPadding = EdgeInsets.zero,
  double keyboard = 0,
  bool expanded = false,
  bool menuOpen = false,
  bool compactBar = false,
  bool onLeft = false,
  double menuHeight = 300,
}) => FabGeometry.resolve(
  media: MediaQueryData(
    size: size,
    padding: padding,
    viewPadding: viewPadding,
    viewInsets: EdgeInsets.only(bottom: keyboard),
  ),
  expanded: expanded,
  menuOpen: menuOpen,
  compactBar: compactBar,
  onLeft: onLeft,
  menuHeight: menuHeight,
);

void main() {
  test('resting, extended and menu forms retain their normal geometry', () {
    final rest = geometry();
    expect(rest.width, 64);
    expect(rest.height, 64);
    expect(rest.radius, BorderRadius.circular(55));
    expect(rest.offset, Offset.zero);

    final extended = geometry(expanded: true);
    expect(extended.width, 342);
    expect(extended.height, 64);

    // An open menu implies an extended bar even if the caller omitted expanded.
    final menu = geometry(menuOpen: true);
    expect(menu.width, 366);
    expect(menu.height, 364);
    expect(menu.radius.topLeft, const Radius.circular(24));
    expect(menu.radius.bottomRight, const Radius.circular(55));
  });

  test('portrait nudge mirrors the anchor and preserves vertical position', () {
    final right = geometry(menuOpen: true);
    final left = geometry(menuOpen: true, onLeft: true);
    expect(right.offset, const Offset(12, 8));
    expect(left.offset, const Offset(-12, 8));
    expect(left.width, right.width);
    expect(left.height, right.height);

    final keyboard = geometry(expanded: true, keyboard: 300, onLeft: true);
    expect(keyboard.offset, const Offset(-12, 12));
    expect(geometry(keyboard: 300).offset.dx, 0);
  });

  test('compact windows keep their anchor across all forms', () {
    for (final size in [
      const Size(844, 390),
      const Size(768, 1024),
      const Size(1024, 768),
      const Size(2000, 1400),
    ]) {
      final rest = geometry(size: size);
      final extended = geometry(size: size, expanded: true);
      final menu = geometry(size: size, menuOpen: true);
      expect(rest.offset, Offset.zero);
      expect(extended.offset, Offset.zero);
      expect(menu.offset, Offset.zero);
      expect(menu.radius, BorderRadius.circular(24));
    }
    // Every compact window is capped to a portrait phone: 390 - 48, or 390 - 24
    // with a menu open. A bigger landscape phone lands on the same width.
    expect(geometry(size: const Size(844, 390), expanded: true).width, 342);
    expect(geometry(size: const Size(932, 430), expanded: true).width, 342);
    expect(geometry(size: const Size(932, 430), menuOpen: true).width, 366);
    expect(geometry(size: const Size(768, 1024), expanded: true).width, 342);
    expect(geometry(size: const Size(1024, 768), expanded: true).width, 342);
    expect(geometry(size: const Size(2000, 1400), menuOpen: true).width, 366);
  });

  test('search and find use 48px only while the keyboard is visible', () {
    expect(geometry(compactBar: true).barHeight, 64);
    expect(geometry(compactBar: true, keyboard: 300).barHeight, 48);
    expect(geometry(keyboard: 300).barHeight, 64);
  });

  test(
    'open menu fits between app bar and keyboard without counting safe area twice',
    () {
      final menu = geometry(
        menuOpen: true,
        menuHeight: 1000,
        keyboard: 300,
        viewPadding: const EdgeInsets.only(top: 44, bottom: 34),
      );
      final paintedBottom = 844 - 300 - 20 + menu.offset.dy;
      expect(paintedBottom - menu.height, 44 + kToolbarHeight);
      expect(menu.menuHeight, menu.maxMenuHeight);

      final withoutBottomSafeArea = geometry(
        menuOpen: true,
        menuHeight: 1000,
        keyboard: 300,
        viewPadding: const EdgeInsets.only(top: 44),
      );
      expect(menu.height, withoutBottomSafeArea.height);
    },
  );

  test('tablet menu clears its bottom safe area and 24px anchor gap', () {
    final menu = geometry(
      size: const Size(1024, 768),
      menuOpen: true,
      menuHeight: 1000,
      viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
    );
    final paintedBottom = 768 - 20 - 24;
    // It clears the safe area and the toolbar, and never passes two thirds.
    expect(
      paintedBottom - menu.height,
      greaterThanOrEqualTo(24 + kToolbarHeight),
    );
    expect(menu.menuHeight, lessThanOrEqualTo(768 * 2 / 3));
  });

  test('insufficient vertical space produces zero menu height', () {
    final menu = geometry(
      size: const Size(844, 250),
      keyboard: 180,
      menuOpen: true,
    );
    expect(menu.menuHeight, 0);
    expect(menu.maxMenuHeight, 0);
    expect(menu.height, menu.barHeight);
    expect(geometry(menuOpen: true, menuHeight: -50).menuHeight, 0);
    expect(geometry(menuHeight: 1000).menuHeight, 0);
  });

  test('narrow windows never produce negative or offscreen widths', () {
    for (final width in [0.0, 20.0, 80.0, 110.0, 150.0]) {
      for (final expanded in [false, true]) {
        for (final menuOpen in [false, true]) {
          final result = geometry(
            size: Size(width, 844),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            expanded: expanded,
            menuOpen: menuOpen,
          );
          expect(result.width, greaterThanOrEqualTo(0));
          expect(result.width, lessThanOrEqualTo(width));
          expect(result.expandedWidth, greaterThanOrEqualTo(0));
        }
      }
    }
    final menu = geometry(
      size: const Size(110, 844),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      menuOpen: true,
    );
    // After its 12px nudge, the right anchor remains inside the safe edge.
    final rightEdge = 110 - 10 - 24 + menu.offset.dx;
    expect(rightEdge, lessThanOrEqualTo(100));
    expect(rightEdge - menu.width, greaterThanOrEqualTo(10));
  });
}
