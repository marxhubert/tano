import 'package:flutter/material.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';
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
    final List<Note> notes = viewModel.notes;
    return SliverList.separated(
      itemCount: notes.length,
      itemBuilder: (BuildContext context, int index) {
        final Note note = notes[index];
        final bool isSelected = viewModel.selected.contains(note.id);

        return Dismissible(
          key: Key(note.id),
          background: _DismissibleBackground(
            color: tanoAmber,
            alignment: Alignment.centerLeft,
            icon: note.important ? Icons.bookmark_border : Icons.bookmark,
          ),
          secondaryBackground: const _DismissibleBackground(
            color: Colors.red,
            alignment: Alignment.centerRight,
            icon: Icons.delete_forever,
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              viewModel.toggleFavorite(note.id);
              return false;
            }
            return await confirmDelete();
          },
          onDismissed: (direction) {
            viewModel.removeNote(note.id);
            onShowUndoSnackBar();
          },
          child: NoteCard(
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
            builder: (context, textColor) => ListTile(
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
              subtitle: RichText(
                maxLines: 3,
                overflow: TextOverflow.clip,
                text: LinkTextEditingController.buildLinkTextSpan(
                  note.content,
                  TextStyle(
                    fontSize: 12.0,
                    color: textColor.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                  tanoAmber,
                ),
              ),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
    );
  }
}

class _DismissibleBackground extends StatelessWidget {
  const _DismissibleBackground({
    required this.color,
    required this.alignment,
    required this.icon,
  });

  final Color color;
  final Alignment alignment;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 21.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(appBorderRadius),
      ),
      child: Icon(icon, color: Colors.white, size: 27.0),
    );
  }
}
