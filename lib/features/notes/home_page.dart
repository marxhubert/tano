import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/features/search/search_page.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/widgets/menu.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/info.dart';
import 'package:tano/shared/widgets/no_record.dart';
import 'package:tano/shared/widgets/action_bar.dart';
import 'package:tano/shared/widgets/theme.dart';

class Home extends StatefulWidget {
  const Home({super.key, required this.repository, this.initialNotes});

  final NotesRepository repository;

  /// Notes already loaded by the splash screen. When null (legacy
  /// navigation flows), the view model falls back to loading them.
  final List<Note>? initialNotes;

  @override
  HomeState createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> {
  late final HomeViewModel _viewModel;
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      repository: widget.repository,
      initialNotes: widget.initialNotes,
    );
    if (widget.initialNotes == null) {
      // Navigation flows that do not receive the data loaded by the
      // splash screen fall back to loading the notes themselves.
      _viewModel.load();
    }
    _loadPreferences();
    _initPackageInfo();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final PackageInfo info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _packageInfo = info;
    });
  }

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();

  Future<void> _loadPreferences() async {
    final SharedPreferences prefs = await _getPrefs();
    if (!prefs.containsKey('viewLayout')) {
      await prefs.setString('viewLayout', 'list');
    }
    _viewModel.setViewLayout(prefs.getString('viewLayout') ?? 'list');
    if (!prefs.containsKey('sortBy')) {
      await prefs.setString('sortBy', 'date');
    }
    _viewModel.setSortBy(prefs.getString('sortBy') ?? 'date');
  }

  Future<void> _saveViewLayoutPref(String viewLayout) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString('viewLayout', viewLayout);
  }

  Future<void> _saveSortingPref(String sortBy) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString('sortBy', sortBy);
  }

  Future<void> _openNoteEditor({
    required bool add,
    required int index,
    required Note note,
  }) async {
    final NoteAction? result = await Navigator.push(
      context,
      MaterialPageRoute<NoteAction>(
        builder: (context) => EditNote(
          add: add,
          index: index,
          noteAction: NoteAction(note: note),
          repository: widget.repository,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result == null) {
      return;
    }
    await _viewModel.applyNoteAction(add: add, index: index, action: result);
  }

  void _sortingBy(String sortBy) {
    _viewModel.setSortBy(sortBy);
    _saveSortingPref(sortBy);
  }

  void _changeLayout(String viewLayout) {
    _viewModel.setViewLayout(viewLayout);
    _saveViewLayoutPref(viewLayout);
  }

  void _changeLanguage(String language) {
    LocaleController.instance.setLanguage(language);
  }

  String _deleteActionTitle() {
    if (_viewModel.selectedCount > 1) {
      return _viewModel.selectedCount == _viewModel.notesCount
          ? AppText.tr('delete_all_notes')
          : AppText.tr('delete_notes', <String, String>{
              'count': '${_viewModel.selectedCount}',
            });
    }
    return AppText.tr('delete_note');
  }

  void _showUndoSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppText.tr('note_deleted')),
        action: SnackBarAction(
          label: AppText.tr('undo'),
          onPressed: () {
            _viewModel.undoLastDelete();
          },
        ),
      ),
    );
  }

  Widget _layoutChanger(List<Note> notes, String viewLayout) {
    if (notes.isEmpty) {
      return noRecordFound(context);
    }

    switch (viewLayout) {
      case 'list':
        return _listLayout(notes);
      case 'gridlist':
        return _gridLayout(notes);
      default:
        return _listLayout(notes);
    }
  }

  Widget _showCheckboxForSelection(int index, bool alreadySelected) {
    if (!_viewModel.isInSelectionMode) {
      return Container(child: null);
    }

    return Checkbox(
      value: alreadySelected,
      onChanged: (value) {
        _viewModel.toggleSelection(index);
      },
    );
  }

  Widget _gridLayout(List<Note> notes) {
    return GridView.count(
      crossAxisCount: 3,
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      children: List.generate(notes.length, (index) {
        String title = notes[index].title;
        String content = notes[index].content;
        String date = formatNoteDate(notes[index].date);
        final bool isSelected = _viewModel.selected.contains(index);
        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: themeCategory(
              notes[index].category,
              false,
              brightness: Theme.of(context).brightness,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 2.0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              InkWell(
                child: Container(
                  color: themeCategory(
                    notes[index].category,
                    true,
                    brightness: Theme.of(context).brightness,
                  ),
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
                                  fontSize: 12.0,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Padding(padding: EdgeInsets.only(bottom: 1.8)),
                        Expanded(
                          flex: 1,
                          child: Text(
                            content,
                            style: TextStyle(fontSize: 10.8),
                            overflow: TextOverflow.clip,
                            maxLines: null,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            SizedBox(height: 14.4),
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
                  if (_viewModel.isInSelectionMode) {
                    _viewModel.toggleSelection(index);
                  } else {
                    _openNoteEditor(
                      add: false,
                      index: index,
                      note: notes[index],
                    );
                  }
                },
                onLongPress: () {
                  _viewModel.enterSelectionMode(index);
                },
              ),
              _viewModel.isInSelectionMode
                  ? GestureDetector(
                      child: Container(
                        color: isSelected ? Colors.black38 : Colors.black12,
                        child: isSelected
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
                                    child: Icon(
                                      Icons.check_circle,
                                      size: 45.0,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Icon(
                                  Icons.panorama_fish_eye,
                                  size: 45.0,
                                  color: Colors.black54,
                                ),
                              ),
                      ),
                      onTap: () {
                        _viewModel.toggleSelection(index);
                      },
                    )
                  : Offstage(),
            ],
          ),
        );
      }),
    );
  }

  Widget _listLayout(List<Note> notes) {
    return ListView.separated(
      itemCount: notes.length,
      padding: EdgeInsets.symmetric(horizontal: 12.0),
      itemBuilder: (BuildContext context, int index) {
        final alreadySelected = _viewModel.selected.contains(index);
        String title = notes[index].title;
        String date = formatNoteDate(notes[index].date);
        final bool important = notes[index].important;
        return Dismissible(
          key: Key(notes[index].id),
          background: Container(
            color: Colors.orange,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: 21.0),
            child: Icon(
              important ? Icons.star_border : Icons.star,
              color: Colors.white,
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
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: themeCategory(
                      notes[index].category,
                      false,
                      brightness: Theme.of(context).brightness,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 2.0,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Container(
                    color: themeCategory(
                      notes[index].category,
                      true,
                      brightness: Theme.of(context).brightness,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.only(left: 9.0),
                      title: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 9.0),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 9.0,
                              color: mutedTextColor(context),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        notes[index].content,
                        maxLines: 3,
                        overflow: TextOverflow.clip,
                        style: TextStyle(fontSize: 12.0),
                      ),
                      onTap: () {
                        if (_viewModel.isInSelectionMode) {
                          _viewModel.toggleSelection(index);
                        } else {
                          _openNoteEditor(
                            add: false,
                            index: index,
                            note: notes[index],
                          );
                        }
                      },
                      onLongPress: () {
                        _viewModel.enterSelectionMode(index);
                      },
                    ),
                  ),
                ),
              ),
              _showCheckboxForSelection(index, alreadySelected),
            ],
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              _viewModel.toggleFavorite(index);
              return false;
            }
            return await getConfirmation(
              context: context,
              actionTitle: _deleteActionTitle(),
              action: AppText.tr('delete'),
            );
          },
          onDismissed: (direction) {
            _viewModel.removeNote(index);
            _showUndoSnackBar();
          },
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return SizedBox(height: 12.0);
      },
    );
  }

  List<Widget> _showActionButtons({required String action}) {
    final Widget addActionButton = BottomActionButton(
      icon: Icons.add,
      onPressed: () {
        _openNoteEditor(add: true, index: -1, note: Note());
      },
    );

    switch (action) {
      case 'add':
        return <Widget>[addActionButton];
      case 'multiple':
        return <Widget>[
          BottomActionButton(
            icon: Icons.arrow_back,
            onPressed: _viewModel.exitSelectionMode,
          ),
          BottomActionButton(
            icon: Icons.clear,
            onPressed: () async {
              if (!_viewModel.hasSelection) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(AppText.tr('no_note_selected'))),
                );
              } else {
                final bool? confirmDeletion = await getConfirmation(
                  context: context,
                  actionTitle: _deleteActionTitle(),
                  action: AppText.tr('delete'),
                );
                if (confirmDeletion == true) {
                  await _viewModel.deleteSelected();
                  _showUndoSnackBar();
                }
              }
            },
          ),
          BottomActionButton(
            icon: Icons.panorama_fish_eye,
            iconSize: 21.0,
            onPressed: _viewModel.clearSelection,
          ),
          BottomActionButton(
            icon: Icons.check_circle,
            iconSize: 21.0,
            onPressed: _viewModel.selectAll,
          ),
        ];
      default:
        return <Widget>[addActionButton];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          key: _scaffoldState,
          appBar: _viewModel.isInSelectionMode
              ? AppBar(
                  automaticallyImplyLeading: false,
                  actions: <Widget>[
                    IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: () {
                        _viewModel.exitSelectionMode();
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
                        _openNoteEditor(add: true, index: -1, note: Note());
                      },
                    ),
                    PopupMenuButton<ThemeMode>(
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                      ),
                      onSelected: (ThemeMode mode) {
                        ThemeController.instance.setThemeMode(mode);
                      },
                      itemBuilder: (BuildContext context) {
                        final ThemeMode current =
                            ThemeController.instance.themeMode;
                        return <PopupMenuEntry<ThemeMode>>[
                          CheckedPopupMenuItem<ThemeMode>(
                            value: ThemeMode.light,
                            checked: current == ThemeMode.light,
                            child: Text(AppText.tr('theme_light')),
                          ),
                          CheckedPopupMenuItem<ThemeMode>(
                            value: ThemeMode.dark,
                            checked: current == ThemeMode.dark,
                            child: Text(AppText.tr('theme_dark')),
                          ),
                          CheckedPopupMenuItem<ThemeMode>(
                            value: ThemeMode.system,
                            checked: current == ThemeMode.system,
                            child: Text(AppText.tr('theme_system')),
                          ),
                        ];
                      },
                    ),
                    PopupMenuButton<PopupItem>(
                      icon: Icon(Icons.more_vert),
                      onSelected: ((valueSelected) {
                        switch (valueSelected.value.toLowerCase()) {
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
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => aboutInfo(
                                context: context,
                                packageInfo: _packageInfo,
                              ),
                            );
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
                            height: popupItem.value == 'separator' ? 8.0 : 28.0,
                            child: popupButton(
                              context: context,
                              popupItem: popupItem,
                              layout: _viewModel.viewLayout,
                              sort: _viewModel.sortBy,
                              lang: LocaleController.instance.language,
                            ),
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
                padding: EdgeInsets.symmetric(horizontal: 12.0),
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
                              AppText.tr('all_notes'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 21.0,
                              ),
                            ),
                          ),
                          Column(
                            children: <Widget>[
                              Text(
                                '${_viewModel.notesCount} ${_viewModel.notesCount > 1 ? AppText.tr('notes') : AppText.tr('note')}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _viewModel.notesCount == 0
                        ? Offstage()
                        : Container(
                            height: 36.0,
                            padding: EdgeInsets.symmetric(horizontal: 18.0),
                            margin: EdgeInsets.only(bottom: 4.5),
                            decoration: BoxDecoration(
                              color: chipFillColor(context),
                              borderRadius: BorderRadius.circular(54.0),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(Icons.search, size: 21.0),
                                SizedBox(width: 9.0),
                                Expanded(
                                  child: GestureDetector(
                                    child: Text(
                                      AppText.tr('search'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14.4,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    onTap: () {
                                      if (!_viewModel.isInSelectionMode) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute<void>(
                                            builder: (BuildContext context) =>
                                                SearchPage(
                                                  repository: widget.repository,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                    _viewModel.isInSelectionMode
                        ? Container(
                            margin: EdgeInsets.only(bottom: 4.5),
                            child: Text(
                              _viewModel.selected.isEmpty
                                  ? AppText.tr('no_note_selected')
                                  : (_viewModel.selectedCount > 1
                                        ? (_viewModel.selectedCount ==
                                                  _viewModel.notesCount
                                              ? AppText.tr(
                                                  'all_notes_selected',
                                                  <String, String>{
                                                    'count':
                                                        '${_viewModel.notesCount}',
                                                  },
                                                )
                                              : AppText.tr('notes_selected', <
                                                  String,
                                                  String
                                                >{
                                                  'count':
                                                      '${_viewModel.selectedCount}',
                                                  'total':
                                                      '${_viewModel.notesCount}',
                                                }))
                                        : AppText.tr(
                                            'single_note_selected',
                                            <String, String>{
                                              'count':
                                                  '${_viewModel.selectedCount}',
                                            },
                                          )),
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w400,
                                fontSize: 12.0,
                              ),
                            ),
                          )
                        : _viewModel.notesCount > 0
                        ? Container(
                            margin: EdgeInsets.only(bottom: 4.5),
                            alignment: Alignment.center,
                            child: Text(
                              AppText.tr('sorted_by', <String, String>{
                                'sort':
                                    (menuItems[_viewModel.sortBy]?.title ?? '')
                                        .toLowerCase(),
                              }),
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
                child: _layoutChanger(_viewModel.notes, _viewModel.viewLayout),
              ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            elevation: 0.0,
            height: 36.0,
            padding: EdgeInsets.zero,
            color: barColor(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _showActionButtons(action: _viewModel.actionButtons),
            ),
          ),
        );
      },
    );
  }
}
