import 'package:flutter/material.dart';

import 'package:tano/shared/config/l10n.dart';

/// The round add button that morphs into a full-width search field.
///
/// The container animates its width, expanding towards the left while keeping
/// its right edge anchored to the screen edge (the FAB location is flush).
class SearchFab extends StatelessWidget {
  const SearchFab({
    super.key,
    required this.isSearchMode,
    required this.controller,
    required this.focusNode,
    required this.onAdd,
    required this.onSearchChanged,
    required this.onReset,
    required this.onClose,
  });

  final bool isSearchMode;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final double btnMargin = 24.0;
    final double btnHeight = 56.0;
    final double expandedHeight = 48.0;
    final double expandedWidth = MediaQuery.of(context).size.width - btnMargin;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: isSearchMode ? expandedHeight : btnHeight,
      width: isSearchMode ? expandedWidth : btnHeight,
      clipBehavior: Clip.hardEdge,
      alignment: Alignment.center,
      transform: Matrix4.translationValues(
          isSearchMode ? btnMargin / 2 : 0,
          isSearchMode ? (btnMargin - 8.0) : 0,
          0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular((isSearchMode ? expandedHeight : btnHeight) / 2),
      ),
      child: isSearchMode
        ? Container(
          padding: EdgeInsets.only(left: 12.0),
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
                    onClose();
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
        )
        : IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: onAdd,
          ),
    );
  }
}
