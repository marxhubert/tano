import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

enum FabVerticalMenu { none, save, color, more }

/// The unified FAB that morphs between 5 states:
/// 1. Home Add (circle icon)
/// 2. Home Search (expanded text field)
/// 3. Home Selection (expanded action bar with 3 buttons)
/// 4. Editor Mode (expanded by default)
/// 5. Vertical Menu (expanded upwards to show options like colors)
class AppFab extends StatefulWidget {
  const AppFab({
    super.key,
    this.isSearchMode = false,
    this.isSelectionMode = false,
    this.isEditorMode = false,
    this.isAddMode = false,
    this.controller,
    this.focusNode,
    this.onAdd,
    this.onSearchChanged,
    this.onReset,
    this.onDelete,
    this.onClearSelection,
    this.onSelectAll,
    this.onSave,
    this.onColorLens,
    this.onMore,
    this.onColorSelected,
    this.currentCategory,
  });

  final bool isSearchMode;
  final bool isSelectionMode;
  final bool isEditorMode;
  final bool isAddMode;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final VoidCallback? onAdd;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onReset;
  final VoidCallback? onDelete;
  final VoidCallback? onClearSelection;
  final VoidCallback? onSelectAll;
  final VoidCallback? onSave;
  final VoidCallback? onColorLens;
  final VoidCallback? onMore;
  final ValueChanged<String>? onColorSelected;
  final String? currentCategory;

  @override
  State<AppFab> createState() => AppFabState();
}

class AppFabState extends State<AppFab> {
  bool? _isManuallyExpanded;
  bool _wasKeyboardClosed = true;
  FabVerticalMenu _verticalMenu = FabVerticalMenu.none;

  @override
  void initState() {
    super.initState();
    // In Editor mode, we start collapsed if it's a new note (add mode).
    if (widget.isEditorMode && widget.isAddMode) {
      _isManuallyExpanded = false;
    }
  }

  void closeVerticalMenu() {
    if (_verticalMenu != FabVerticalMenu.none) {
      setState(() {
        _verticalMenu = FabVerticalMenu.none;
      });
    }
  }

  void _toggleVerticalMenu(FabVerticalMenu menu) {
    setState(() {
      _verticalMenu = (_verticalMenu == menu) ? FabVerticalMenu.none : menu;
      if (_verticalMenu != FabVerticalMenu.none) {
        _isManuallyExpanded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double btnMargin = 24.0;
    final double btnHeight = 56.0;
    final double expandedHeight = 48.0;
    final double expandedWidth = screenWidth - btnMargin;

    final bool isKeyboardClosed = MediaQuery.of(context).viewInsets.bottom == 0;

    if (isKeyboardClosed != _wasKeyboardClosed) {
      _isManuallyExpanded = null;
      _wasKeyboardClosed = isKeyboardClosed;
    }

    bool isExpanded = widget.isSearchMode || widget.isSelectionMode;
    if (widget.isEditorMode) {
      isExpanded = _isManuallyExpanded ?? isKeyboardClosed;
    }

    // Rule: Any horizontal collapse must close the vertical menu
    if (!isExpanded && _verticalMenu != FabVerticalMenu.none) {
      _verticalMenu = FabVerticalMenu.none;
    }

    final double targetWidth = (isKeyboardClosed && _verticalMenu == FabVerticalMenu.none)
        ? expandedWidth * 0.9
        : expandedWidth * 0.95;
    final double currentWidth = isExpanded ? targetWidth : btnHeight;

    // Vertical Expansion Height
    double currentHeight = widget.isSearchMode ? expandedHeight : btnHeight;
    const double verticalMenuHeight = 200.0;
    if (_verticalMenu != FabVerticalMenu.none) {
      currentHeight += verticalMenuHeight;
    }

    final double tx =
        isExpanded ? ((currentWidth - screenWidth) / 2 + btnMargin) : 0.0;

    double ty = 0.0;
    if (!isKeyboardClosed) {
      if (widget.isSearchMode) {
        ty = btnMargin - 8.0;
      } else if (widget.isEditorMode) {
        ty = 12.0;
      }
    }

    final double borderRadiusValue = _verticalMenu != FabVerticalMenu.none
        ? 28.0
        : (widget.isSearchMode ? expandedHeight : btnHeight) / 2;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: currentHeight,
      width: currentWidth,
      clipBehavior: Clip.hardEdge,
      transform: Matrix4.translationValues(tx, ty, 0.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(borderRadiusValue),
        border: Border.all(
          color: getBorderColor(
            Theme.of(context).colorScheme.primary,
            isDark: Theme.of(context).brightness == Brightness.dark,
          ),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final double expansionProgress =
            (constraints.maxWidth - btnHeight) / (targetWidth - btnHeight);
        final bool showContent = !isExpanded || expansionProgress > 0.75;

        return AnimatedOpacity(
          opacity: showContent ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 100),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              if (_verticalMenu != FabVerticalMenu.none)
                Positioned(
                  bottom: widget.isSearchMode ? expandedHeight : btnHeight,
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _buildVerticalMenuContent(context),
                ),
              SizedBox(
                height: widget.isSearchMode ? expandedHeight : btnHeight,
                child: _buildMainContent(context, isExpanded, targetWidth),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVerticalMenuContent(BuildContext context) {
    if (_verticalMenu == FabVerticalMenu.color) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppText.tr('menu_theme'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16.0,
                  crossAxisSpacing: 16.0,
                  childAspectRatio: 1.8,
                ),
                itemCount: TanoPastels.all.length,
                itemBuilder: (context, index) {
                  final pair = TanoPastels.all[index];
                  final bool isSelected =
                      pair.name == (widget.currentCategory ?? 'nuage');

                  return GestureDetector(
                    onTap: () {
                      widget.onColorSelected?.call(pair.name);
                    },
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? tanoAmber : Colors.white30,
                          width: isSelected ? 2.0 : 0.6,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              Expanded(child: Container(color: pair.light)),
                              Expanded(child: Container(color: pair.dark)),
                            ],
                          ),
                          if (isSelected)
                            Container(
                              color: Colors.black45,
                              child: const Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: tanoAmber,
                                  size: 20.0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMainContent(
      BuildContext context, bool isExpanded, double targetWidth) {
    if (widget.isEditorMode) {
      if (!isExpanded) {
        return IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () => setState(() => _isManuallyExpanded = true),
        );
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: targetWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  widget.onSave?.call();
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.color_lens_outlined,
                  color: _verticalMenu == FabVerticalMenu.color
                      ? tanoAmber
                      : Colors.white,
                ),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _toggleVerticalMenu(FabVerticalMenu.color);
                  widget.onColorLens?.call();
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  widget.onMore?.call();
                },
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    size: 18.0, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _verticalMenu = FabVerticalMenu.none;
                    _isManuallyExpanded = false;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    if (widget.isSelectionMode) {
      final String deleteLabel = AppText.tr('delete');
      final String capitalizedDelete = deleteLabel.isNotEmpty
          ? deleteLabel[0].toUpperCase() + deleteLabel.substring(1)
          : deleteLabel;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: targetWidth,
          child: Row(
            children: <Widget>[
              _SelectionFabButton(
                icon: Icons.delete,
                label: capitalizedDelete,
                color: const Color(0xFFFF8A80),
                onPressed: widget.onDelete ?? () {},
              ),
              _SelectionFabButton(
                icon: Icons.check_box_outline_blank,
                label: AppText.tr('select_none'),
                onPressed: widget.onClearSelection ?? () {},
              ),
              _SelectionFabButton(
                icon: Icons.select_all,
                label: AppText.tr('select_all'),
                onPressed: widget.onSelectAll ?? () {},
              ),
            ],
          ),
        ),
      );
    }

    if (widget.isSearchMode) {
      return Container(
        padding: const EdgeInsets.only(left: 12.0),
        child: Row(
          spacing: 8.0,
          children: <Widget>[
            const Icon(Icons.search, color: Colors.white, size: 24.0),
            Expanded(
              flex: 1,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.0,
                ),
                decoration: InputDecoration(
                  hintText: AppText.tr('search'),
                  hintStyle: const TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: widget.onSearchChanged,
                onTapOutside: (_) {
                  widget.focusNode?.unfocus();
                },
              ),
            ),
            if (widget.controller?.text.isNotEmpty ?? false)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: widget.onReset,
              ),
          ],
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: widget.onAdd,
    );
  }
}

class _SelectionFabButton extends StatelessWidget {
  const _SelectionFabButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color effectiveColor = color ?? Colors.white;
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 20.0, color: effectiveColor),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.0,
                color: effectiveColor,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
