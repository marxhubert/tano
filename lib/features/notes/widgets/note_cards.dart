import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/note_card.dart';

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

  Widget _card(Note note) => buildNoteCard(
    note: note,
    isList: isList,
    isSelected: viewModel.selected.contains(note.id),
    isInSelectionMode: viewModel.isInSelectionMode,
    activeNoteIds: viewModel.activeNoteIds,
    onOpen: () => onOpenNote(note),
    onToggleSelection: () => viewModel.toggleSelection(note.id),
    onEnterSelection: () => viewModel.enterSelectionMode(note.id),
  );
}
