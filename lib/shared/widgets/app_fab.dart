import 'package:flutter/material.dart';
import 'package:tano/shared/config/l10n.dart';

/// The unified FAB that morphs between 4 states:
/// 1. Home Add (circle icon)
/// 2. Home Search (expanded text field)
/// 3. Home Selection (expanded action bar with 3 buttons)
/// 4. Editor Mode (expanded by default, manual toggle when keyboard is open)
class AppFab extends StatefulWidget {
  const AppFab({
    super.key,
    this.isSearchMode = false,
    this.isSelectionMode = false,
    this.isEditorMode = false,
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
  });

  final bool isSearchMode;
  final bool isSelectionMode;
  final bool isEditorMode;
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

  @override
  State<AppFab> createState() => _AppFabState();
}

class _AppFabState extends State<AppFab> {
  bool _isManuallyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double btnMargin = 24.0;
    final double btnHeight = 56.0;
    final double expandedHeight = 48.0;
    final double expandedWidth = screenWidth - btnMargin;
    final bool isKeyboardClosed = MediaQuery.of(context).viewInsets.bottom == 0;

    // Home logic: expands in Search or Selection
    bool isExpanded = widget.isSearchMode || widget.isSelectionMode;

    // Editor logic: expanded by default if keyboard is closed, or manually toggled if keyboard is open
    if (widget.isEditorMode) {
      isExpanded = isKeyboardClosed || _isManuallyExpanded;
    }

    final double targetWidth = isKeyboardClosed ? expandedWidth * 0.9 : expandedWidth;
    final double currentWidth = isExpanded ? targetWidth : btnHeight;

    // Position adjustment
    final double tx = isExpanded ? ((currentWidth - screenWidth) / 2 + btnMargin) : 0.0;
    final double ty = (widget.isSearchMode && !isKeyboardClosed) ? btnMargin - 8.0 : 0.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: widget.isSearchMode ? expandedHeight : btnHeight,
      width: currentWidth,
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      transform: Matrix4.translationValues(tx, ty, 0.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular((widget.isSearchMode ? expandedHeight : btnHeight) / 2),
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
      child: _buildContent(context, isExpanded),
    );
  }

  Widget _buildContent(BuildContext context, bool isExpanded) {
    // --- Editor Mode ---
    if (widget.isEditorMode) {
      if (!isExpanded) {
        return IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () => setState(() => _isManuallyExpanded = true),
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: widget.onSave,
          ),
          IconButton(
            icon: const Icon(Icons.color_lens_outlined, color: Colors.white),
            onPressed: widget.onColorLens,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: widget.onMore,
          ),
          // Collapser shown only when keyboard is open
          if (MediaQuery.of(context).viewInsets.bottom > 0)
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () => setState(() => _isManuallyExpanded = false),
            ),
        ],
      );
    }

    // --- Home: Selection Mode ---
    if (widget.isSelectionMode) {
      final String deleteLabel = AppText.tr('delete');
      final String capitalizedDelete = deleteLabel.isNotEmpty
          ? deleteLabel[0].toUpperCase() + deleteLabel.substring(1)
          : deleteLabel;

      return Row(
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
      );
    }

    // --- Home: Search Mode ---
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

    // --- Home: Default (Add) ---
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
