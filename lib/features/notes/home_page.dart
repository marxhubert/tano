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
    double offset = scaffoldGeometry.contentBottom -
        scaffoldGeometry.floatingActionButtonSize.height -
        padding;
    if (scaffoldGeometry.snackBarSize.height > 0.0) {
      // Push the FAB up so it stays above the SnackBar.
      offset -= (scaffoldGeometry.snackBarSize.height - 12.0);
    }
    return offset;
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
  final ScrollController _scrollController = ScrollController();
  bool _isSearchMode = false;
  bool _showAppBarTitle = false;
  bool _wasInSelectionMode = false;
  static const _sliverPadding = 12.0;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      repository: widget.repository,
      initialNotes: widget.initialNotes,
    );
    _wasInSelectionMode = _viewModel.isInSelectionMode;
    if (widget.initialNotes == null) {
      // Navigation flows that do not receive the data loaded by the
      // splash screen fall back to loading the notes themselves.
      _viewModel.load();
    }
    _loadPreferences();
    _initPackageInfo();
    _scrollController.addListener(_onScroll);
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.isInSelectionMode && _isSearchMode) {
      setState(() {
        _isSearchMode = false;
      });
      _searchFocusNode.unfocus();
    } else if (_wasInSelectionMode && !_viewModel.isInSelectionMode) {
      // We just exited selection mode: clear search to return to the full list.
      if (_viewModel.hasSearchQuery) {
        _clearSearch();
      }
    }
    _wasInSelectionMode = _viewModel.isInSelectionMode;
  }

  void _onScroll() {
    final bool showTitle = _scrollController.offset > 120;
    if (showTitle != _showAppBarTitle) {
      setState(() {
        _showAppBarTitle = showTitle;
      });
    }
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
      _SelectionActionButton(
        icon: Icons.delete,
        label: AppText.tr('delete'),
        color: Colors.red,
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
      _SelectionActionButton(
        icon: Icons.check_box_outline_blank,
        label: AppText.tr('select_none'),
        onPressed: _viewModel.clearSelection,
      ),
      _SelectionActionButton(
        icon: Icons.select_all,
        label: AppText.tr('select_all'),
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
                  title: _showAppBarTitle
                      ? Text(
                          AppText.tr('all_notes'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18.0,
                            letterSpacing: -1.0,
                          ),
                        )
                      : null,
                  centerTitle: true,
                  actions: <Widget>[
                    TextButton(
                      onPressed: _viewModel.exitSelectionMode,
                      child: Text(
                        AppText.tr('cancel'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                  elevation: 0.0,
                )
              : AppBar(
                  elevation: 0.0,
                  title: _showAppBarTitle
                      ? Text(
                          AppText.tr('all_notes'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18.0,
                            letterSpacing: -1.0,
                          ),
                        )
                      : null,
                  centerTitle: true,
                  actions: _isSearchMode
                      ? <Widget>[
                          TextButton(
                            onPressed: _exitSearchMode,
                            child: Text(
                              AppText.tr('cancel'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ]
                      : <Widget>[
                          IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: _enterSearchMode,
                          ),
                          PopupMenuButton<PopupItem>(
                            icon: const Icon(Icons.more_vert),
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
                                  ThemeController.instance
                                      .setThemeMode(ThemeMode.light);
                                  break;
                                case "theme_dark":
                                  ThemeController.instance
                                      .setThemeMode(ThemeMode.dark);
                                  break;
                                case "theme_system":
                                  ThemeController.instance
                                      .setThemeMode(ThemeMode.system);
                                  break;
                                case "en":
                                case "fr":
                                  _changeLanguage(valueSelected.value);
                                  break;
                                case "info":
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) =>
                                        aboutInfo(
                                      context: context,
                                      packageInfo: _packageInfo,
                                    ),
                                  );
                                  break;
                              }
                            }),
                            itemBuilder: (BuildContext context) {
                              final List<PopupItem> popupItems = [];
                              menuItems
                                  .forEach((String key, PopupItem popupItem) {
                                popupItems.add(popupItem);
                              });
                              return popupItems.map((PopupItem popupItem) {
                                return PopupMenuItem<PopupItem>(
                                  value: popupItem,
                                  height: popupItem.value == 'separator'
                                      ? 8.0
                                      : 28.0,
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
                            padding: EdgeInsets.only(right: 12.0),
                          ),
                        ],
                ),
          body: CustomScrollView(
            controller: _scrollController,
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
          floatingActionButton: HomeFab(
            isSearchMode: _isSearchMode,
            isSelectionMode: _viewModel.isInSelectionMode,
            controller: _searchController,
            focusNode: _searchFocusNode,
            onAdd: () {
              _openNoteEditor(add: true, note: Note());
            },
            onSearchChanged: (String value) {
              _viewModel.setSearchQuery(value);
            },
            onReset: _clearSearch,
            onDelete: () async {
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
            onClearSelection: _viewModel.clearSelection,
            onSelectAll: _viewModel.selectAll,
          ),
          bottomNavigationBar: null,
        );
      },
    );
  }
}

class _SelectionActionButton extends StatelessWidget {
  const _SelectionActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 24.0, color: color),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.0,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
