import 'package:flutter/material.dart';
import 'package:tano/features/editor/edit_note_view_model.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/widgets/menu.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/action_bar.dart';
import 'package:tano/shared/widgets/theme.dart';

class EditNote extends StatefulWidget {
  final bool add;
  final int index;
  final NoteAction noteAction;
  final NotesRepository repository;

  const EditNote({
    super.key,
    required this.add,
    required this.index,
    required this.noteAction,
    required this.repository,
  });

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  late final EditNoteViewModel _viewModel;
  late NoteAction _noteAction;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  int _noteContentLength = 0;
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _viewModel = EditNoteViewModel(
      repository: widget.repository,
      add: widget.add,
      initialNote: widget.noteAction.note,
    );
    _noteAction = NoteAction(kind: NoteActionKind.cancel, note: widget.noteAction.note);
    _titleController.text =
        widget.noteAction.note?.title.replaceAll('\n', ' ') ?? '';
    _contentController.text = widget.noteAction.note?.content ?? '';
    _noteContentLength = widget.noteAction.note?.content.length ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _saveNote({required NoteAction noteAction}) {
    final Note note = _viewModel.buildNote(
      title: _titleController.text,
      content: _contentController.text,
    );
    if (!_viewModel.isValid(
      title: _titleController.text,
      content: _contentController.text,
    )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppText.tr('content_empty'))));
    } else {
      noteAction.note = note;
      noteAction.kind = NoteActionKind.save;
      Navigator.pop(context, noteAction);
    }
  }

  void _deleteNote(NoteAction noteAction) {
    noteAction.kind = NoteActionKind.delete;
    Navigator.pop(context, noteAction);
  }

  void _getNoteContentLength(String content) {
    setState(() {
      _noteContentLength = content.length;
    });
  }

  Future<bool> _onWillPopCallback() async {
    final String title = _titleController.text;
    final String content = _contentController.text;
    if (_viewModel.isDirty(title: title, content: content)) {
      final bool? confirm = await getConfirmation(
        context: context,
        actionTitle: AppText.tr('save_before_leave'),
        action: AppText.tr('save'),
      );
      if (confirm == true) {
        final Note note = _viewModel.buildNote(title: title, content: content);
        if (!_viewModel.isValid(title: title, content: content)) {
          if (!mounted) {
            return false;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppText.tr('content_empty'))));
          return false;
        }
        await _viewModel.persistSavedNote(note);
      }
    }

    return true;
  }

  List<Widget> _showActionButtons({required String action}) {
    final Widget markAsImportantActionButton = BottomActionButton(
      icon: _viewModel.important ? Icons.bookmark : Icons.bookmark_border,
      color: _viewModel.important ? tanoAmber : null,
      onPressed: _viewModel.toggleImportant,
    );

    switch (action) {
      case 'add':
        return <Widget>[markAsImportantActionButton];
      case 'edit':
        return <Widget>[
          markAsImportantActionButton,
          BottomActionButton(
            icon: Icons.clear,
            onPressed: () async {
              final bool? confirmDeletion = await getConfirmation(
                context: context,
                actionTitle: AppText.tr('delete_note'),
                action: AppText.tr('delete'),
              );
              if (confirmDeletion == true) {
                _deleteNote(_noteAction);
              }
            },
          ),
        ];
      default:
        return <Widget>[markAsImportantActionButton];
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool canLeave = await _onWillPopCallback();
        if (canLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldState,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20.0),
              onPressed: () async {
                final bool willPop = await _onWillPopCallback();
                if (willPop && context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (Route<dynamic> route) => false,
                  );
                }
              },
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => _saveNote(noteAction: _noteAction),
              ),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (BuildContext context, Widget? child) {
            return Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.5, vertical: 0.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: TextField(
                          maxLines: 1,
                          maxLength: 54,
                          showCursor: true,
                          controller: _titleController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 21.0,
                          ),
                          decoration: InputDecoration(
                            hintText: AppText.tr('title_here'),
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            counter: Offstage(),
                            contentPadding: EdgeInsets.all(0.0),
                          ),
                          onSubmitted: (submitted) {
                            FocusScope.of(context).requestFocus(_titleFocus);
                          },
                        ),
                      ),
                      SizedBox(width: 9.0),
                      PopupMenuButton<PopupItem>(
                        onSelected: ((valueSelected) {
                          _viewModel.setCategory(valueSelected.value);
                        }),
                        itemBuilder: (BuildContext context) {
                          final List<PopupItem> popupItems = [];
                          categoryElements.forEach((
                            String key,
                            PopupItem popupItem,
                          ) {
                            popupItems.add(popupItem);
                          });
                          return popupItems.map((PopupItem popupItem) {
                            return PopupMenuItem<PopupItem>(
                              value: popupItem,
                              child: popupButton(
                                context: context,
                                popupItem: popupItem,
                                editMode: true,
                              ),
                            );
                          }).toList();
                        },
                        child: Row(
                          children: <Widget>[
                            popupButton(
                              context: context,
                              popupItem: categoryElements[_viewModel.category] ??
                                  categoryElements['neutral']!,
                              editMode: true,
                            ),
                            const Icon(Icons.arrow_drop_down, size: 18.0),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    color: editorBackground(context),
                    padding: EdgeInsets.symmetric(horizontal: 9.0),
                    child: Column(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 1.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  '$_noteContentLength',
                                  style: TextStyle(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w300,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              Text(
                                _viewModel.selectedDate.toString().substring(
                                  0,
                                  16,
                                ),
                                style: TextStyle(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w300,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            maxLines: null,
                            minLines: null,
                            showCursor: true,
                            autofocus: widget.add,
                            focusNode: _contentFocus,
                            controller: _contentController,
                            textInputAction: TextInputAction.newline,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(fontSize: 14.4, height: 1.8),
                            decoration: InputDecoration(
                              hintText: AppText.tr('content_here'),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(0.0),
                            ),
                            onChanged: (String content) {
                              _getNoteContentLength(content);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: _viewModel,
          builder: (BuildContext context, Widget? child) {
            return BottomAppBar(
              elevation: 0.0,
              height: 36.0,
              padding: EdgeInsets.zero,
              color: barColor(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _showActionButtons(
                  action: widget.add ? 'add' : 'edit',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
