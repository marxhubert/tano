import 'package:flutter/material.dart';
import 'package:tano/config/l10n.dart';
import 'package:tano/services/database.dart';
import 'package:tano/models/note.dart';
import 'package:tano/utils/note_edit.dart';
import 'package:tano/pages/edit_entry.dart';

class ViewNote extends StatefulWidget {
    final int index;
    final NoteEdit noteEdit;

    const ViewNote({
        super.key,
        required this.index,
        required this.noteEdit,
    });

    @override
    State<ViewNote> createState() => _ViewNoteState();
}

class _ViewNoteState extends State<ViewNote> {
    late NoteEdit _noteEdit;
    late int _index;
    late Database _database;

    @override
    void initState() {
        super.initState();
        _noteEdit = NoteEdit(action: 'Cancel', note: widget.noteEdit.note);
        _index = widget.index;
        _loadNotes();
    }

    Future<List<Note>> _loadNotes() async {
        await DbFileRoutines().readNotes().then((noteJson) {
            _database = dbFromJson(noteJson);
            _database.note.sort((note1, note2) => note2.date!.compareTo(note1.date!));
        });
        return _database.note;
    }

    void _addOrEditNote({required bool add, required int index, required Note note}) async {
        final NoteEdit? result = await Navigator.push(
            context,
            MaterialPageRoute<NoteEdit>(
                builder: (context) => EditEntry(
                    add: add,
                    index: index,
                    noteEdit: NoteEdit(action: '', note: note),
                ),
                fullscreenDialog: true
            ),
        );
        if (result == null) {
            return;
        }
        switch (result.action) {
            case 'Save':
                if (add) {
                    setState(() {
                        _database.note.add(result.note!);
                    });
                } else {
                    setState(() {
                        _database.note[index] = result.note!;
                    });
                }
                await DbFileRoutines().writeNotes(dbToJson(_database));
                break;
            case 'Cancel':
                break;
            default:
                break;
        }
        if (mounted) {
            Navigator.pop(context, result);
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text(_noteEdit.note?.title ?? ''),
            ),
            body: SafeArea(
                child: SingleChildScrollView(
                    padding: EdgeInsets.all(36.0),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                            Row(
                                children: <Widget>[
                                    Expanded(
                                        flex: 1,
                                        child: Text(
                                            _noteEdit.note?.title ?? '',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w400,
                                                fontSize: 21.0
                                            ),
                                        ),
                                    ),
                                    Switch(
                                        value: _noteEdit.note?.important ?? false,
                                        onChanged: (value) {
                                            setState(() {
                                                _noteEdit.note!.important = !_noteEdit.note!.important!;
                                                _database.note[_index] = _noteEdit.note!;
                                                DbFileRoutines().writeNotes(dbToJson(_database));
                                            });
                                        }
                                    ),
                                ],
                            ),
                            SizedBox(height: 12.0,),
                            Text(
                                _noteEdit.note?.date?.substring(0, 10) ?? '',
                            ),
                            SizedBox(height: 27.0,),
                            Text(
                                AppText.tr('notes_section'),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                ),
                            ),
                            SizedBox(height: 9.0,),
                            Text(
                                _noteEdit.note?.content ?? ''
                            ),
                        ],
                    ),
                ),
            ),
            floatingActionButton: FloatingActionButton(
                tooltip: AppText.tr('edit_note'),
                child: Icon(Icons.edit),
                onPressed: () => _addOrEditNote(add: false, index: _index, note: _noteEdit.note!),
            ),
        );
    }
}
