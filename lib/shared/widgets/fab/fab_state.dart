/// One effective mode, even while a page is changing several flags together.
enum FabMode { home, editor, folder, search, selection, find }

enum FabVerticalMenu { none, add, color, more, link, move }

/// Synchronous presentation state. Loading data never decides which menu opens.
/// Widget lifecycle methods reconcile page inputs; rendering only reads state.
class FabPresentation {
  FabPresentation({required FabMode mode, bool initiallyCollapsed = false})
    : _mode = mode,
      _manualExpansion = initiallyCollapsed ? false : null;

  FabMode _mode;
  bool? _manualExpansion;
  bool _keyboardOpen = false;
  bool _titleEditing = false;
  bool _collapsedByDefault = false;
  bool _canMove = true;
  FabVerticalMenu _menu = FabVerticalMenu.none;
  FabVerticalMenu _moveReturnTo = FabVerticalMenu.none;

  FabMode get mode => _mode;
  FabVerticalMenu get menu => _menu;
  FabVerticalMenu get moveReturnTo => _moveReturnTo;
  bool get expanded {
    if (_titleEditing) return false;
    if (_mode == FabMode.search ||
        _mode == FabMode.selection ||
        _mode == FabMode.find) {
      return true;
    }
    return _manualExpansion ??
        (_mode != FabMode.home && !_keyboardOpen && !_collapsedByDefault);
  }

  void reconcile({
    required FabMode mode,
    required bool keyboardOpen,
    required bool titleEditing,
    required bool collapsedByDefault,
    required bool canMove,
  }) {
    if (_mode != mode) {
      closeMenu();
      _manualExpansion = null;
    }
    _mode = mode;
    _keyboardOpen = keyboardOpen;
    _titleEditing = titleEditing;
    _collapsedByDefault = collapsedByDefault;
    _canMove = canMove;
    if (titleEditing) collapse();
    if (!allows(_menu)) closeMenu();
    // Explicit user intent survives keyboard metrics, rotation and rebuilds.
    // Only an untouched FAB uses the automatic keyboard-based default.
  }

  bool allows(FabVerticalMenu menu) {
    if (menu == FabVerticalMenu.none) return true;
    if (_titleEditing) return false;
    return switch (_mode) {
      FabMode.editor => true,
      FabMode.folder =>
        menu != FabVerticalMenu.link && menu != FabVerticalMenu.move,
      FabMode.selection => menu == FabVerticalMenu.move && _canMove,
      FabMode.home || FabMode.search || FabMode.find => false,
    };
  }

  void expand() {
    if (!_titleEditing) _manualExpansion = true;
  }

  void collapse() {
    _manualExpansion = false;
    closeMenu();
  }

  void closeMenu() {
    _menu = FabVerticalMenu.none;
    _moveReturnTo = FabVerticalMenu.none;
  }

  void openMenu(FabVerticalMenu menu) {
    if (!allows(menu)) return;
    if (menu == FabVerticalMenu.none) {
      closeMenu();
    } else {
      _menu = menu;
      expand();
    }
  }

  void toggleMenu(FabVerticalMenu menu) {
    if (_menu == menu) {
      closeMenu();
    } else {
      openMenu(menu);
    }
  }

  void openMove(FabVerticalMenu returnTo) {
    if (!allows(FabVerticalMenu.move)) return;
    _moveReturnTo = returnTo;
    openMenu(FabVerticalMenu.move);
  }
}
