import 'package:flutter/material.dart';

import 'package:tano/shared/config/l10n.dart';

/// The unified FAB that morphs between 3 states:
/// 1. Add (circle icon)
/// 2. Search (expanded text field)
/// 3. Selection (expanded action bar with 3 buttons)
class HomeFab extends StatelessWidget {
  const HomeFab({
    super.key,
    required this.isSearchMode,
    required this.isSelectionMode,
    required this.controller,
    required this.focusNode,
    required this.onAdd,
    required this.onSearchChanged,
    required this.onReset,
    required this.onDelete,
    required this.onClearSelection,
    required this.onSelectAll,
  });

  final bool isSearchMode;
  final bool isSelectionMode;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReset;
  final VoidCallback onDelete;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double btnMargin = 24.0;
    final double btnHeight = 56.0;
    final double expandedHeight = 48.0;
    final double expandedWidth = screenWidth - btnMargin;
    final bool isKeyboardClosed = MediaQuery.of(context).viewInsets.bottom == 0;

    // The FAB expands when in Search or Selection mode.
    final bool isExpanded = isSearchMode || isSelectionMode;

    // Use full width for Selection, and responsive width for Search.
    final double targetWidth = isKeyboardClosed ? expandedWidth * 0.9 : expandedWidth;

    final double currentWidth = isExpanded ? targetWidth : btnHeight;

    // Position adjustment to center the expanded bar while keeping the FAB
    // location anchored correctly.
    final double tx = isExpanded ? ((currentWidth - screenWidth) / 2 + btnMargin) : 0.0;

    // Vertical translation: slightly higher when keyboard is closed for better visibility.
    final double ty = (isSearchMode && !isKeyboardClosed) ? btnMargin - 8.0 : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: isSearchMode ? expandedHeight : btnHeight,
      width: currentWidth,
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      transform: Matrix4.translationValues(tx, ty, 0.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular((isSearchMode ? expandedHeight : btnHeight) / 2),
        boxShadow: isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isSelectionMode) {
      final String deleteLabel = AppText.tr('delete');
      final String capitalizedDelete = deleteLabel.isNotEmpty
          ? deleteLabel[0].toUpperCase() + deleteLabel.substring(1)
          : deleteLabel;

      return Row(
        children: <Widget>[
          _SelectionFabButton(
            icon: Icons.delete,
            label: capitalizedDelete,
            color: const Color(0xFFFF8A80), // Vibrant but balanced red for FAB
            onPressed: onDelete,
          ),
          _SelectionFabButton(
            icon: Icons.check_box_outline_blank,
            label: AppText.tr('select_none'),
            onPressed: onClearSelection,
          ),
          _SelectionFabButton(
            icon: Icons.select_all,
            label: AppText.tr('select_all'),
            onPressed: onSelectAll,
          ),
        ],
      );
    }

    if (isSearchMode) {
      return Container(
        padding: const EdgeInsets.only(left: 12.0),
        child: Row(
          spacing: 8.0,
          children: <Widget>[
            const Icon(Icons.search, color: Colors.white, size: 24.0),
            Expanded(
              flex: 1,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
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
                onChanged: onSearchChanged,
                onTapOutside: (_) {
                  focusNode.unfocus();
                },
              ),
            ),
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: onReset,
              ),
          ],
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.add, color: Colors.white),
      onPressed: onAdd,
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
