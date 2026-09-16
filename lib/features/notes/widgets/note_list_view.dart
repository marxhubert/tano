import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';
import 'package:tano/shared/widgets/theme.dart';

/// List of note rows with swipe-to-favorite and swipe-to-delete.
class NoteListView extends StatelessWidget {
  const NoteListView({
    super.key,
    required this.viewModel,
    required this.onOpenNote,
    required this.onShowUndoSnackBar,
    required this.confirmDelete,
  });

  final HomeViewModel viewModel;
  final void Function(Note note) onOpenNote;
  final VoidCallback onShowUndoSnackBar;
  final Future<bool?> Function() confirmDelete;

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
    return Dismissible(
      key: Key(note.id),
      background: _DismissibleBackground(
        color: tanoAmber,
        alignment: Alignment.centerLeft,
        icon: Symbols.label_important,
        // Full while the note is not important yet: the swipe adds the
        // bookmark, so the target state is the filled one.
        fill: note.important ? 0.0 : 1.0,
      ),
      secondaryBackground: const _DismissibleBackground(
        color: Colors.red,
        alignment: Alignment.centerRight,
        icon: Symbols.delete_forever,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          viewModel.toggleFavorite(note.id);
          return false;
        }
        if (note.isLocked) {
          showAdaptiveNotice(context, AppText.tr('delete_locked_error'));
          return false;
        }
        return await confirmDelete();
      },
      onDismissed: (direction) {
        viewModel.removeNote(note.id);
        onShowUndoSnackBar();
      },
      child: EntityCard(
        kind: EntityKind.note,
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
      ),
    );
  }
}

class _DismissibleBackground extends StatelessWidget {
  const _DismissibleBackground({
    required this.color,
    required this.alignment,
    required this.icon,
    this.fill = 0.0,
  });

  final Color color;
  final Alignment alignment;
  final IconData icon;

  /// Variable-font fill of the glyph (1.0 for the filled variant).
  final double fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 21.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(appBorderRadius),
      ),
      child: Icon(icon, color: Colors.white, size: 27.0, fill: fill),
    );
  }
}
