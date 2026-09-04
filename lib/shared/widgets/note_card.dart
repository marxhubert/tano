import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
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
  });

  final Note note;
  final NoteCardContentBuilder builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isInSelectionMode;
  final VoidCallback? onSelectionToggle;

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
      child: Stack(
        children: <Widget>[
          // Pinned indicator
          if (note.isPinned)
            Positioned(
              top: 2.0,
              left: 2.0,
              child: Icon(
                Icons.push_pin,
                size: 14.0,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),

          // The visual "Important" bookmark behind the content
          if (note.important)
            Positioned(
              top: -4.0,
              right: 4.0,
              child: Icon(
                Icons.bookmark,
                size: 16.0,
                color: tanoAmber.withValues(alpha: 0.8),
              ),
            ),

          // Actual Note Content
          InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: builder(context, textColor),
          ),

          // Selection Overlay
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
      ),
    );
  }
}

/// Small muted row showing how many checklists and note links a note
/// contains (done_all / sticky_note_2 + xN), as on the editor info line.
class NoteCounts extends StatelessWidget {
  const NoteCounts({
    super.key,
    required this.content,
    required this.color,
  });

  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int checklists = checklistCount(content);
    final int links = linkCountIn(content);
    if (checklists == 0 && links == 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (checklists > 0) ...<Widget>[
          Icon(Icons.done_all, size: 11.0, color: color),
          const SizedBox(width: 2.0),
          Text('x$checklists',
              style: TextStyle(fontSize: 9.0, color: color)),
        ],
        if (checklists > 0 && links > 0) const SizedBox(width: 8.0),
        if (links > 0) ...<Widget>[
          Icon(Icons.sticky_note_2, size: 11.0, color: color),
          const SizedBox(width: 2.0),
          Text('x$links', style: TextStyle(fontSize: 9.0, color: color)),
        ],
      ],
    );
  }
}
