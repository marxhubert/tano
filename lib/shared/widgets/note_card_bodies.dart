import 'package:tano/core/models/task.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/card_typography.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Note grid body. The excerpt takes the space left by the date and the title,
/// and shrinks when there is less of it (no excerpt with a cover, where the
/// lower half holds the title only).
Widget buildNoteGridContent({
  required Note note,
  required Color textColor,
  required Set<String> activeNoteIds,
  required bool hasCover,
  String? dateText,
  IconData? dateIcon,
}) {
  final Widget title = Text(
    note.title,
    maxLines: hasCover ? 2 : 3,
    overflow: TextOverflow.ellipsis,
    style: cardTitleStyle(textColor),
  );
  return Container(
    // Keep the title, excerpt and metadata on one paper margin.
    padding: EdgeInsets.fromLTRB(
      appPaddingMedium,
      hasCover ? 8.0 : appPaddingMedium,
      appPaddingMedium,
      8.0,
    ),
    child: Column(
      // Metadata always left-aligned, body top-aligned.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.0,
            children: <Widget>[
              _noteDate(
                note,
                textColor,
                dateText: dateText,
                dateIcon: dateIcon,
              ),
              if (hasCover) Flexible(child: title) else title,
              if (!hasCover)
                Expanded(
                  child: _noteExcerpt(
                    content: note.isTask
                        ? TaskContent.preview(note.content)
                        : note.content,
                    textColor: textColor,
                    activeNoteIds: activeNoteIds,
                    isTask: note.isTask,
                  ),
                ),
            ],
          ),
        ),
        NoteCounts(
          content: note.content,
          description: note.isTask ? note.description : '',
          color: cardMutedColor(textColor),
          attachmentCount: note.attachments.length,
          taskCount: note.isTask
              ? TaskContent.savedItems(note.content).length
              : null,
          isImportant: note.important,
        ),
      ],
    ),
  );
}

/// Note list body. The excerpt fills the remaining height and ends on a full
/// line when the title leaves it little room.
Widget buildNoteListContent({
  required Note note,
  required Color textColor,
  required Set<String> activeNoteIds,
  required bool hasCover,
  String? dateText,
  IconData? dateIcon,
}) {
  return Padding(
    // Match the grid card's horizontal paper margin.
    padding: const EdgeInsets.fromLTRB(
      appPaddingMedium,
      appPaddingMedium,
      appPaddingMedium,
      8.0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                note.title,
                maxLines: hasCover ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: cardTitleStyle(textColor),
              ),
            ),
            const SizedBox(width: 9.0),
            _noteDate(
              note,
              textColor,
              dateText: dateText,
              dateIcon: dateIcon,
            ),
          ],
        ),
        const SizedBox(height: 4.0),
        Expanded(
          // A checklist keeps its preview even under a cover: the list leaves
          // it the room a coverless row has.
          child: _noteExcerpt(
            content: note.isTask
                ? TaskContent.preview(note.content)
                : note.content,
            textColor: textColor,
            activeNoteIds: activeNoteIds,
            isTask: note.isTask,
          ),
        ),
        NoteCounts(
          content: note.content,
          description: note.isTask ? note.description : '',
          color: cardMutedColor(textColor),
          attachmentCount: note.attachments.length,
          taskCount: note.isTask
              ? TaskContent.savedItems(note.content).length
              : null,
          isImportant: note.important,
        ),
      ],
    ),
  );
}

/// The card's date line. The archive passes its own text and a leading glyph,
/// so an archived document shows when it was archived.
Widget _noteDate(
  Note note,
  Color textColor, {
  String? dateText,
  IconData? dateIcon,
}) {
  final String text = dateText ?? formatNoteDate(note.date);
  if (dateIcon == null) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: cardDateStyle(textColor),
    );
  }
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Icon(dateIcon, size: cardMetaIconSize, color: cardMutedColor(textColor)),
      const SizedBox(width: 3.0),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: cardDateStyle(textColor),
        ),
      ),
    ],
  );
}

/// Excerpt that fills the remaining height. Its line count is computed from
/// that height so the text always ends on a full line with an ellipsis,
/// instead of being clipped in the middle of one.
Widget _noteExcerpt({
  required String content,
  required Color textColor,
  required Set<String> activeNoteIds,
  bool isTask = false,
}) {
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double lineHeight = cardContentSize * cardContentLineHeight;
      final int fit = (constraints.maxHeight / lineHeight).floor();
      if (fit < 1) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.topLeft,
        child: RichText(
          maxLines: fit,
          overflow: TextOverflow.ellipsis,
          text: LinkTextEditingController.buildMarkdownTextSpan(
            content,
            cardContentStyle(
              textColor,
              fontFamily: isTask
                  ? Theme.of(context).textTheme.bodyMedium?.fontFamily
                  : 'TanoSerif',
            ),
            accentColor(context),
            activeNoteIds,
            checklistIndent: isTask ? 0 : 16,
          ),
        ),
      );
    },
  );
}

/// Small muted row showing, in order, the bookmark marker, then how many
/// checklists, note links and attachments a note contains (Symbols + xN).
class NoteCounts extends StatelessWidget {
  const NoteCounts({
    super.key,
    required this.content,
    required this.color,
    this.attachmentCount = 0,
    this.description = '',
    this.taskCount,
    this.isImportant = false,
  });

  final String content;
  final String description;
  final Color color;
  final int attachmentCount;
  final int? taskCount;

  /// Whether the note is bookmarked: shows the amber marker first.
  final bool isImportant;

  @override
  Widget build(BuildContext context) {
    final int checklists = taskCount ?? checklistCount(content);
    final int links = linkCountIn(content) + linkCountIn(description);
    final bool hasCounts = checklists > 0 || links > 0 || attachmentCount > 0;
    if (!hasCounts && !isImportant) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 0.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // The bookmark always comes first in the metadata.
          if (isImportant) ...<Widget>[
            const Icon(
              Symbols.bookmark,
              // A touch larger than the counts beside it.
              size: cardMetaIconSize + 3.0,
              fill: 1.0,
              color: tanoAmber,
            ),
            if (hasCounts) const SizedBox(width: 4.0),
          ],
          if (checklists > 0) ...<Widget>[
            Icon(Symbols.check_box, size: cardMetaIconSize, color: color),
            const SizedBox(width: 1.0),
            Text('x$checklists', style: cardMetaStyle(color)),
          ],
          if (checklists > 0 && links > 0) const SizedBox(width: 4.0),
          if (links > 0) ...<Widget>[
            Icon(Symbols.sticky_note_2, size: cardMetaIconSize, color: color),
            const SizedBox(width: 1.0),
            Text('x$links', style: cardMetaStyle(color)),
          ],
          if ((checklists > 0 || links > 0) && attachmentCount > 0)
            const SizedBox(width: 4.0),
          if (attachmentCount > 0) ...<Widget>[
            Icon(Symbols.attachment, size: cardMetaIconSize, color: color),
            const SizedBox(width: 1.0),
            Text('x$attachmentCount', style: cardMetaStyle(color)),
          ],
        ],
      ),
    );
  }
}
