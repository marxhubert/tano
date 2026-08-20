import 'package:flutter/material.dart';

import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/menu.dart';

/// Grid of note cards, one card per note.
class NoteGridView extends StatelessWidget {
  const NoteGridView({
    super.key,
    required this.viewModel,
    required this.onOpenNote,
  });

  final HomeViewModel viewModel;
  final void Function(int index, Note note) onOpenNote;

  @override
  Widget build(BuildContext context) {
    final List<Note> notes = viewModel.notes;

    return GridView.count(
      crossAxisCount: 3,
      padding: EdgeInsets.all(12.0),
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      children: List.generate(notes.length, (index) {
        final String title = notes[index].title;
        final String content = notes[index].content;
        final String date = formatNoteDate(notes[index].date);
        final bool isSelected = viewModel.selected.contains(index);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: themeCategory(
              notes[index].category,
              false,
              brightness: Theme.of(context).brightness,
            ),
            borderRadius: BorderRadius.circular(12.0),
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
              InkWell(
                child: Container(
                  color: themeCategory(
                    notes[index].category,
                    true,
                    brightness: Theme.of(context).brightness,
                  ),
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4.0,
                      children: <Widget>[
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.0,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            content,
                            style: TextStyle(fontSize: 10.8),
                            overflow: TextOverflow.clip,
                            maxLines: null,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 9.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                onTap: () {
                  if (viewModel.isInSelectionMode) {
                    viewModel.toggleSelection(index);
                  } else {
                    onOpenNote(index, notes[index]);
                  }
                },
                onLongPress: () {
                  viewModel.enterSelectionMode(index);
                },
              ),
              viewModel.isInSelectionMode
                  ? GestureDetector(
                      child: Container(
                        color: isSelected ? Colors.black38 : Colors.black12,
                        child: isSelected
                            ? Stack(
                                children: <Widget>[
                                  Center(
                                    child: SizedBox(
                                      width: 36.0,
                                      height: 36.0,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        radius: 100.0,
                                        child: null,
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 45.0,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Icon(
                                  Icons.panorama_fish_eye,
                                  size: 45.0,
                                  color: Colors.black54,
                                ),
                              ),
                      ),
                      onTap: () {
                        viewModel.toggleSelection(index);
                      },
                    )
                  : Offstage(),
            ],
          ),
        );
      }),
    );
  }
}
