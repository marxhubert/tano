import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';

/// Notes as a grid or a list of cards.
///
/// The two layouts differ only in the sliver flag, the card's list flag and the
/// body builder. Keeping them in one widget makes every shared behaviour —
/// selection, cover, metadata, tap/long-press — land on both at once.
class NoteCards extends StatelessWidget {
  const NoteCards({
    super.key,
    required this.viewModel,
    required this.isList,
    required this.onOpenNote,
  });

  final HomeViewModel viewModel;

  /// True for one card per row; false for the almost-square grid.
  final bool isList;

  final void Function(Note note) onOpenNote;

  @override
  Widget build(BuildContext context) {
    return EntitySliver<Note>(
      items: viewModel.notes,
      isList: isList,
      cardBuilder: (BuildContext context, Note note) => _card(note),
    );
  }

  Widget _card(Note note) {
    return EntityCard(
      kind: note.kind,
      category: note.category,
      title: note.title,
      subtitle: formatNoteDate(note.date),
      coverImage: note.coverImage,
      isImportant: note.important,
      isLocked: note.isLocked,
      isListLayout: isList,
      isSelected: viewModel.selected.contains(note.id),
      isInSelectionMode: viewModel.isInSelectionMode,
      onTap: () {
        if (viewModel.isInSelectionMode) {
          viewModel.toggleSelection(note.id);
        } else {
          onOpenNote(note);
        }
      },
      onLongPress: () => viewModel.enterSelectionMode(note.id),
      onSelectionToggle: () => viewModel.toggleSelection(note.id),
      builder: (context, textColor, hasCover) => isList
          ? buildNoteListContent(
              note: note,
              textColor: textColor,
              activeNoteIds: viewModel.activeNoteIds,
              hasCover: hasCover,
            )
          : buildNoteGridContent(
              note: note,
              textColor: textColor,
              activeNoteIds: viewModel.activeNoteIds,
              hasCover: hasCover,
            ),
    );
  }
}
