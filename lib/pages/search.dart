import 'package:flutter/material.dart';
import 'package:tano/models/note.dart';
import 'package:tano/pages/edit.dart';
import 'package:tano/services/database.dart';
import 'package:tano/utils/action.dart';
import 'package:tano/utils/menu.dart';

class SearchPage extends StatefulWidget {
    @override
    _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
    Database _database;
    List<Note> _notes = [];
    List<Note> _searchResult = [];
    TextEditingController _searchFieldController = TextEditingController();

    @override
    void initState() {
        super.initState();
        _loadNotes().then((notes) {
            setState(() {
                _notes = notes;
            });
        });
        _searchFieldController.text = '';
    }

    @override
    void dispose() {
        _searchFieldController.dispose();
        super.dispose();
    }

    Future<List<Note>> _loadNotes() async {
        await DbFileRoutines().readNotes().then((noteJson) {
            _database = dbFromJson(noteJson);
            _database.note.sort((note1, note2) => note2.date.compareTo(note1.date));
        });
        return _database.note;
    }

    void _searchEngine(String keyword) {
        if ('' == keyword.trim()) {
            setState(() {
                _searchResult.clear();
            });
        } else {
            _searchResult.clear();
            _notes.forEach((Note note) {
                bool isStringInTitle = note.title.contains(RegExp(keyword, caseSensitive: false));
                bool isStringInContent = note.content.contains(RegExp(keyword, caseSensitive: false));
                if (isStringInTitle || isStringInContent) {
                    setState(() {
                        if (!_searchResult.contains(note)) {
                            _searchResult.add(note);
                        }
                    });
                }
            });
        }
    }

    void _noteController({bool add, int index, Note note}) async {
        NoteAction _noteAction = NoteAction(action: '', note: note);
        _noteAction = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => EditNote(
                    add: add,
                    index: index,
                    noteAction: _noteAction,
                ),
                fullscreenDialog: true
            ),
        );
        switch (_noteAction.action) {
            case 'Save':
                if (add) {
                    setState(() {
                        _database.note.add(_noteAction.note);
                    });
                } else {
                    setState(() {
                        _database.note[index] = _noteAction.note;
                    });
                }
                break;
            case 'Delete':
                setState(() {
                    _database.note.removeAt(index);
                });
                break;
            case 'Cancel':
                break;
            default:
                break;
        }
        DbFileRoutines().writeNotes(dbToJson(_database));
    }

    Widget _showSearchResult(List<Note> notes) {
        return Container(
            child: notes.isEmpty
            ? Column(children: <Widget>[
                Padding(padding: EdgeInsets.only(bottom: 4.5),),
                Text(
                    'Aucun élément trouvé',
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 12.0
                    ),
                ),
            ],)
            : _compactListLayout(notes),
        );
    }

    Widget _compactListLayout(List<Note> notes) {
        return ListView.separated(
            itemCount: notes.length,
            itemBuilder: (BuildContext context, int index) {
                String _title = notes[index].title;
                String _date = notes[index].date.toString().substring(0, 10);
                final _important = notes[index].important;
                return Row(
                    children: <Widget>[
                        Expanded(
                            flex: 1,
                            child: Card(
                                elevation: 0.6,
                                color: themeCategory(notes[index].category, false),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(0.0)),
                                ),
                                child: Container(
                                    margin: EdgeInsets.only(left: 2.7),
                                    color: themeCategory(notes[index].category, true),
                                    child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 9.0,),
                                        title: Text(
                                            _title,
                                            style: TextStyle(
                                                fontSize: 14.4,
                                                fontWeight: FontWeight.bold
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                            _date,
                                            style: TextStyle(
                                                fontSize: 12.0,
                                                fontStyle: FontStyle.italic,
                                            ),
                                        ),
                                        trailing: Icon(
                                            _important ? Icons.star : Icons.star_border,
                                            color: _important ? Colors.orange : null,
                                            size: 18.0,
                                        ),
                                        onTap: () {
                                            _noteController(add: false, index: index, note: notes[index]);
                                        },
                                    ),
                                ),
                            ),
                        ),
                    ],
                );
            },
            separatorBuilder: (BuildContext context, int index) {
                return Padding(
                    padding: EdgeInsets.only(bottom: 0.0),
                );
            },
        );
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            body: SafeArea(
                child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.2),
                    margin: EdgeInsets.only(top: 4.5),
                    child: Column(
                        children: <Widget>[
                            Container(
                                height: 36.0,
                                decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(54.0),
                                ),
                                child: Row(
                                    children: <Widget>[
                                        GestureDetector(
                                            child: Container(
                                                width: 54.0,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(54.0),
                                                ),
                                                child: Center(
                                                    child: Icon(Icons.arrow_back, size: 21.0,),
                                                ),
                                            ),
                                            onTap: () => Navigator.pop(context),
                                        ),
                                        //SizedBox(width: 12.0,),
                                        Expanded(
                                            flex: 1,
                                            child: TextField(
                                                showCursor: true,
                                                controller: _searchFieldController,
                                                autofocus: true,
                                                textInputAction: TextInputAction.next,
                                                style: TextStyle(
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14.4,
                                                ),
                                                decoration: InputDecoration(
                                                    hintText: 'Taper pour rechercher',
                                                    hintStyle: TextStyle(
                                                        color: Colors.black
                                                    ),
                                                    border: InputBorder.none,
                                                ),
                                                onTap: () {
                                                    setState(() {
                                                        _searchResult.clear();
                                                    });
                                                },
                                                onChanged: (String text) {
                                                    setState(() {
                                                        _searchEngine(text);
                                                    });
                                                },
                                            ),
                                        ),
                                        _searchFieldController.text == ''
                                        ? Offstage()
                                        : GestureDetector(
                                            child: Container(
                                                width: 54.0,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(54.0),
                                                ),
                                                child: Center(
                                                    child: Icon(Icons.clear, size: 21.0,),
                                                ),
                                            ),
                                            onTap: () {
                                                setState(() {
                                                    _searchFieldController.text = '';
                                                    _searchResult.clear();
                                                });
                                            },
                                        ),
                                    ],
                                ),
                            ),
                            _searchResult.length > 0
                            ? Container(
                                padding: EdgeInsets.symmetric(vertical: 4.5),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                        Text(
                                            _searchResult.length == 1 ? '${_searchResult.length} seul résultat correspondant' : '${_searchResult.length} résultats correspondants',
                                            style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontSize: 12.0
                                            ),
                                        ),
                                    ],
                                ),
                            )
                            : Offstage(),
                            Expanded(
                                child: Container(
                                    child: _showSearchResult(_searchResult),
                                ),
                            ),
                        ],
                    ),
                ),
            ),
        );
    }
}
