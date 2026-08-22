import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/note_card.dart';
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
      crossAxisCount: 3,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
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
          builder: (context, textColor) => Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4.0,
              children: <Widget>[
                Text(
                  note.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11.0,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    note.content,
                    style: TextStyle(
                      fontSize: 10.0,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    overflow: TextOverflow.clip,
                    maxLines: null,
                  ),
                ),
                Text(
                  formatNoteDate(note.date),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8.0,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
