import 'package:flutter/material.dart';
import 'dart:math';
import 'package:tano/config/l10n.dart';
import 'package:tano/models/note.dart';
import 'package:tano/utils/note_edit.dart';

class EditEntry extends StatefulWidget {
    final bool add;
    final int index;
    final NoteEdit noteEdit;

    const EditEntry({
        super.key,
        required this.add,
        required this.index,
        required this.noteEdit,
    });

    @override
    State<EditEntry> createState() => _EditEntryState();
}

class _EditEntryState extends State<EditEntry> {
    late NoteEdit _noteEdit;
    late String _actionTitle;
    late DateTime _selectedDate;
    late bool _important;
    final TextEditingController _titleController = TextEditingController();
    final TextEditingController _contentController = TextEditingController();
    final FocusNode _titleFocus = FocusNode();
    final FocusNode _contentFocus = FocusNode();

    @override
    void initState() {
        super.initState();
        _noteEdit = NoteEdit(action: 'Cancel', note: widget.noteEdit.note);
        _actionTitle = widget.add ? AppText.tr('add_note') : AppText.tr('edit_note');
        if (widget.add) {
            _selectedDate = DateTime.now();
            _titleController.text = '';
            _contentController.text = '';
            _important = false;
        } else {
            _selectedDate = DateTime.parse(_noteEdit.note!.date!);
            _titleController.text = _noteEdit.note!.title ?? '';
            _contentController.text = _noteEdit.note!.content ?? '';
            _important = _noteEdit.note!.important ?? false;
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
        String id = widget.add ? Random().nextInt(999999).toString() : noteEdit.note!.id ?? '';
        noteEdit.note = Note(
            id: id,
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
                title: Text(_actionTitle),
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
                                    labelText: AppText.tr('title'),
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
                                    labelText: AppText.tr('content'),
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
                                            AppText.tr('important'),
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
                tooltip: AppText.tr('save_changes'),
                child: Icon(Icons.save),
                onPressed: () => _saveAction(_noteEdit),
            ),
        );
    }
}
