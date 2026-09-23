import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/shared/widgets/card_typography.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Folder grid body: the name on top, the metadata at the bottom.
Widget buildFolderGridContent({
  required Folder folder,
  required int noteCount,
  required Color textColor,
  required bool hasCover,
}) {
  return Padding(
    // The same paper margins as note and task cards.
    padding: EdgeInsets.fromLTRB(
      appPaddingMedium,
      hasCover ? 8.0 : appPaddingMedium,
      appPaddingMedium,
      8.0,
    ),
    child: SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            folder.name,
            maxLines: hasCover ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: cardTitleStyle(textColor),
          ),
          const Spacer(),
          buildFolderMetadata(
            textColor,
            noteCount,
            isImportant: folder.important,
          ),
        ],
      ),
    ),
  );
}

/// Folder list body: name and metadata form one block, centred vertically and
/// left aligned (like the locked list template). The folder is the exception
/// that keeps two title lines even with a cover.
Widget buildFolderListContent({
  required Folder folder,
  required int noteCount,
  required Color textColor,
  required bool hasCover,
}) {
  return Padding(
    padding: const EdgeInsets.all(appPaddingMedium),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      // The name yields to the metadata rather than overflowing a short card.
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Flexible(
          child: Text(
            folder.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: cardTitleStyle(textColor),
          ),
        ),
        buildFolderMetadata(
          textColor,
          noteCount,
          isImportant: folder.important,
        ),
      ],
    ),
  );
}

/// Folder metadata: the bookmark marker (filled amber) when the folder is a
/// favourite, then the note-count glyph and value. An empty, unbookmarked
/// folder shows nothing at all rather than an "x0".
Widget buildFolderMetadata(
  Color textColor,
  int noteCount, {
  bool isImportant = false,
}) {
  if (noteCount == 0 && !isImportant) return const SizedBox.shrink();
  final Color color = cardMutedColor(textColor);
  return Padding(
    padding: const EdgeInsets.only(top: 2.0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // The bookmark always comes first in the metadata.
        if (isImportant) ...<Widget>[
          const Icon(
            Symbols.bookmark,
            size: cardMetaIconSize,
            fill: 1.0,
            color: tanoAmber,
          ),
          if (noteCount > 0) const SizedBox(width: 4.0),
        ],
        if (noteCount > 0) ...<Widget>[
          Icon(Symbols.sticky_note_2, size: cardMetaIconSize, color: color),
          const SizedBox(width: 1.0),
          Text('x$noteCount', style: cardMetaStyle(color)),
        ],
      ],
    ),
  );
}
