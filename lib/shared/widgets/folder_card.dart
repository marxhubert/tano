import 'package:flutter/material.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/shared/widgets/theme.dart';

/// A folder card, shared by the list and grid views.
///
/// Grid: the folder icon sits in the top-left corner, the name at the bottom.
/// List: the icon is on the left, vertically centred, the name on its right.
/// The metadata (icon + note count) is below the name, in grey, and hidden
/// when there is nothing to show.
class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.folder,
    required this.noteCount,
    this.isListLayout = false,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isInSelectionMode = false,
    this.onSelectionToggle,
  });

  final Folder folder;
  final int noteCount;
  final bool isListLayout;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isInSelectionMode;
  final VoidCallback? onSelectionToggle;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = themeCategory(
      folder.category,
      true,
      brightness: Theme.of(context).brightness,
    );
    final Color borderColor = getBorderColor(bgColor, isDark: isDark);
    final Color textColor = getTextColor(bgColor);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(appBorderRadius),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 2.0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          if (folder.important)
            Positioned(
              top: -4.0,
              right: 4.0,
              child: Icon(
                Icons.bookmark,
                size: 16.0,
                color: tanoAmber.withValues(alpha: 0.8),
              ),
            ),
          InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 6.0),
              child: isListLayout ? _buildList(textColor) : _buildGrid(textColor),
            ),
          ),
          if (isInSelectionMode)
            Positioned.fill(
              child: GestureDetector(
                onTap: onSelectionToggle,
                child: Container(
                  color: isSelected ? Colors.black38 : Colors.black12,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.panorama_fish_eye,
                        size: 24.0,
                        color: isDark ? TanoStates.action.dark : tanoTeal,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGrid(Color textColor) {
    // Fill the whole card so every area (not just the text) stays tappable.
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.folder_open, size: 22.0, color: textColor),
          const Spacer(),
          Text(
            folder.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          _metadata(textColor),
        ],
      ),
    );
  }

  Widget _buildList(Color textColor) {
    return Row(
      children: <Widget>[
        Icon(Icons.folder_open, size: 22.0, color: textColor),
        const SizedBox(width: 10.0),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                folder.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              _metadata(textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metadata(Color textColor) {
    if (noteCount <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.description_outlined,
            size: 11.0,
            color: textColor.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 3.0),
          Text(
            '$noteCount',
            style: TextStyle(
              fontSize: 9.0,
              color: textColor.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
