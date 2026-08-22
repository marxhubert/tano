import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/theme.dart';

enum FabVerticalMenu { none, add, color, more }

/// The unified FAB that morphs between various states (Home, Search, Selection, Editor).
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
    this.onImageSelected,
    this.onChecklistSelected,
    this.onLinkSelected,
    this.onAttachmentSelected,
    this.onPinSelected,
    this.onFindSelected,
    this.onMoveSelected,
    this.onLockSelected,
    this.onDeleteSelected,
    this.onCollaboratorsSelected,
    this.onShareSelected,
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
  final VoidCallback? onImageSelected;
  final VoidCallback? onChecklistSelected;
  final VoidCallback? onLinkSelected;
  final VoidCallback? onAttachmentSelected;
  final VoidCallback? onPinSelected;
  final VoidCallback? onFindSelected;
  final VoidCallback? onMoveSelected;
  final VoidCallback? onLockSelected;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onCollaboratorsSelected;
  final VoidCallback? onShareSelected;

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
    if (widget.isEditorMode && widget.isAddMode) {
      _isManuallyExpanded = false;
    }
  }

  void closeVerticalMenu() {
    if (_verticalMenu != FabVerticalMenu.none) {
      setState(() => _verticalMenu = FabVerticalMenu.none);
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
    const double btnMargin = 24.0;
    const double btnHeight = 56.0;
    const double expandedHeight = 48.0;
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

    if (!isExpanded && _verticalMenu != FabVerticalMenu.none) {
      _verticalMenu = FabVerticalMenu.none;
    }

    final double targetWidth =
        (isKeyboardClosed && _verticalMenu == FabVerticalMenu.none)
            ? expandedWidth * 0.9
            : expandedWidth * 0.95;
    final double currentWidth = isExpanded ? targetWidth : btnHeight;

    double verticalMenuHeight = 0;
    if (_verticalMenu == FabVerticalMenu.color) {
      verticalMenuHeight = 210.0;
    } else if (_verticalMenu == FabVerticalMenu.add) {
      verticalMenuHeight = 180.0;
    } else if (_verticalMenu == FabVerticalMenu.more) {
      verticalMenuHeight = 310.0;
    }

    double currentHeight = widget.isSearchMode ? expandedHeight : btnHeight;
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
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
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
    switch (_verticalMenu) {
      case FabVerticalMenu.color:
        return _buildColorMenu(context);
      case FabVerticalMenu.add:
        return _buildAddMenu(context);
      case FabVerticalMenu.more:
        return _buildMoreMenu(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildColorMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppText.tr('menu_theme'),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),
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
                  onTap: () => widget.onColorSelected?.call(pair.name),
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
                          const Center(
                            child: Icon(Icons.check_circle,
                                color: tanoAmber, size: 20.0),
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

  Widget _buildAddMenu(BuildContext context) {
    return _buildVerticalList([
      _VerticalMenuItem(
        icon: Icons.crop_original,
        label: AppText.tr('option_image'),
        onTap: widget.onImageSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.checklist,
        label: AppText.tr('option_checklist'),
        onTap: widget.onChecklistSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.link,
        label: AppText.tr('option_link'),
        onTap: widget.onLinkSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.attachment,
        label: AppText.tr('option_attachment'),
        onTap: widget.onAttachmentSelected,
      ),
    ]);
  }

  Widget _buildMoreMenu(BuildContext context) {
    final String deleteLabel = AppText.tr('delete');
    final String capitalizedDelete = deleteLabel.isNotEmpty
        ? deleteLabel[0].toUpperCase() + deleteLabel.substring(1)
        : '';

    return _buildVerticalList([
      _VerticalMenuItem(
        icon: Icons.push_pin_outlined,
        label: AppText.tr('option_pin'),
        onTap: widget.onPinSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.search,
        label: AppText.tr('option_find'),
        onTap: widget.onFindSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.drive_file_move_outlined,
        label: AppText.tr('option_move'),
        onTap: widget.onMoveSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.person_add_alt,
        label: AppText.tr('option_collaborators'),
        onTap: widget.onCollaboratorsSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.share,
        label: AppText.tr('option_share'),
        onTap: widget.onShareSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.lock_outline,
        label: AppText.tr('option_lock'),
        onTap: widget.onLockSelected,
      ),
      _VerticalMenuItem(
        icon: Icons.delete_outline,
        label: capitalizedDelete,
        iconColor: const Color(0xFFFF8A80),
        textColor: const Color(0xFFFF8A80),
        onTap: widget.onDeleteSelected,
      ),
    ]);
  }

  Widget _buildVerticalList(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildMainContent(
      BuildContext context, bool isExpanded, double targetWidth) {
    if (widget.isEditorMode) return _buildEditorBar(context, isExpanded, targetWidth);
    if (widget.isSelectionMode) return _buildSelectionBar(context, targetWidth);
    if (widget.isSearchMode) return _buildSearchBar(context);
    return _buildDefaultAddButton();
  }

  Widget _buildEditorBar(BuildContext context, bool isExpanded, double targetWidth) {
    if (!isExpanded) {
      return IconButton(
        icon: const Icon(Icons.more_horiz, color: Colors.white),
        onPressed: () => setState(() => _isManuallyExpanded = true),
      );
    }

    return _buildHorizontalBar(targetWidth, [
      _EditorAction(
        icon: Icons.add,
        isActive: _verticalMenu == FabVerticalMenu.add,
        onTap: () {
          FocusScope.of(context).unfocus();
          _toggleVerticalMenu(FabVerticalMenu.add);
        },
      ),
      _EditorAction(
        icon: Icons.color_lens_outlined,
        isActive: _verticalMenu == FabVerticalMenu.color,
        onTap: () {
          FocusScope.of(context).unfocus();
          _toggleVerticalMenu(FabVerticalMenu.color);
          widget.onColorLens?.call();
        },
      ),
      _EditorAction(
        icon: Icons.more_vert,
        isActive: _verticalMenu == FabVerticalMenu.more,
        onTap: () {
          FocusScope.of(context).unfocus();
          _toggleVerticalMenu(FabVerticalMenu.more);
          widget.onMore?.call();
        },
      ),
      IconButton(
        icon: const Icon(Icons.arrow_forward_ios, size: 18.0, color: Colors.white),
        onPressed: () => setState(() {
          _verticalMenu = FabVerticalMenu.none;
          _isManuallyExpanded = false;
        }),
      ),
    ]);
  }

  Widget _buildSelectionBar(BuildContext context, double targetWidth) {
    final String deleteLabel = AppText.tr('delete');
    final String capitalizedDelete = deleteLabel.isNotEmpty
        ? deleteLabel[0].toUpperCase() + deleteLabel.substring(1)
        : deleteLabel;

    return _buildHorizontalBar(targetWidth, [
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
    ]);
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12.0),
      child: Row(
        spacing: 8.0,
        children: <Widget>[
          const Icon(Icons.search, color: Colors.white, size: 24.0),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              style: const TextStyle(color: Colors.white, fontSize: 16.0),
              decoration: InputDecoration(
                hintText: AppText.tr('search'),
                hintStyle: const TextStyle(color: Colors.white70),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: widget.onSearchChanged,
              onTapOutside: (_) => widget.focusNode?.unfocus(),
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

  Widget _buildDefaultAddButton() {
    return IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: widget.onAdd,
    );
  }

  Widget _buildHorizontalBar(double width, List<Widget> children) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: SizedBox(
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        ),
      ),
    );
  }
}

class _EditorAction extends StatelessWidget {
  const _EditorAction({
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: isActive ? tanoAmber : Colors.white),
      onPressed: onTap,
    );
  }
}

class _VerticalMenuItem extends StatelessWidget {
  const _VerticalMenuItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? Colors.white70, size: 24.0),
            const SizedBox(width: 14.0),
            Text(
              label,
              style: TextStyle(color: textColor ?? Colors.white, fontSize: 15.0),
            ),
          ],
        ),
      ),
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
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
