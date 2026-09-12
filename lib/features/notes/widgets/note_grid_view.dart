import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/note_card_content.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Grid of note cards, one card per note.
class NoteGridView extends StatelessWidget {
  const NoteGridView({
    super.key,
    required this.viewModel,
    required this.onOpenNote,
  });

  final HomeViewModel viewModel;
  final void Function(Note note) onOpenNote;

  @override
  Widget build(BuildContext context) {
    final List<Note> notes = viewModel.notes;

    return SliverGrid.count(
      crossAxisCount: gridCrossAxisCount(context),
      crossAxisSpacing: 8.0,
      mainAxisSpacing: 8.0,
      childAspectRatio: 0.9,
      children: List.generate(notes.length, (index) {
        final Note note = notes[index];
        final bool isSelected = viewModel.selected.contains(note.id);

        return NoteCard(
          note: note,
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
          builder: (context, textColor) => buildNoteGridContent(
            note: note,
            textColor: textColor,
            activeNoteIds: viewModel.activeNoteIds,
          ),
        );
      }),
    );
  }
}
