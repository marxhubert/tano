import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/fab/fab_state.dart';

void _page(
  FabPresentation state, {
  FabMode mode = FabMode.editor,
  bool keyboard = false,
  bool rename = false,
  bool collapsed = false,
  bool canMove = true,
}) => state.reconcile(
  mode: mode,
  keyboardOpen: keyboard,
  titleEditing: rename,
  collapsedByDefault: collapsed,
  canMove: canMove,
);

void main() {
  test('automatic editor default follows keyboard until the user chooses', () {
    final state = FabPresentation(mode: FabMode.editor);
    _page(state);
    expect(state.expanded, isTrue);
    _page(state, keyboard: true);
    expect(state.expanded, isFalse);
    state.openMenu(FabVerticalMenu.add);
    _page(state, keyboard: false);
    _page(state, keyboard: true);
    expect(state.expanded, isTrue);
    expect(state.menu, FabVerticalMenu.add);
    state.collapse();
    _page(state, keyboard: false);
    expect(state.expanded, isFalse);
    expect(state.menu, FabVerticalMenu.none);
  });

  test('closing a panel keeps the explicit extended bar', () {
    final state = FabPresentation(
      mode: FabMode.editor,
      initiallyCollapsed: true,
    );
    expect(state.expanded, isFalse);
    state.openMenu(FabVerticalMenu.add);
    state.closeMenu();
    expect(state.expanded, isTrue);
    expect(state.menu, FabVerticalMenu.none);
  });

  test('selection capability revocation closes its move submenu', () {
    final state = FabPresentation(mode: FabMode.selection);
    _page(state, mode: FabMode.selection);
    state.openMove(FabVerticalMenu.none);
    expect(state.menu, FabVerticalMenu.move);
    _page(state, mode: FabMode.selection, canMove: false);
    expect(state.menu, FabVerticalMenu.none);
    expect(state.expanded, isTrue);
    state.openMove(FabVerticalMenu.none);
    expect(state.menu, FabVerticalMenu.none);
  });

  test('rename forbids menus until explicitly reopened after editing', () {
    final state = FabPresentation(mode: FabMode.folder);
    _page(state, mode: FabMode.folder);
    state.openMenu(FabVerticalMenu.color);
    _page(state, mode: FabMode.folder, rename: true);
    state.openMenu(FabVerticalMenu.more);
    expect(state.menu, FabVerticalMenu.none);
    expect(state.expanded, isFalse);
    _page(state, mode: FabMode.folder);
    expect(state.expanded, isFalse);
    state.expand();
    expect(state.expanded, isTrue);
  });

  test(
    'page modes exclude irrelevant panels and clear return destinations',
    () {
      final state = FabPresentation(mode: FabMode.editor);
      state.openMove(FabVerticalMenu.more);
      _page(state, mode: FabMode.find);
      expect(state.menu, FabVerticalMenu.none);
      expect(state.moveReturnTo, FabVerticalMenu.none);
      for (final mode in [FabMode.home, FabMode.search, FabMode.find]) {
        _page(state, mode: mode);
        for (final menu in FabVerticalMenu.values) {
          state.openMenu(menu);
          expect(state.menu, FabVerticalMenu.none);
        }
      }
    },
  );
}
