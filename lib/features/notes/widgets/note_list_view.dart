import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';

/// Note rows use the same selection and action menus as the grid.
class NoteListView extends StatelessWidget {
  const NoteListView({
    super.key,
    required this.viewModel,
    required this.onOpenNote,
  });

  final HomeViewModel viewModel;
  final void Function(Note note) onOpenNote;

  @override
  Widget build(BuildContext context) {
    return EntitySliver<Note>(
      items: viewModel.notes,
      isList: true,
      cardBuilder: (BuildContext context, Note note) => _row(context, note),
    );
  }

  Widget _row(BuildContext context, Note note) {
    final bool isSelected = viewModel.selected.contains(note.id);
    return EntityCard(
      kind: note.kind,
      category: note.category,
      title: note.title,
      subtitle: formatNoteDate(note.date),
      coverImage: note.coverImage,
      isImportant: note.important,
      isLocked: note.isLocked,
      isListLayout: true,
      isSelected: isSelected,
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
      builder: (context, textColor, hasCover) => buildNoteListContent(
        note: note,
        textColor: textColor,
        activeNoteIds: viewModel.activeNoteIds,
        hasCover: hasCover,
      ),
    );
  }
}
