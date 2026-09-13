import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Body of a note card in the grid layout.
///
/// Shared by the home page and the folder page so both render exactly the
/// same card (date shifted when pinned, markdown content, counts at the
/// bottom).
Widget buildNoteGridContent({
  required Note note,
  required Color textColor,
  required Set<String> activeNoteIds,
}) {
  final bool hasCover = note.coverImage != null && !note.isLocked;
  return Container(
    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // The metadata is glued to the bottom of the card whatever the
        // content above it.
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4.0,
            children: <Widget>[
              Padding(
                padding: note.isPinned
                    ? const EdgeInsets.only(left: 8.0)
                    : const EdgeInsets.only(left: 0.0),
                child: Text(
                  formatNoteDate(note.date),
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    fontSize: 8.0,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasCover)
                // With a cover the title shares the lower half with the
                // metadata.
                Flexible(
                  child: Text(
                    note.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11.0,
                      color: textColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                Text(
                  note.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0,
                    color: textColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              if (!hasCover)
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: RichText(
                      text: LinkTextEditingController.buildMarkdownTextSpan(
                        note.content,
                        TextStyle(
                          fontSize: 10.0,
                          color: textColor.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                        tanoAmber,
                        activeNoteIds,
                      ),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
            ],
          ),
        ),
        NoteCounts(
          content: note.content,
          color: textColor.withValues(alpha: 0.6),
          attachmentCount: note.attachments.length,
        ),
      ],
    ),
  );
}

/// Body of a note card in the list layout.
Widget buildNoteListContent({
  required Note note,
  required Color textColor,
  required Set<String> activeNoteIds,
}) {
  return ListTile(
    title: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(
            note.title,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 9.0),
        Text(
          formatNoteDate(note.date),
          style: TextStyle(
            fontSize: 9.0,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RichText(
          maxLines: 3,
          overflow: TextOverflow.clip,
          text: LinkTextEditingController.buildMarkdownTextSpan(
            note.content,
            TextStyle(
              fontSize: 12.0,
              color: textColor.withValues(alpha: 0.8),
              height: 1.4,
            ),
            tanoAmber,
            activeNoteIds,
          ),
        ),
        NoteCounts(
          content: note.content,
          color: textColor.withValues(alpha: 0.6),
          attachmentCount: note.attachments.length,
        ),
      ],
    ),
  );
}
