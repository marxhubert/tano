import 'package:flutter/material.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/shared/widgets/cover_image.dart';
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
    this.coverImage,
  });

  final Folder folder;
  final int noteCount;
  final bool isListLayout;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isInSelectionMode;
  final VoidCallback? onSelectionToggle;

  /// Stored cover image name, drawn as a background.
  final String? coverImage;

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
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // The cover is a background: the top half in the grid, the left
          // third in the list.
          final bool showCover = coverImage != null && !folder.isLocked;
          final double coverHeight =
              showCover && !isListLayout ? constraints.maxHeight / 2 : 0.0;
          final double coverWidth =
              showCover && isListLayout ? constraints.maxWidth / 3 : 0.0;
          return Stack(
            children: <Widget>[
              if (showCover)
                Positioned(
                  top: 0.0,
                  left: 0.0,
                  right: isListLayout ? null : 0.0,
                  bottom: isListLayout ? 0.0 : null,
                  width: isListLayout ? coverWidth : null,
                  height: isListLayout ? null : coverHeight,
                  child: CoverImage(name: coverImage!),
                ),
          // Markers sit after the cover, never on top of it: below it in the
          // grid, just to its right in the list.
          if (folder.important)
            Positioned(
              // Glued to the cover's bottom edge in the grid.
              top: showCover && !isListLayout ? coverHeight - 2.0 : -4.0,
              right: 4.0,
              child: Icon(
                Icons.bookmark,
                size: 16.0,
                color: tanoAmber.withValues(alpha: 0.8),
              ),
            ),
          if (folder.isPinned)
            Positioned(
              top: showCover && !isListLayout ? coverHeight + 2.0 : 2.0,
              left: showCover && isListLayout ? coverWidth + 4.0 : 2.0,
              child: Icon(
                Icons.push_pin,
                size: 14.0,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
          if (isListLayout)
            InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: EdgeInsets.only(left: coverWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 6.0),
                  child: _buildList(textColor, bgColor, showCover),
                ),
              ),
            )
          else
            Positioned.fill(
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(
                  padding: EdgeInsets.only(top: coverHeight),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 6.0),
                    child: _buildGrid(textColor, bgColor, showCover),
                  ),
                ),
              ),
            ),
          if (isInSelectionMode)
            Positioned.fill(
              child: GestureDetector(
                onTap: onSelectionToggle,
                child: Container(
                  color: isSelected ? Colors.black38 : Colors.black12,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _selectionIcon(isDark),
                    ),
                  ),
                ),
              ),
            ),
            ],
          );
        },
      ),
    );
  }

  /// Selection indicator. A locked folder cannot be selected, so it shows no
  /// circle at all.
  Widget _selectionIcon(bool isDark) {
    if (folder.isLocked) return const SizedBox.shrink();
    final Color color = isDark ? TanoStates.action.dark : tanoTeal;
    if (!isSelected) {
      return Icon(Icons.panorama_fish_eye, size: 24.0, color: color);
    }
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        const SizedBox(
          width: 18.0,
          height: 18.0,
          child: CircleAvatar(backgroundColor: Colors.white, radius: 100.0),
        ),
        Icon(Icons.check_circle, size: 24.0, color: color),
      ],
    );
  }

  /// Empty folder row: the 32px glyph plus the card's 14px vertical padding.
  static const double _emptyRowHeight = 46.0;

  /// List rows are kept at least 1.5x the empty height.
  static const double _listRowMinHeight = _emptyRowHeight * 1.5 - 14.0;

  /// A cover puts the icon above the text, so the row needs a bit more.
  static const double _listMinHeightWithCover = _listRowMinHeight + 16.0;

  Widget _buildGrid(Color textColor, Color bgColor, bool hasCover) {
    // Fill the whole card so every area (not just the text) stays tappable.
    //
    // With a cover the content only gets the lower half: the folder glyph is
    // dropped and the name is limited to two lines, so the name and the
    // metadata never overflow.
    if (hasCover) {
      return SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              folder.name,
              maxLines: 2,
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
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _folderIcon(textColor, bgColor),
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

  Widget _buildList(Color textColor, Color bgColor, bool hasCover) {
    final TextStyle nameStyle = TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.bold,
      color: textColor,
    );
    // Keep every folder row at least 1.5x the height of an empty one, and a
    // little more when a cover pushes the icon above the text.
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: hasCover ? _listMinHeightWithCover : _listRowMinHeight,
      ),
      child: hasCover
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Kept clear of the pin, which sits at the top of the row.
                const SizedBox(height: 10.0),
                _folderIcon(textColor, bgColor),
                const SizedBox(height: 6.0),
                Text(
                  folder.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: nameStyle,
                ),
                _metadata(textColor),
              ],
            )
          : Row(
              children: <Widget>[
                _folderIcon(textColor, bgColor),
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
                        style: nameStyle,
                      ),
                      _metadata(textColor),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// The folder glyph: a slightly larger open folder, or a closed folder
  /// with a small lock inside it when the folder is locked.
  Widget _folderIcon(Color textColor, Color bgColor) {
    if (!folder.isLocked) {
      return Icon(Icons.folder_open, size: 24.0, color: textColor);
    }
    return SizedBox(
      width: 24.0,
      height: 24.0,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(Icons.folder, size: 24.0, color: textColor),
          // The lock sits inside the folder, a bit to the right.
          Transform.translate(
            offset: const Offset(0.5, 0.5),
            child: Icon(Icons.key, size: 16.0, color: bgColor),
          ),
        ],
      ),
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
          Text(
            'x$noteCount',
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
