import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/shared/widgets/card_typography.dart';

/// Folder grid body: the name on top, the metadata at the bottom.
Widget buildFolderGridContent({
  required Folder folder,
  required int noteCount,
  required Color textColor,
  required bool hasCover,
}) {
  return Padding(
    // Grid padding 8, gap under a cover 4, metadata 4 from the bottom.
    padding: EdgeInsets.fromLTRB(8.0, hasCover ? 4.0 : 8.0, 8.0, 4.0),
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
          buildFolderMetadata(textColor, noteCount),
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
    padding: const EdgeInsets.all(12.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          folder.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: cardTitleStyle(textColor),
        ),
        buildFolderMetadata(textColor, noteCount),
      ],
    ),
  );
}

/// Folder metadata: a note-count glyph and value.
Widget buildFolderMetadata(
  Color textColor,
  int noteCount,
) {
  final Color color = textColor.withValues(alpha: 0.6);
  return Padding(
    padding: const EdgeInsets.only(top: 2.0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Symbols.sticky_note_2, size: cardMetaIconSize, color: color),
        Text('x$noteCount',
            style: TextStyle(fontSize: cardMetaSize, color: color)),
      ],
    ),
  );
}
