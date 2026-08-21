import 'package:flutter/material.dart';
import 'package:tano/features/editor/edit_note_view_model.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/widgets/menu.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/app_fab.dart';
import 'package:tano/shared/widgets/page_layout.dart';
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
    _noteAction =
        NoteAction(kind: NoteActionKind.cancel, note: widget.noteAction.note);
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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.tr('content_empty'))));
    } else {
      noteAction.note = note;
      noteAction.kind = NoteActionKind.save;
      Navigator.pop(context, noteAction);
    }
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
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppText.tr('content_empty'))));
          return false;
        }
        await _viewModel.persistSavedNote(note);
      }
    }

    return true;
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
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (BuildContext context, Widget? child) {
          return PageScaffold(
            scaffoldKey: _scaffoldState,
            title: widget.add ? AppText.tr('add_note') : AppText.tr('edit_note'),
            onPop: () async {
              final bool willPop = await _onWillPopCallback();
              if (willPop && context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (Route<dynamic> route) => false,
                );
              }
            },
            actions: [
              IconButton(
                icon: Icon(
                  _viewModel.important ? Icons.bookmark : Icons.bookmark_border,
                  color: _viewModel.important ? tanoAmber : null,
                ),
                onPressed: _viewModel.toggleImportant,
              ),
            ],
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    TextField(
                      maxLines: 1,
                      maxLength: 54,
                      showCursor: true,
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 21.0,
                      ),
                      decoration: InputDecoration(
                        hintText: AppText.tr('title_here'),
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        counter: const Offstage(),
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (submitted) {
                        FocusScope.of(context).requestFocus(_contentFocus);
                      },
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            '$_noteContentLength',
                            style: const TextStyle(
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
                          style: const TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w300,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      maxLines: null,
                      minLines: 10,
                      showCursor: true,
                      autofocus: widget.add,
                      focusNode: _contentFocus,
                      controller: _contentController,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 14.4, height: 1.8),
                      decoration: InputDecoration(
                        hintText: AppText.tr('content_here'),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (String content) {
                        _getNoteContentLength(content);
                      },
                    ),
                  ],
                ),
              ),
            ],
            floatingActionButtonLocation: const FlushEndFabLocation(),
            floatingActionButton: AppFab(
              isEditorMode: true,
              onSave: () => _saveNote(noteAction: _noteAction),
              onColorLens: () {}, // Placeholder
              onMore: () {}, // Placeholder
            ),
          );
        },
      ),
    );
  }
}
