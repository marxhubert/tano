import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/cover_image.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';
import 'package:tano/shared/widgets/theme.dart';

typedef NoteCardContentBuilder = Widget Function(
    BuildContext context, Color textColor);

/// A shared container for notes used in both List and Grid views.
/// Handles background color, borders, shadows, and the "Important" indicator.
class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    required this.note,
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isInSelectionMode = false,
    this.onSelectionToggle,
    this.isListLayout = false,
    this.coverImage,
  });

  final Note note;
  final NoteCardContentBuilder builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isInSelectionMode;
  final VoidCallback? onSelectionToggle;

  /// Whether the card sits in the list layout. Only the locked placeholder
  /// differs: a list row keeps two title lines, left aligned, while a grid
  /// tile centers up to three.
  final bool isListLayout;

  /// Stored cover image name, drawn as a background. A locked note never
  /// shows its cover.
  final String? coverImage;

  static Widget _lockedIcon(Color textColor) {
    return Icon(
      Icons.lock_outline,
      size: 20.0,
      color: textColor.withValues(alpha: 0.6),
    );
  }

  static Widget _lockedTitle(
    Note note,
    Color textColor, {
    required TextAlign align,
    required int maxLines,
  }) {
    return Text(
      note.title.isEmpty ? AppText.tr('no_title') : note.title,
      textAlign: align,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  static Widget _lockedDate(Note note, Color textColor) {
    return Text(
      formatNoteDate(note.date),
      style: TextStyle(
        fontSize: 9.0,
        color: textColor.withValues(alpha: 0.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = themeCategory(
      note.category,
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
          // third in the list. The content keeps its place, just shifted.
          final bool showCover = coverImage != null && !note.isLocked;
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
          if (note.isPinned)
            Positioned(
              top: showCover && !isListLayout ? coverHeight + 2.0 : 2.0,
              left: showCover && isListLayout ? coverWidth + 4.0 : 2.0,
              child: Icon(
                Icons.push_pin,
                size: 14.0,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),

          if (note.important)
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

          // Actual Note Content, shifted to leave room for the cover. A list
          // row is sized by its content; a grid tile fills its cell so the
          // whole cover stays tappable.
          if (isListLayout)
            InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: EdgeInsets.only(left: coverWidth),
                child: builder(context, textColor),
              ),
            )
          else
            Positioned.fill(
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(
                  padding: EdgeInsets.only(top: coverHeight),
                  child: builder(context, textColor),
                ),
              ),
            ),

          // A locked note shows nothing but its lock, title and date.
          if (note.isLocked)
            Positioned.fill(
              child: GestureDetector(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Container(
                  color: bgColor,
                  child: isListLayout
                      // List: lock on the left, title and date stacked right.
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Row(
                              children: <Widget>[
                                _lockedIcon(textColor),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      _lockedTitle(
                                        note,
                                        textColor,
                                        align: TextAlign.start,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 2.0),
                                      _lockedDate(note, textColor),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      // Grid: everything centered in the tile.
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                _lockedIcon(textColor),
                                const SizedBox(height: 6.0),
                                _lockedTitle(
                                  note,
                                  textColor,
                                  align: TextAlign.center,
                                  maxLines: 3,
                                ),
                                const SizedBox(height: 2.0),
                                _lockedDate(note, textColor),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),

          // Selection Overlay
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
                      child: isSelected
                          ? Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                const SizedBox(
                                  width: 18.0,
                                  height: 18.0,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 100.0,
                                  ),
                                ),
                                Icon(
                                  Icons.check_circle,
                                  size: 24.0,
                                  color: isDark
                                      ? TanoStates.action.dark
                                      : tanoTeal,
                                ),
                              ],
                            )
                          : Icon(
                              Icons.panorama_fish_eye,
                              size: 24.0,
                              color: isDark
                                  ? TanoStates.action.dark
                                  : tanoTeal.withValues(alpha: 0.6),
                            ),
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
}

/// Small muted row showing how many checklists, note links and attachments
/// a note contains (done_all / sticky_note_2 / attachment + xN), as on the
/// editor info line.
class NoteCounts extends StatelessWidget {
  const NoteCounts({
    super.key,
    required this.content,
    required this.color,
    this.attachmentCount = 0,
  });

  final String content;
  final Color color;
  final int attachmentCount;

  @override
  Widget build(BuildContext context) {
    final int checklists = checklistCount(content);
    final int links = linkCountIn(content);
    if (checklists == 0 && links == 0 && attachmentCount == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (checklists > 0) ...<Widget>[
            Icon(Icons.done_all, size: 11.0, color: color),
            const SizedBox(width: 1.0),
            Text('x$checklists',
                style: TextStyle(fontSize: 9.0, color: color)),
          ],
          if (checklists > 0 && links > 0) const SizedBox(width: 4.0),
          if (links > 0) ...<Widget>[
            Icon(Icons.sticky_note_2, size: 11.0, color: color),
            const SizedBox(width: 1.0),
            Text('x$links', style: TextStyle(fontSize: 9.0, color: color)),
          ],
          if ((checklists > 0 || links > 0) && attachmentCount > 0)
            const SizedBox(width: 4.0),
          if (attachmentCount > 0) ...<Widget>[
            Icon(Icons.attachment, size: 11.0, color: color),
            const SizedBox(width: 1.0),
            Text('x$attachmentCount',
                style: TextStyle(fontSize: 9.0, color: color)),
          ],
        ],
      ),
    );
  }
}
