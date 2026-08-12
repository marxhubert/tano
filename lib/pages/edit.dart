import 'package:flutter/material.dart';
import 'dart:math';
import 'package:tano/config/l10n.dart';
import 'package:tano/domain/notes_repository.dart';
import 'package:tano/models/database.dart';
import 'package:tano/models/note.dart';
import 'package:tano/utils/action.dart';
import 'package:tano/utils/menu.dart';
import 'package:tano/widgets/confirm.dart';

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
    late Database _database;
    late NoteAction _noteAction;
    late String _id;
    late DateTime _selectedDate;
    late bool _important;
    late String _category;
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    final FocusNode _titleFocus = FocusNode();
    final FocusNode _contentFocus = FocusNode();
    int _noteContentLength = 0;
    final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
    late Note _initialNote;

    @override
    void initState() {
        super.initState();
        widget.repository.loadNotes().then((notes) {
            _database = Database(note: notes);
        });
        _noteAction = NoteAction(action: 'Cancel', note: widget.noteAction.note);
        if (widget.add) {
            _id = Random().nextInt(999999).toString();
            _selectedDate = DateTime.now();
            _titleController.text = '';
            _contentController.text = '';
            _important = false;
            _category = 'none';
            _noteContentLength = 0;
            _initialNote = _setNote(init: true);
        } else {
            _id = _noteAction.note!.id ?? '';
            _selectedDate = DateTime.parse(_noteAction.note!.date!);
            _titleController.text = _noteAction.note!.title!.replaceAll('\n', ' ');
            _contentController.text = _noteAction.note!.content ?? '';
            _important = _noteAction.note!.important ?? false;
            _category = _noteAction.note!.category ?? 'none';
            _noteContentLength = _noteAction.note!.content?.length ?? 0;
            _initialNote = _setNote(init: true);
        }
    }

    @override
    void dispose() {
        _titleController.dispose();
        _contentController.dispose();
        _titleFocus.dispose();
        _contentFocus.dispose();
        super.dispose();
    }

    Note _setNote({bool init = false}) {
        int max = 18 > _noteContentLength ? _noteContentLength : 18;
        String content = _contentController.text.trim();
        String title = _titleController.text.trim() != '' ? _titleController.text.trim() : content.substring(0, max).replaceAll('\n', ' ');

        return Note(
            id: _id,
            date: _selectedDate.toString(),
            title: init ? _titleController.text : title,
            content: init ? _contentController.text : content,
            important: _important,
            category: _category,
        );
    }

    void _saveNote({required NoteAction noteAction, bool willPop = false}) {
        Note note = _setNote();
        if ('' == note.content!.trim()) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        AppText.tr('content_empty')
                    ),
                ),
            );
        } else {
            noteAction.note = note;
            if (willPop) {
                widget.add ? _database.note.add(noteAction.note!) : _database.note[widget.index] = noteAction.note!;
            } else {
                noteAction.action = 'Save';
                Navigator.pop(context, noteAction);
            }
        }
    }

    void _deleteNote(NoteAction noteAction) {
        noteAction.action = 'Delete';
        Navigator.pop(context, noteAction);
    }

    void _getNoteContentLength(String content) {
        setState(() {
            _noteContentLength = content.length;
        });
    }

    List<Widget> _showActionButtons({required String action}) {
        Widget deleteActionButton = IconButton(
            icon: Icon(Icons.clear),
            iconSize: 24.0,
            onPressed: () async {
                final bool? confirmDeletion = await getConfirmation(context: context, actionTitle: AppText.tr('delete_note'), action: AppText.tr('delete'));
                if (confirmDeletion == true) {
                    _deleteNote(_noteAction);
                }
            },
        );

        Widget markAsImportantActionButton = IconButton(
            icon: Icon(
                _important ? Icons.star : Icons.star_border,
                color: _important ? Colors.orange : null,
            ),
            iconSize: 24.0,
            onPressed: () {
                setState(() {
                    _important = !_important;
                });
            },
        );

        switch (action) {
            case 'add':
                return <Widget>[
                    Expanded(flex: 1, child: markAsImportantActionButton,),
                ];
            case 'edit':
                return <Widget>[
                    Expanded(flex: 1, child: markAsImportantActionButton,),
                    Expanded(flex: 1, child: deleteActionButton,),
                ];
            default:
                return <Widget>[
                    Expanded(flex: 1, child: markAsImportantActionButton,),
                ];
        }
    }

    Future<bool> _onWillPopCallback() async {
        Note note = _setNote();
        if (note.toJson().toString() != _initialNote.toJson().toString()) {
            final bool? confirm = await getConfirmation(context: context, actionTitle: AppText.tr('save_before_leave'), action: AppText.tr('save'));
            if (confirm == true) {
                _saveNote(noteAction: _noteAction, willPop: true);
                if (note.content == '') {
                    return false;
                }
                await widget.repository.saveNotes(_database.note);
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
            child: Scaffold(
                key: _scaffoldState,
                appBar: AppBar(
                    automaticallyImplyLeading: false,
                    elevation: 0.0,
                    actions: <Widget>[
                        IconButton(
                            icon: Icon(Icons.arrow_back),
                            onPressed: () async {
                                final bool willPop = await _onWillPopCallback();
                                if (willPop && context.mounted) {
                                    Navigator.of(context).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
                                }
                            },
                        ),
                        Expanded(
                            child: Offstage(),
                        ),
                        IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () => _saveNote(noteAction: _noteAction),
                        ),
                    ],
                ),
                body: Column(
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
                                                    fontFamily: 'Calibri',
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 21.0,
                                                ),
                                                decoration: InputDecoration(
                                                    hintText: AppText.tr('title_here'),
                                                    hintStyle: TextStyle(
                                                        color: Colors.grey,
                                                    ),
                                                    border: InputBorder.none,
                                                    counter: Offstage(),
                                                    contentPadding: EdgeInsets.all(0.0),
                                                ),
                                                onSubmitted: (submitted) {
                                                    FocusScope.of(context).requestFocus(_titleFocus);
                                                },
                                            ),
                                        ),
                                        SizedBox(width: 9.0,),
                                        PopupMenuButton<PopupItem>(
                                            onSelected: ((valueSelected) {
                                                setState(() {
                                                    _category = valueSelected.value;
                                                });
                                            }),
                                            itemBuilder: (BuildContext context) {
                                                final List<PopupItem> popupItems = [];
                                                categoryElements.forEach((String key, PopupItem popupItem) {
                                                    popupItems.add(popupItem);
                                                });
                                                return popupItems.map((PopupItem popupItem) {
                                                    return PopupMenuItem<PopupItem>(
                                                        value: popupItem,
                                                        child: popupButton(popupItem: popupItem, editMode: true),
                                                    );
                                                }).toList();
                                            },
                                            child: Row(
                                                children: <Widget>[
                                                    popupButton(popupItem: categoryElements[_category]!, editMode: true),
                                                    Icon(Icons.arrow_drop_down, size: 18.0,),
                                                ],
                                            ),
                                        ),
                                    ],
                                ),
                            ),
                            Expanded(
                                flex: 1,
                                child: Container(
                                    color: Colors.white,
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
                                                            _selectedDate.toString().substring(0, 16),
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
                                                    style: TextStyle(
                                                        fontSize: 14.4,
                                                        height: 1.8,
                                                    ),
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
                    ),
                bottomNavigationBar: BottomAppBar(
                    elevation: 0.0,
                    color: Colors.blueGrey.shade50,
                    child: Container(
                        height: 40.5,
                        alignment: Alignment.center,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: _showActionButtons(action: widget.add ? 'add' : 'edit'),
                        ),
                    ),
                ),
            ),
        );
    }
}
