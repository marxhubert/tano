import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';

/// Builds one note card with the wiring every screen shares.
///
/// Home, Folder and the trash all showed the same field mapping (title, date,
/// cover, important, lock) and the same "select unless open" tap rule, but with
/// different selection sources. Those stay parameters; the card configuration
/// itself lives here so a change reaches every screen.
Widget buildNoteCard({
  required Note note,
  required bool isList,
  required bool isSelected,
  required bool isInSelectionMode,
  required Set<String> activeNoteIds,
  required VoidCallback onOpen,
  required VoidCallback onToggleSelection,
  required VoidCallback onEnterSelection,
  String? dateText,
  IconData? dateIcon,
}) {
  return EntityCard(
    kind: note.kind,
    category: note.category,
    title: note.title,
    subtitle: dateText ?? formatNoteDate(note.date),
    coverImage: note.coverImage,
    isImportant: note.important,
    isLocked: note.isLocked,
    isListLayout: isList,
    isSelected: isSelected,
    isInSelectionMode: isInSelectionMode,
    onSelectionToggle: onToggleSelection,
    onLongPress: onEnterSelection,
    onTap: () => isInSelectionMode ? onToggleSelection() : onOpen(),
    builder: (BuildContext context, Color textColor, bool hasCover) => isList
        ? buildNoteListContent(
            note: note,
            textColor: textColor,
            activeNoteIds: activeNoteIds,
            hasCover: hasCover,
            dateText: dateText,
            dateIcon: dateIcon,
          )
        : buildNoteGridContent(
            note: note,
            textColor: textColor,
            activeNoteIds: activeNoteIds,
            hasCover: hasCover,
            dateText: dateText,
            dateIcon: dateIcon,
          ),
  );
}
