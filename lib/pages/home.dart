import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tano/models/note.dart';
import 'package:tano/services/database.dart';
import 'package:tano/utils/menu_item.dart';
import 'package:tano/utils/note_edit.dart';
import 'package:tano/pages/edit_entry.dart';
import 'package:tano/pages/view_note.dart';

class Home extends StatefulWidget {
    @override
    HomeState createState() {
        return HomeState();
    }
}

class HomeState extends State<Home> {
    Database _database;

    Future<List<Note>> _loadNotes() async {
        await DbFileRoutines().readNotes().then((noteJson) {
            _database = dbFromJson(noteJson);
            _database.note.sort((note1, note2) => note2.date.compareTo(note1.date));
        });
        return _database.note;
    }

    void _viewNote({int index, Note note}) async {
        NoteEdit _noteEdit = NoteEdit(action: '', note: note);
        await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ViewNote(
                    index: index,
                    noteEdit: _noteEdit,
                ),
                fullscreenDialog: true
            ),
        );
    }

    void _addOrEditNote({bool add, int index, Note note}) async {
        NoteEdit _noteEdit = NoteEdit(action: '', note: note);
        _noteEdit = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditEntry(
                    add: add,
                    index: index,
                    noteEdit: _noteEdit,
                ),
                fullscreenDialog: true
            ),
        );
        switch (_noteEdit.action) {
            case 'Save':
                if (add) {
                    setState(() {
                        _database.note.add(_noteEdit.note);
                    });
                } else {
                    setState(() {
                        _database.note[index] = _noteEdit.note;
                    });
                }
                DbFileRoutines().writeNotes(dbToJson(_database));
                break;
            case 'Cancel':
                break;
            default:
                break;
        }
    }

    Widget _buildListViewSeparated(AsyncSnapshot snapshot) {
        if (0 == snapshot.data.length) {
            return Container(
                child: Center(
                    child: Text(
                        'No record found ...',
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 27.0,
                        ),
                    )
                ),
            );
        }

        return ListView.separated(
            itemCount: snapshot.data.length,
            itemBuilder: (BuildContext context, int index) {
                String _title = snapshot.data[index].title;
                String _date = snapshot.data[index].date.toString().substring(0, 10);
                final _important = snapshot.data[index].important;
                return Dismissible(
                    key: Key(snapshot.data[index].id),
                    background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 27.0),
                        child: Icon(
                            Icons.delete,
                            color: Colors.white,
                        ),
                    ),
                    secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 27.0),
                        child: Icon(
                            Icons.delete,
                            color: Colors.white,
                        ),
                    ),
                    child: Container(
                        child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 27.0, vertical: 12.0),
                            title: Text(
                                _title,
                                style: TextStyle(
                                    fontSize: 21.0,
                                    fontWeight: FontWeight.w400
                                ),
                                overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                                _date,
                            ),
                            trailing: IconButton(
                                icon: Icon(
                                    _important ? Icons.star : Icons.star_border,
                                    color: _important ? Colors.orange : null,
                                    size: 36.0,
                                ),
                                onPressed: () {
                                    setState(() {
                                        snapshot.data[index].important = !snapshot.data[index].important;
                                        _database.note[index] = snapshot.data[index];
                                        DbFileRoutines().writeNotes(dbToJson(_database));
                                    });
                                },
                            ),
                            onTap: () {
                                _viewNote(index: index, note: snapshot.data[index]);
                            },
                            onLongPress: () {
                                _addOrEditNote(add: false, index: index, note: snapshot.data[index]);
                            },
                        ),
                    ),
                    onDismissed: (direction) {
                        setState(() {
                            _database.note.removeAt(index);
                        });
                        DbFileRoutines().writeNotes(dbToJson(_database));
                    },
                );
            },
            separatorBuilder: (BuildContext context, int index) {
                return Divider(
                    color: Colors.grey,
                    height: 0.1,
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('Tano'),
                actions: <Widget>[
                    PopupMenuButton<MenuItem>(
                        icon: Icon(Icons.more_vert),
                        onSelected: ((valueSelected) {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) => aboutDialog(context)
                            );
                        }),
                        itemBuilder: (BuildContext context) {
                            return menuItemList.map((MenuItem menuItem) {
                                return PopupMenuItem<MenuItem>(
                                    value: menuItem,
                                    child: Row(
                                        children: <Widget>[
                                            Icon(menuItem.icon.icon, color: Colors.black,),
                                            Padding(
                                                padding: EdgeInsets.all(9.0),
                                            ),
                                            Text(menuItem.title),
                                        ],
                                    ),
                                );
                            }).toList();
                        },
                    ),
                    SizedBox(width: 9.0,),
                ],
            ),
            body: FutureBuilder(
                initialData: [],
                future: _loadNotes(),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                    return !snapshot.hasData
                        ? Center(child: CircularProgressIndicator())
                        : _buildListViewSeparated(snapshot);
                },
            ),
            floatingActionButton: FloatingActionButton(
                tooltip: 'Add note entry',
                child: Icon(Icons.add),
                onPressed: () {
                    _addOrEditNote(add: true, index: -1, note: Note());
                },
            ),
        );
    }
}