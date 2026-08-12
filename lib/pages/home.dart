import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tano/config/l10n.dart';
import 'package:tano/models/note.dart';
import 'package:tano/services/database.dart';
import 'package:tano/widgets/confirm.dart';
import 'package:tano/utils/menu.dart';
import 'package:tano/utils/action.dart';
import 'package:tano/pages/edit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/widgets/info.dart';
import 'package:tano/widgets/no_record.dart';
import 'package:package_info_plus/package_info_plus.dart';

class Home extends StatefulWidget {
    const Home({super.key, this.initialDatabase});

    /// Notes already loaded by the splash screen. When null (legacy
    /// navigation flows), the state falls back to reading them from disk.
    final Database? initialDatabase;

    @override
    HomeState createState() {
        return HomeState();
    }
}

class HomeState extends State<Home> {
    late Database _database;
    int _notesCount = 0;
    late SharedPreferences _prefs;
    final _selected = <int>{};
    String _viewLayout = 'list';
    String _actionButtons = 'add';
    bool _isInSelectionMode = false;
    String _sortBy = 'date';
    final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
    PackageInfo? _packageInfo;

    Future<String> _getViewPrefFromSP() async {
        _prefs = await SharedPreferences.getInstance();
        if (!_prefs.containsKey('viewLayout')) {
            _prefs.setString('viewLayout', 'list');
        }
        return _prefs.getString('viewLayout') ?? 'list';
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
        return _prefs.getString('sortBy') ?? 'date';
    }

    Future<void> _setSortingPrefToSP(String sortBy) async {
        _prefs = await SharedPreferences.getInstance();
        _prefs.setString('sortBy', sortBy);
    }

    @override
    void initState() {
        super.initState();
        _database = widget.initialDatabase ?? Database();
        _sortNotesBy(_database.note);
        if (widget.initialDatabase == null) {
            // Navigation flows that do not receive the data loaded by the
            // splash screen fall back to reading the notes from disk.
            _loadDatabaseFromDisk().then((database) {
                if (!mounted) return;
                setState(() {
                    _database = database;
                    _notesCount = database.note.length;
                    _sortNotesBy(_database.note);
                });
            });
        } else {
            _notesCount = _database.note.length;
        }
        _getViewPrefFromSP().then((viewLayout) {
            _viewLayout = viewLayout;
        });
        _getSortingPrefFromSP().then((sortBy) {
            _sortBy = sortBy;
            setState(() {
                _sortNotesBy(_database.note);
            });
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
        if (!mounted) return;
        setState(() {
            _packageInfo = info;
        });
    }

    Future<Database> _loadDatabaseFromDisk() async {
        final String noteJson = await DbFileRoutines().readNotes();
        return dbFromJson(noteJson);
    }

    void _sortNotesBy(List<Note> notes) {
        switch (_sortBy) {
            case 'date':
                notes.sort((note1, note2) => note2.date!.compareTo(note1.date!));
                break;
            case 'alpha':
                notes.sort((note1, note2) => note1.title!.compareTo(note2.title!));
                break;
            case 'important':
                notes.sort((note1, note2) => note2.important.toString().compareTo(note1.important.toString()));
                break;
            case 'category':
                notes.sort((note1, note2) => note1.category!.compareTo(note2.category!));
                break;
        }
    }

    void _noteController({required bool add, required int index, required Note note}) async {
        final NoteAction? result = await Navigator.push(
            context,
            MaterialPageRoute<NoteAction>(
                builder: (context) => EditNote(
                    add: add,
                    index: index,
                    noteAction: NoteAction(action: '', note: note),
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
        await DbFileRoutines().writeNotes(dbToJson(_database));
        _notesCount = _database.note.length;
    }

    void _sortingBy(String sortBy) {
        if ('' != sortBy) {
            setState(() {
                _sortBy = sortBy;
                _setSortingPrefToSP(sortBy);
            });
        }
    }

    void _changeLanguage(String language) {
        setState(() {
            LocaleController.instance.setLanguage(language);
        });
    }

    String _deleteActionTitle() {
        if (_selected.length > 1) {
            return _selected.length == _notesCount
                ? AppText.tr('delete_all_notes')
                : AppText.tr('delete_notes', <String, String>{'count': '${_selected.length}'});
        }
        return AppText.tr('delete_note');
    }

    void _changeLayout(String viewLayout) {
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
        if (notes.isEmpty) {
            return noRecordFound();
        }

        switch (viewLayout) {
            case 'compact':
                return _compactLayout(notes);
            case 'list':
                return _listLayout(notes);
            case 'gridlist':
                return _gridLayout(notes);
            default:
                return _listLayout(notes);
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
            },
        );
    }

    Widget _gridLayout(List<Note> notes) {
        return GridView.count(
            crossAxisCount: 3,
            padding: EdgeInsets.symmetric(horizontal: 4.5),
            children: List.generate(notes.length, (index) {
                String title = notes[index].title ?? '';
                String content = notes[index].content ?? '';
                String date = notes[index].date.toString().substring(0, 10);
                final bool important = notes[index].important ?? false;
                return Card(
                    margin: EdgeInsets.all(2.7),
                    elevation: 0.6,
                    color: themeCategory(notes[index].category ?? 'none', false),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(0.0)),
                    ),
                    child: Stack(
                        children: <Widget>[
                            InkWell(
                                child: Container(
                                    color: themeCategory(notes[index].category ?? 'none', true),
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
                                                                title,
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
                                                        content,
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
                                                                date,
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
                            Row(
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
                                                            important ? Icons.star : Icons.star_border,
                                                            color: important ? Colors.orange : null,
                                                            size: 15.0,
                                                        ),
                                                    ),
                                                    onTap: () {
                                                        setState(() {
                                                            notes[index].important = !(notes[index].important ?? false);
                                                            _database.note[index] = notes[index];
                                                            DbFileRoutines().writeNotes(dbToJson(_database));
                                                        });
                                                    },
                                                )
                                            ],
                                        )
                                    ],
                                ),
                            _isInSelectionMode
                            ? GestureDetector(
                                child: Container(
                                    color: _selected.contains(index) ? Colors.black38 : Colors.black12,
                                    child: _selected.contains(index)
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
                String title = notes[index].title ?? '';
                String date = notes[index].date.toString().substring(0, 10);
                final bool important = notes[index].important ?? false;
                return Dismissible(
                    key: Key(notes[index].id ?? ''),
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
                                    color: themeCategory(notes[index].category ?? 'none', false),
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(0.0)),
                                    ),
                                    child: Container(
                                        margin: EdgeInsets.only(left: 2.7),
                                        color: themeCategory(notes[index].category ?? 'none', true),
                                        child: ListTile(
                                            contentPadding: EdgeInsets.only(left: 9.0,),
                                            title: Row(
                                                children: <Widget>[
                                                    Expanded(
                                                        child: Text(
                                                            title,
                                                            style: TextStyle(
                                                                fontSize: 12.0,
                                                                fontWeight: FontWeight.bold
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                        ),
                                                    ),
                                                    SizedBox(width: 9.0,),
                                                    Text(
                                                        date,
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
                                                    important ? Icons.star : Icons.star_border,
                                                    color: important ? Colors.orange : null,
                                                    size: 18.0,
                                                ),
                                                onPressed: () {
                                                    if (_isInSelectionMode) {
                                                        setState(() {
                                                            _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
                                                        });
                                                    } else {
                                                        setState(() {
                                                            notes[index].important = !(notes[index].important ?? false);
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
                        return await getConfirmation(context: context, actionTitle: _deleteActionTitle(), action: AppText.tr('delete'));
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
                String title = notes[index].title ?? '';
                String date = notes[index].date.toString().substring(0, 10);
                final bool important = notes[index].important ?? false;
                return Dismissible(
                    key: Key(notes[index].id ?? ''),
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
                                    color: themeCategory(notes[index].category ?? 'none', false),
                                    shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(0.0)),
                                    ),
                                    child: Container(
                                        margin: EdgeInsets.only(left: 2.7),
                                        color: themeCategory(notes[index].category ?? 'none', true),
                                        child: ListTile(
                                            contentPadding: EdgeInsets.only(left: 9.0,),
                                            title: Text(
                                                title,
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
                                                                    notes[index].content ?? '',
                                                                    maxLines: 3,
                                                                    overflow: TextOverflow.clip,
                                                                    style: TextStyle(
                                                                        fontSize: 12.0,
                                                                    ),
                                                                ),
                                                                Text(
                                                                    date,
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
                                                    important ? Icons.star : Icons.star_border,
                                                    color: important ? Colors.orange : null,
                                                    size: 18.0,
                                                ),
                                                onPressed: () {
                                                    if (_isInSelectionMode) {
                                                        setState(() {
                                                            _selected.contains(index) ? _selected.remove(index) : _selected.add(index);
                                                        });
                                                    } else {
                                                        setState(() {
                                                            notes[index].important = !(notes[index].important ?? false);
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
                        return await getConfirmation(context: context, actionTitle: _deleteActionTitle(), action: AppText.tr('delete'));
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

    List<Widget> _showActionButtons({required String action}) {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                AppText.tr('no_note_selected')
                            ),
                        ),
                    );
                } else {
                    final notes = <Note>[];
                    final bool? confirmDeletion = await getConfirmation(context: context, actionTitle: _deleteActionTitle(), action: AppText.tr('delete'));
                    if (confirmDeletion == true) {
                        setState(() {
                            for (final int index in _selected) {
                                notes.add(_database.note[index]);
                            }
                            for (final Note note in notes) {
                                _database.note.remove(note);
                            }
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
                    for (final Note note in _database.note) {
                        _selected.add(_database.note.indexOf(note));
                    }
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
            case 'multiple':
                return <Widget>[
                    Expanded(flex: 1, child: cancelActionButton,),
                    Expanded(flex: 1, child: deleteActionButton,),
                    Expanded(flex: 1, child: selectNoneActionButton,),
                    Expanded(flex: 1, child: selectAllActionButton,),
                ];
            default:
                return <Widget>[
                    Expanded(flex: 1, child: addActionButton,),
                ];
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
                                case "en":
                                case "fr":
                                    _changeLanguage(valueSelected.value);
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
                                    height: 42.0,                                                    child: popupButton(popupItem: popupItem, layout: _viewLayout, sort: _sortBy, lang: LocaleController.instance.language),
                                );
                            }).toList();
                        },
                        padding: EdgeInsets.all(0.0),
                    ),
                ],
            ),
            body: Column(
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
                                                Expanded(                                                        child: Text(
                                                            AppText.tr('all_notes'),
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
                                                            '$_notesCount ${_notesCount > 1 ? AppText.tr('notes') : AppText.tr('note')}',
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
                                                            AppText.tr('search'),
                                                            style: TextStyle(
                                                                fontWeight: FontWeight.w400,
                                                                fontSize: 14.4,
                                                                color: Colors.grey.shade600
                                                            ),
                                                        ),
                                                        onTap: () {
                                                            if (!_isInSelectionMode) {
                                                                Navigator.of(context).pushNamed('/search');
                                                            }
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
                                            _selected.isEmpty
                                                ? AppText.tr('no_note_selected')
                                                : (_selected.length > 1
                                                    ? (_selected.length == _notesCount ? AppText.tr('all_notes_selected', <String, String>{'count': '$_notesCount'}) : AppText.tr('notes_selected', <String, String>{'count': '${_selected.length}', 'total': '$_notesCount'}))
                                                    : AppText.tr('single_note_selected', <String, String>{'count': '${_selected.length}'})),
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
                                            AppText.tr('sorted_by', <String, String>{'sort': (menuItems[_sortBy]?.title ?? '').toLowerCase()}),
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
                            child: _layoutChanger(_database.note, _viewLayout),
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
                        children: _showActionButtons(action: _actionButtons),
                    ),
                ),
            ),
//            drawer: DrawerMenu(),
        );
    }
}