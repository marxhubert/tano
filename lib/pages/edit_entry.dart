import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:tano/models/note.dart';
import 'package:tano/utils/note_edit.dart';

class EditEntry extends StatefulWidget {
    final bool add;
    final int index;
    final NoteEdit noteEdit;

    const EditEntry({
        Key key,
        this.add,
        this.index,
        this.noteEdit,
    }) : super(key: key);

    @override
    _EditEntryState createState() => _EditEntryState();
}

class _EditEntryState extends State<EditEntry> {
    NoteEdit _noteEdit;
    String _actionTitle;
    DateTime _selectedDate;
    bool _important;
    TextEditingController _titleController = TextEditingController();
    TextEditingController _contentController = TextEditingController();
    FocusNode _titleFocus = FocusNode();
    FocusNode _contentFocus = FocusNode();

    @override
    void initState() {
        super.initState();
        _noteEdit = NoteEdit(action: 'Cancel', note: widget.noteEdit.note);
        _actionTitle = widget.add ? 'Add' : 'Edit';
        if (widget.add) {
            _selectedDate = DateTime.now();
            _titleController.text = '';
            _contentController.text = '';
            _important = false;
        } else {
            _selectedDate = DateTime.parse(_noteEdit.note.date);
            _titleController.text = _noteEdit.note.title;
            _contentController.text = _noteEdit.note.content;
            _important = _noteEdit.note.important;
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

    void _saveAction(NoteEdit noteEdit) {
        noteEdit.action = 'Save';
        String _id = widget.add ? Random().nextInt(999999).toString() : noteEdit.note.id;
        noteEdit.note = Note(
            id: _id,
            date: _selectedDate.toString(),
            title: _titleController.text,
            content: _contentController.text,
            important: _important,
        );
        Navigator.pop(context, noteEdit);
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('$_actionTitle note'),
                automaticallyImplyLeading: true,
            ),
            body: SafeArea(
                child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 45.0),
                    child: Column(
                        children: <Widget>[
                            Container(
                                height: 21.0,
                            ),
                            TextField(
                                controller: _titleController,
                                autofocus: true,
                                textInputAction: TextInputAction.newline,
                                decoration: InputDecoration(
                                    labelText: 'Title',
                                ),
                                onSubmitted: (submitted) {
                                    FocusScope.of(context).requestFocus(_titleFocus);
                                },
                                maxLength: 126,
                                minLines: 1,
                                maxLines: null,
                            ),
                            SizedBox(height: 18.0,),
                            TextField(
                                controller: _contentController,
                                textInputAction: TextInputAction.newline,
                                focusNode: _contentFocus,
                                textCapitalization: TextCapitalization.sentences,
                                decoration: InputDecoration(
                                    labelText: 'Content',
                                ),
                                maxLength: 3000,
                                minLines: 3,
                                maxLines: null,
                            ),
                            SizedBox(height: 21.0,),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                    Expanded(
                                        flex: 1,
                                        child: Text(
                                            'This is mportant',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15.0,
                                            ),
                                        ),
                                    ),
                                    Switch(
                                        value: _important,
                                        onChanged: (value) {
                                            setState(() {
                                                _important = !_important;
                                            });
                                        },
                                    ),
                                ],
                            ),
                        ],
                    ),
                ),
            ),
            floatingActionButton: FloatingActionButton(
                tooltip: 'Save changes',
                child: Icon(Icons.save),
                onPressed: () => _saveAction(_noteEdit),
            ),
        );
    }
}
