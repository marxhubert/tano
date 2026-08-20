import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/features/notes/widgets/note_grid_view.dart';
import 'package:tano/features/notes/widgets/note_list_view.dart';
import 'package:tano/features/notes/widgets/search_fab.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/widgets/menu.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/info.dart';
import 'package:tano/shared/widgets/no_record.dart';
import 'package:tano/shared/widgets/action_bar.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Places the floating action button flush against the bottom-right corner
/// of the screen (no margin).
class _FlushEndFabLocation extends StandardFabLocation {
  static const padding = 24;
  const _FlushEndFabLocation();

  @override
  double getOffsetX(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
    return scaffoldGeometry.scaffoldSize.width -
        scaffoldGeometry.floatingActionButtonSize.width - padding;
  }

  @override
  double getOffsetY(
    ScaffoldPrelayoutGeometry scaffoldGeometry,
    double adjustment,
  ) {
    // Use contentBottom so the field stays above the soft keyboard.
    return scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height -
        padding;
  }
}

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchMode = false;
  static const _sliverPadding = 12.0;

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
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    required Note note,
  }) async {
    final NoteAction? result = await Navigator.push(
      context,
      MaterialPageRoute<NoteAction>(
        builder: (context) => EditNote(
          add: add,
          index: -1,
          noteAction: NoteAction(note: note),
          repository: widget.repository,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result == null) {
      return;
    }
    await _viewModel.applyNoteAction(
      add: add,
      originalId: note.id,
      action: result,
    );
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

  void _clearSearch() {
    _searchController.clear();
    _viewModel.setSearchQuery('');
  }

  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _exitSearchMode() {
    _clearSearch();
    setState(() {
      _isSearchMode = false;
    });
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
      if (_viewModel.hasSearchQuery) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(
              AppText.tr('no_note_found'),
              style: TextStyle(fontSize: 12.0),
            ),
          ),
        );
      }
      return SliverFillRemaining(
        hasScrollBody: false,
        child: noRecordFound(context),
      );
    }

    switch (viewLayout) {
      case 'gridlist':
        return NoteGridView(
          viewModel: _viewModel,
          onOpenNote: (Note note) {
            _openNoteEditor(add: false, note: note);
          },
        );
      case 'list':
      default:
        return NoteListView(
          viewModel: _viewModel,
          onOpenNote: (Note note) {
            _openNoteEditor(add: false, note: note);
          },
          onShowUndoSnackBar: _showUndoSnackBar,
          confirmDelete: _confirmDelete,
        );
    }
  }

  Future<bool?> _confirmDelete() {
    return getConfirmation(
      context: context,
      actionTitle: _deleteActionTitle(),
      action: AppText.tr('delete'),
    );
  }

  List<Widget> _showActionButtons() {
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
                      icon: Icon(Icons.search),
                      onPressed: _enterSearchMode,
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
                          case "theme_light":
                            ThemeController.instance.setThemeMode(ThemeMode.light);
                            break;
                          case "theme_dark":
                            ThemeController.instance.setThemeMode(ThemeMode.dark);
                            break;
                          case "theme_system":
                            ThemeController.instance.setThemeMode(ThemeMode.system);
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
          body: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_sliverPadding, _sliverPadding, _sliverPadding, 0.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          AppText.tr('all_notes'),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 24.0,
                            letterSpacing: -2.0,
                          ),
                        ),
                      ),
                      _viewModel.isInSelectionMode
                      ? Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
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
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      : Text(
                        '${_viewModel.notesCount} ${_viewModel.notesCount > 1 ? AppText.tr('notes') : AppText.tr('note')}',
                        style: TextStyle(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(_sliverPadding),
                sliver: _layoutChanger(_viewModel.notes, _viewModel.viewLayout),
              ),
            ],
          ),
          floatingActionButtonLocation: const _FlushEndFabLocation(),
          floatingActionButton: _viewModel.isInSelectionMode
            ? null
            : SearchFab(
                isSearchMode: _isSearchMode,
                controller: _searchController,
                focusNode: _searchFocusNode,
                onAdd: () {
                  _openNoteEditor(add: true, note: Note());
                },
                onSearchChanged: (String value) {
                  _viewModel.setSearchQuery(value);
                },
                onReset: _clearSearch,
                onClose: _exitSearchMode,
              ),
          bottomNavigationBar: _viewModel.isInSelectionMode
            ? BottomAppBar(
                elevation: 0.0,
                height: 36.0,
                padding: EdgeInsets.zero,
                color: barColor(context),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _showActionButtons(),
                ),
              )
            : null,
        );
      },
    );
  }
}
