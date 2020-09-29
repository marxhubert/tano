import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tano/models/note.dart';
import 'package:tano/services/database.dart';
import 'package:tano/widgets/confirm.dart';
import 'package:tano/utils/menu.dart';
import 'package:tano/utils/action.dart';
import 'package:tano/pages/edit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/widgets/info.dart';
import 'package:tano/widgets/no_record.dart';
import 'package:package_info/package_info.dart';

class Home extends StatefulWidget {
    @override
    HomeState createState() {
        return HomeState();
    }
}

class HomeState extends State<Home> {
    Database _database;
    int _notesCount = 0;
    SharedPreferences _prefs;
    final _selected = Set<int>();
    String _viewLayout;
    String _actionButtons;
    bool _isInSelectionMode = false;
    String _sortBy;
    final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
    PackageInfo _packageInfo = PackageInfo(
        appName: 'Unknown',
        packageName: 'Unknown',
        version: 'Unknown',
        buildNumber: 'Unknown',
    );

    Future<String> _getViewPrefFromSP() async {
        _prefs = await SharedPreferences.getInstance();
        if (!_prefs.containsKey('viewLayout')) {
            _prefs.setString('viewLayout', 'list');
        }
        return _prefs.getString('viewLayout');
    }

    Future<void> _setViewPrefToSP(String viewLayout) async {
        _prefs = await SharedPreferences.getInstance();
        _prefs.setString('viewLayout', viewLayout);
    }

    Future<String> _getSortingPrefFromSP() async {
        _prefs = await SharedPreferences.getInstance();
        if (!_prefs.containsKey('sortBy')) {
            _prefs.setString('sortBy', 'date');
        }
        return _prefs.getString('sortBy');
    }

    Future<void> _setSortingPrefToSP(String sortBy) async {
        _prefs = await SharedPreferences.getInstance();
        _prefs.setString('sortBy', sortBy);
    }

    @override
    void initState() {
        super.initState();
        _loadNotes().then((notes) {
            setState(() {
                _notesCount = notes.length;
            });
        });
        _getViewPrefFromSP().then((viewLayout) {
            _viewLayout = viewLayout;
        });
        _getSortingPrefFromSP().then((sortBy) {
            _sortBy = sortBy;
        });
        _actionButtons = 'add';
        _initPackageInfo();
    }

    @override
    void dispose() {
        super.dispose();
    }

    Future<void> _initPackageInfo() async {
        final PackageInfo info = await PackageInfo.fromPlatform();
        setState(() {
            _packageInfo = info;
        });
    }

    Future<List<Note>> _loadNotes() async {
        await DbFileRoutines().readNotes().then((noteJson) {
            _database = dbFromJson(noteJson);
            setState(() {
                _sortNotesBy(_database.note);
            });
        });
        return _database.note;
    }

    void _sortNotesBy(List<Note> notes) {
        switch (_sortBy) {
            case 'date':
                notes.sort((note1, note2) => note2.date.compareTo(note1.date));
                break;
            case 'alpha':
                notes.sort((note1, note2) => note1.title.compareTo(note2.title));
                break;
            case 'important':
                notes.sort((note1, note2) => note2.important.toString().compareTo(note1.important.toString()));
                break;
            case 'category':
                notes.sort((note1, note2) => note1.category.compareTo(note2.category));
                break;
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
        if (null != _noteAction) {
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
            _notesCount = _database.note.length;
        }
    }

    _sortingBy(String sortBy) {
        if ('' != sortBy) {
            setState(() {
                _sortBy = sortBy;
                _setSortingPrefToSP(sortBy);
            });
        }
    }

    _changeLayout(String viewLayout) {
        switch (viewLayout) {
            case 'compact':
                setState(() {
                    _viewLayout = 'compact';
                    _setViewPrefToSP(_viewLayout);
                });
                break;
            case 'list':
                setState(() {
                    _viewLayout = 'list';
                    _setViewPrefToSP(_viewLayout);
                });
                break;
            case 'gridlist':
                setState(() {
                    _viewLayout = 'gridlist';
                    _setViewPrefToSP(_viewLayout);
                });
                break;
        }
    }

    Widget _layoutChanger(List<Note> notes, String viewLayout) {
        if (0 == notes.length) {
            return noRecordFound();
        }

        switch (viewLayout) {
            case 'compact':
                return _compactLayout(notes);
                break;
            case 'list':
                return _listLayout(notes);
                break;
            case 'gridlist':
                return _gridLayout(notes);
                break;
            default:
                return _listLayout(notes);
                break;
        }
    }

    Widget _showCheckboxForSelection(int index, bool alreadySelected) {
        if (!_isInSelectionMode) {
            return Container(child: null,);
        }

        return Checkbox(
            value: alreadySelected,
            onChanged: (value) {
                setState(() {
                    if (alreadySelected) {
                        _selected.remove(index);
                    } else {
                        _selected.add(index);
                    }
                });
                print(_selected);
            },
        );
    }

    Widget _gridLayout(List<Note> notes) {
        return GridView.count(
            crossAxisCount: 3,
            padding: EdgeInsets.symmetric(horizontal: 4.5),
            children: List.generate(notes.length, (index) {
                String _title = notes[index].title;
                String _content = notes[index].content;
                String _date = notes[index].date.toString().substring(0, 10);
                final _important = notes[index].important;
                return Card(
                    margin: EdgeInsets.all(2.7),
                    elevation: 0.6,
                    color: themeCategory(notes[index].category, false),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(0.0)),
                    ),
                    child: Stack(
                        children: <Widget>[
                            InkWell(
                                child: Container(
                                    color: themeCategory(notes[index].category, true),
                                    margin: EdgeInsets.only(bottom: 2.7),
                                    child: Container(
                                        padding: EdgeInsets.all(2.7),
                                        child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: <Widget>[
                                                Row(
                                                    children: <Widget>[
                                                        Expanded(
                                                            flex: 1,
                                                            child: Text(
                                                                _title,
                                                                style: TextStyle(
                                                                    fontWeight: FontWeight.bold,
                                                                    fontSize: 12.0
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                                Padding(
                                                    padding: EdgeInsets.only(bottom: 1.8),
                                                ),
                                                Expanded(
                                                    flex: 1,
                                                    child: Text(
                                                        _content,
                                                        style: TextStyle(
                                                            fontSize: 10.8
                                                        ),
                                                        overflow: TextOverflow.clip,
                                                        maxLines: null,
                                                    ),
                                                ),
                                                Row(
                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                    children: <Widget>[
                                                        SizedBox(height: 14.4,),
                                                        Expanded(
                                                            child: Text(
                                                                '$_date',
                                                                style: TextStyle(
                                                                    fontSize: 9.0,
                                                                    fontStyle: FontStyle.italic,
                                                                ),
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ],
                                        ),
                                    ),
                                ),
                                onTap: () {
                                    if (_isInSelectionMode) {
                                        setState(() {
                                            _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
                                        });
                                    } else {
                                        _noteController(add: false, index: index, note: notes[index]);
                                    }
                                },
                                onLongPress: () {
                                    setState(() {
                                        _selected.add(index);
                                        _isInSelectionMode = true;
                                        _actionButtons = 'multiple';
                                    });
                                },
                            ),
                            Container(
                                child: Row(
                                    children: <Widget>[
                                        Expanded(child: Offstage(),),
                                        Column(
                                            children: <Widget>[
                                                Expanded(child: Offstage(),),
                                                GestureDetector(
                                                    child: Container(
                                                        width: 45.0,
                                                        height: 45.0,
                                                        color: Colors.transparent,
                                                        alignment: Alignment.bottomRight,
                                                        padding: EdgeInsets.all(4.5),
                                                        child: Icon(
                                                            _important ? Icons.star : Icons.star_border,
                                                            color: _important ? Colors.orange : null,
                                                            size: 15.0,
                                                        ),
                                                    ),
                                                    onTap: () {
                                                        setState(() {
                                                            notes[index].important = !notes[index].important;
                                                            _database.note[index] = notes[index];
                                                            DbFileRoutines().writeNotes(dbToJson(_database));
                                                        });
                                                    },
                                                )
                                            ],
                                        )
                                    ],
                                ),
                            ),
                            _isInSelectionMode
                            ? GestureDetector(
                                child: Container(
                                    color: _selected.contains(index) ? Colors.black38 : Colors.black12,
                                    child: _selected.contains(index)
                                        ? Stack(
                                            children: <Widget>[
                                                Center(
                                                    child: Container(
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
                                                    child: Icon(Icons.check_circle, size: 45.0, color: Colors.blue,),
                                                ),
                                            ],
                                        )
                                        : Center(
                                            child: Icon(Icons.panorama_fish_eye, size: 45.0, color: Colors.black54,),
                                        ),
                                ),
                                onTap: () {
                                    setState(() {
                                        _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
                                    });
                                },
                            )
                            : Offstage(),
                        ],
                    ),
                );
            },),
        );
    }

    Widget _compactLayout(List<Note> notes) {
        return ListView.separated(
            itemCount: notes.length,
            itemBuilder: (BuildContext context, int index) {
                final alreadySelected = _selected.contains(index);
                String _title = notes[index].title;
                String _content = notes[index].content;
                String _date = notes[index].date.toString().substring(0, 10);
                final _important = notes[index].important;
                return Dismissible(
                    key: Key(notes[index].id),
                    background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 21.0),
                        child: Icon(
                            Icons.delete_forever,
                            color: Colors.blueGrey.shade50,
                            size: 27.0,
                        ),
                    ),
                    secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 21.0),
                        child: Icon(
                            Icons.delete_forever,
                            color: Colors.blueGrey.shade50,
                            size: 27.0,
                        ),
                    ),
                    child: Row(
                        children: <Widget>[
                            Expanded(
                                flex: 1,
                                child: Card(
                                    elevation: 0.6,
                                    margin: EdgeInsets.symmetric(horizontal: 4.5, vertical: 3.6),
                                    color: themeCategory(notes[index].category, false),
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(0.0)),
                                    ),
                                    child: Container(
                                        margin: EdgeInsets.only(left: 2.7),
                                        color: themeCategory(notes[index].category, true),
                                        child: ListTile(
                                            contentPadding: EdgeInsets.only(left: 9.0,),
                                            title: Row(
                                                children: <Widget>[
                                                    Expanded(
                                                        child: Text(
                                                            _title,
                                                            style: TextStyle(
                                                                fontSize: 12.0,
                                                                fontWeight: FontWeight.bold
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                        ),
                                                    ),
                                                    SizedBox(width: 9.0,),
                                                    Text(
                                                        _date,
                                                        style: TextStyle(
                                                            fontSize: 9.0,
                                                            fontStyle: FontStyle.italic,
                                                            color: Colors.black,
                                                        ),
                                                    ),
                                                ],
                                            ),
                                            trailing: IconButton(
                                                icon: Icon(
                                                    _important ? Icons.star : Icons.star_border,
                                                    color: _important ? Colors.orange : null,
                                                    size: 18.0,
                                                ),
                                                onPressed: () {
                                                    if (_isInSelectionMode) {
                                                        setState(() {
                                                            _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
                                                        });
                                                    } else {
                                                        setState(() {
                                                            notes[index].important = !notes[index].important;
                                                            _database.note[index] = notes[index];
                                                            DbFileRoutines().writeNotes(dbToJson(_database));
                                                        });
                                                    }
                                                },
                                            ),
                                            onTap: () {
                                                if (_isInSelectionMode) {
                                                    setState(() {
                                                        _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
                                                    });
                                                } else {
                                                    _noteController(add: false, index: index, note: notes[index]);
                                                }
                                            },
                                            onLongPress: () {
                                                setState(() {
                                                    _selected.add(index);
                                                    _isInSelectionMode = true;
                                                    _actionButtons = 'multiple';
                                                });
                                            },
                                        ),
                                    ),
                                ),
                            ),
                            _showCheckboxForSelection(index, alreadySelected),
                        ],
                    ),
                    confirmDismiss: (direction) async {
                        return await getConfirmation(context: context, actionTitle: _selected.length > 1 ? 'Supprimer ${_selected.length == _notesCount ? 'toutes les' : 'les ${_selected.length}'} notes' : 'Supprimer la note', action: 'supprimer');
                    },
                    onDismissed: (direction) {
                        setState(() {
                            _database.note.removeAt(index);
                        });
                        DbFileRoutines().writeNotes(dbToJson(_database));
                    },
                );
            },
            separatorBuilder: (BuildContext context, int index) {
                return Padding(
                    padding: EdgeInsets.only(bottom: 0.0),
                );
            },
        );
    }

    Widget _listLayout(List<Note> notes) {
        return ListView.separated(
            itemCount: notes.length,
            itemBuilder: (BuildContext context, int index) {
                final alreadySelected = _selected.contains(index);
                String _title = notes[index].title;
                String _content = notes[index].content;
                String _date = notes[index].date.toString().substring(0, 10);
                final _important = notes[index].important;
                return Dismissible(
                    key: Key(notes[index].id),
                    background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 21.0),
                        child: Icon(
                            Icons.delete_forever,
                            color: Colors.blueGrey.shade50,
                            size: 27.0,
                        ),
                    ),
                    secondaryBackground: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 21.0),
                        child: Icon(
                            Icons.delete_forever,
                            color: Colors.blueGrey.shade50,
                            size: 27.0,
                        ),
                    ),
                    child: Row(
                        children: <Widget>[
                            Expanded(
                                flex: 1,
                                child: Card(
                                    elevation: 0.6,
                                    margin: EdgeInsets.symmetric(horizontal: 4.5, vertical: 3.6),
                                    color: themeCategory(notes[index].category, false),
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(0.0)),
                                    ),
                                    child: Container(
                                        margin: EdgeInsets.only(left: 2.7),
                                        color: themeCategory(notes[index].category, true),
                                        child: ListTile(
                                            contentPadding: EdgeInsets.only(left: 9.0,),
                                            title: Text(
                                                _title,
                                                style: TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.bold
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Row(
                                                children: <Widget>[
                                                    Expanded(
                                                        child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: <Widget>[
                                                                Text(
                                                                    _content,
                                                                    maxLines: 3,
                                                                    overflow: TextOverflow.clip,
                                                                    style: TextStyle(
                                                                        fontSize: 12.0,
                                                                    ),
                                                                ),
                                                                Text(
                                                                    _date,
                                                                    style: TextStyle(
                                                                        fontSize: 10.8,
                                                                        fontStyle: FontStyle.italic,
                                                                        color: Colors.black,
                                                                    ),
                                                                ),
                                                            ],
                                                        ),
                                                    ),
                                                ],
                                            ),
                                            trailing: IconButton(
                                                icon: Icon(
                                                    _important ? Icons.star : Icons.star_border,
                                                    color: _important ? Colors.orange : null,
                                                    size: 18.0,
                                                ),
                                                onPressed: () {
                                                    if (_isInSelectionMode) {
                                                        setState(() {
                                                            _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
                                                        });
                                                    } else {
                                                        setState(() {
                                                            notes[index].important = !notes[index].important;
                                                            _database.note[index] = notes[index];
                                                            DbFileRoutines().writeNotes(dbToJson(_database));
                                                        });
                                                    }
                                                },
                                            ),
                                            onTap: () {
                                                if (_isInSelectionMode) {
                                                    setState(() {
                                                        _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
                                                    });
                                                } else {
                                                    _noteController(add: false, index: index, note: notes[index]);
                                                }
                                            },
                                            onLongPress: () {
                                                setState(() {
                                                    _selected.add(index);
                                                    _isInSelectionMode = true;
                                                    _actionButtons = 'multiple';
                                                });
                                            },
                                        ),
                                    ),
                                ),
                            ),
                            _showCheckboxForSelection(index, alreadySelected),
                        ],
                    ),
                    confirmDismiss: (direction) async {
                        return await getConfirmation(context: context, actionTitle: _selected.length > 1 ? 'Supprimer ${_selected.length == _notesCount ? 'toutes les' : 'les ${_selected.length}'} notes' : 'Supprimer la note', action: 'supprimer');
                    },
                    onDismissed: (direction) {
                        setState(() {
                            _database.note.removeAt(index);
                        });
                        DbFileRoutines().writeNotes(dbToJson(_database));
                    },
                );
            },
            separatorBuilder: (BuildContext context, int index) {
                return Padding(
                    padding: EdgeInsets.only(bottom: 0.0),
                );
            },
        );
    }

    List<Widget> _showActionButtons({int index, String action}) {
        Widget addActionButton = IconButton(
            icon: Icon(Icons.add),
            iconSize: 24.0,
            onPressed: () {
                _noteController(add: true, index: -1, note: Note());
            },
        );

        Widget cancelActionButton = IconButton(
            icon: Icon(Icons.arrow_back),
            iconSize: 24.0,
            onPressed: () {
                setState(() {
                    _selected.clear();
                    _isInSelectionMode = false;
                    _actionButtons = 'add';
                });
            },
        );

        Widget deleteActionButton = IconButton(
            icon: Icon(Icons.clear),
            iconSize: 24.0,
            onPressed: () async {
                if (_selected.isEmpty) {
                    _scaffoldState.currentState.showSnackBar(
                        SnackBar(
                            content: Text(
                                "Aucune note sélectionnée"
                            ),
                        ),
                    );
                } else {
                    final notes = <Note>[];
                    bool confirmDeletion = await getConfirmation(context: context, actionTitle: _selected.length > 1 ? 'Supprimer ${_selected.length == _notesCount ? 'toutes les' : 'les ${_selected.length}'} notes' : 'Supprimer la note', action: 'supprimer');
                    if (confirmDeletion) {
                        setState(() {
                            _selected.forEach((index) {
                                notes.add(_database.note[index]);
                            });
                            notes.forEach((note) {
                                _database.note.remove(note);
                            });
                            DbFileRoutines().writeNotes(dbToJson(_database));
                            _notesCount = _database.note.length;
                            _selected.clear();
                            _isInSelectionMode = false;
                            _actionButtons = 'add';
                        });
                    }
                }
            },
        );

        Widget selectAllActionButton = IconButton(
            icon: Icon(Icons.check_circle),
            iconSize: 21.0,
            onPressed: () {
                setState(() {
                    _database.note.forEach((note) {
                        _selected.add(_database.note.indexOf(note));
                    });
                });
            },
        );

        Widget selectNoneActionButton = IconButton(
            icon: Icon(Icons.panorama_fish_eye),
            iconSize: 21.0,
            onPressed: () {
                setState(() {
                    _selected.clear();
                });
            },
        );

        switch (action) {
            case 'add':
                return <Widget>[
                    Expanded(flex: 1, child: addActionButton,),
                ];
                break;
            case 'multiple':
                return <Widget>[
                    Expanded(flex: 1, child: cancelActionButton,),
                    Expanded(flex: 1, child: deleteActionButton,),
                    Expanded(flex: 1, child: selectNoneActionButton,),
                    Expanded(flex: 1, child: selectAllActionButton,),
                ];
                break;
            default:
                return <Widget>[
                    Expanded(flex: 1, child: addActionButton,),
                ];
                break;
        }
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            key: _scaffoldState,
            appBar: _isInSelectionMode
            ? AppBar(
                automaticallyImplyLeading: false,
                actions: <Widget>[
                    IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () {
                            setState(() {
                                _selected.clear();
                                _isInSelectionMode = false;
                                _actionButtons = 'add';
                            });
                        },
                    ),
                ],
                elevation: 0.0,
            )
            : AppBar(
                elevation: 0.0,
                actions: <Widget>[
                    IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                            _noteController(add: true, index: -1, note: Note());
                        },
                    ),
                    PopupMenuButton<PopupItem>(
                        icon: Icon(Icons.more_vert),
                        onSelected: ((valueSelected) {
                            switch(valueSelected.value.toLowerCase()) {
                                case "compact":
                                    _changeLayout('compact');
                                    break;
                                case "list":
                                    _changeLayout('list');
                                    break;
                                case "gridlist":
                                    _changeLayout('gridlist');
                                    break;
                                case "date":
                                    _sortingBy('date');
                                    break;
                                case "alpha":
                                    _sortingBy('alpha');
                                    break;
                                case "important":
                                    _sortingBy('important');
                                    break;
                                case "category":
                                    _sortingBy('category');
                                    break;
                                case "info":
                                    showDialog(context: context, builder: (BuildContext context) => aboutInfo(context: context, packageInfo: _packageInfo));
                                    break;
                            }
                        }),
                        itemBuilder: (BuildContext context) {
                            final List<PopupItem> popupItems = [];
                            menuItems.forEach((String key, PopupItem popupItem) {
                                popupItems.add(popupItem);
                            });
                            return popupItems.map((PopupItem popupItem) {
                                return PopupMenuItem<PopupItem>(
                                    value: popupItem,
                                    height: 42.0,
                                    child: popupButton(popupItem: popupItem, layout: _viewLayout, sort: _sortBy),
                                );
                            }).toList();
                        },
                        padding: EdgeInsets.all(0.0),
                    ),
                ],
            ),
            body: Container(
                child: Column(
                    children: <Widget>[
                        Container(
                            padding: EdgeInsets.symmetric(horizontal: 9.0),
                            child: Column(
                                children: <Widget>[
                                    Container(
                                        margin: EdgeInsets.only(bottom: 4.5),
                                        child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.baseline,
                                            textBaseline: TextBaseline.alphabetic,
                                            children: <Widget>[
                                                Expanded(
                                                    child: Text(
                                                        'Toutes les notes',
                                                        style: TextStyle(
                                                            fontFamily: 'Calibri',
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 21.0,
                                                        ),
                                                    ),
                                                ),
                                                Column(
                                                    children: <Widget>[
                                                        Text(
                                                            '$_notesCount ${_notesCount > 1 ? "notes" : "note"}',
                                                            style: TextStyle(
                                                                fontFamily: 'Calibri',
                                                                fontWeight: FontWeight.w400,
                                                            ),
                                                        ),
                                                    ],
                                                ),
                                            ],
                                        ),
                                    ),
                                    _notesCount == 0
                                    ? Offstage()
                                    : Container(
                                        height: 36.0,
                                        padding: EdgeInsets.symmetric(horizontal: 18.0),
                                        margin: EdgeInsets.only(bottom: 4.5),
                                        decoration: BoxDecoration(
                                            color: Colors.black12,
                                            borderRadius: BorderRadius.circular(54.0),
                                        ),
                                        child: Row(
                                            children: <Widget>[
                                                Icon(Icons.search, size: 21.0,),
                                                SizedBox(width: 9.0,),
                                                Expanded(
                                                    child: GestureDetector(
                                                        child: Text(
                                                            'Rechercher',
                                                            style: TextStyle(
                                                                fontWeight: FontWeight.w400,
                                                                fontSize: 14.4,
                                                                color: Colors.grey.shade600
                                                            ),
                                                        ),
                                                        onTap: () {
                                                            _isInSelectionMode == true
                                                                ? print('Tano is in selection mode.')
                                                                : Navigator.of(context).pushNamed('/search');
                                                        },
                                                    ),
                                                ),
                                            ],
                                        ),
                                    ),
                                    _isInSelectionMode
                                    ? Container(
                                        margin: EdgeInsets.only(bottom: 4.5),
                                        child: Text(
                                            _selected.length == 0
                                                ? 'Aucune note sélectionnée'
                                                : (_selected.length > 1
                                                    ? (_selected.length == _notesCount ? 'Toutes les $_notesCount notes sont sélectionnées' : '${_selected.length}/$_notesCount notes sélectionnées')
                                                    : '${_selected.length} seule note sélectionnée'),
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 12.0,
                                            ),
                                        ),
                                    )
                                    : _notesCount > 0
                                    ? Container(
                                        margin: EdgeInsets.only(bottom: 4.5),
                                        alignment: Alignment.center,
                                        child: Text(
                                            'Triage par ${menuItems[_sortBy].title.toLowerCase()}',
                                            style: TextStyle(
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w400,
                                                fontSize: 12.0,
                                            ),
                                        ),
                                    )
                                    : Offstage(),
                                ],
                            ),
                        ),
                        Expanded(
                            child: FutureBuilder(
                                initialData: [],
                                future: _loadNotes(),
                                builder: (BuildContext context, AsyncSnapshot snapshot) {
                                    while (!snapshot.hasData) {
                                        return Center(child: CircularProgressIndicator());
                                    }
                                    List<Note> notes = List<Note>.generate(snapshot.data.length, (int index) => snapshot.data[index]);
                                    return _layoutChanger(notes, _viewLayout);
                                },
                            ),
                        ),
                    ],
                ),
            ),
            bottomNavigationBar: BottomAppBar(
                elevation: 0.0,
                color: Colors.blueGrey.shade50,
                child: Container(
                    height: 40.5,
                    alignment: Alignment.center,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _showActionButtons(action: _actionButtons),
                    ),
                ),
            ),
//            drawer: DrawerMenu(),
        );
    }
}