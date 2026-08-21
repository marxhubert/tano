import 'package:flutter/material.dart';

import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/menu.dart';
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
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final Color bgColor = themeCategory(
          notes[index].category,
          true,
          brightness: Theme.of(context).brightness,
        );
        final Color borderColor = getBorderColor(bgColor, isDark: isDark);
        final Color textColor = getTextColor(bgColor);

        final bool alreadySelected = viewModel.selected.contains(
          notes[index].id,
        );
        final String title = notes[index].title;
        final String date = formatNoteDate(notes[index].date);
        final bool important = notes[index].important;
        return Dismissible(
          key: Key(notes[index].id),
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 21.0),
            decoration: const BoxDecoration(
              color: tanoAmber,
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: Icon(
              important ? Icons.bookmark_border : Icons.bookmark,
              color: Colors.white,
              size: 27.0,
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 21.0),
            decoration: const BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
            ),
            child: Icon(
              Icons.delete_forever,
              color: Colors.blueGrey.shade50,
              size: 27.0,
            ),
          ),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: borderColor, width: 0.5),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 2.0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                if (important)
                  Positioned(
                    top: -4.0,
                    right: 2.0,
                    child: Icon(
                      Icons.bookmark,
                      size: 16.0,
                      color: tanoAmber.withValues(alpha: 0.8),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    if (viewModel.isInSelectionMode) {
                      viewModel.toggleSelection(notes[index].id);
                    } else {
                      onOpenNote(notes[index]);
                    }
                  },
                  onLongPress: () {
                    viewModel.enterSelectionMode(notes[index].id);
                  },
                  child: ListTile(
                    title: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 9.0),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 9.0,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      notes[index].content,
                      maxLines: 3,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontSize: 12.0,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
                if (viewModel.isInSelectionMode)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {
                        viewModel.toggleSelection(notes[index].id);
                      },
                      child: Container(
                        color: alreadySelected ? Colors.black38 : Colors.black12,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: alreadySelected
                                ? Stack(
                                    alignment: Alignment.center,
                                    children: <Widget>[
                                      SizedBox(
                                        width: 18.0,
                                        height: 18.0,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.white,
                                          radius: 100.0,
                                          child: null,
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle,
                                        size: 24.0,
                                        color: isDark ? TanoStates.action.dark : tanoTeal,
                                      ),
                                    ],
                                  )
                                : Icon(
                                    Icons.panorama_fish_eye,
                                    size: 24.0,
                                    color: isDark
                                        ? TanoStates.action.dark
                                        : tanoTeal.withValues(alpha: 0.6),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              viewModel.toggleFavorite(notes[index].id);
              return false;
            }
            return await confirmDelete();
          },
          onDismissed: (direction) {
            viewModel.removeNote(notes[index].id);
            onShowUndoSnackBar();
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return SizedBox(height: 12.0);
      },
    );
  }
}
