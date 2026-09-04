import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/features/notes/widgets/note_grid_view.dart';
import 'package:tano/features/notes/widgets/note_list_view.dart';
import 'package:tano/shared/widgets/app_fab.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/widgets/menu.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/no_record.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/config/route_observer.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';

class Home extends StatefulWidget {
  const Home({super.key, this.initialNotes});

  /// Notes already loaded by the splash screen. When null (legacy
  /// navigation flows), the view model falls back to loading them.
  final List<Note>? initialNotes;

  @override
  HomeState createState() {
    return HomeState();
  }
}

class HomeState extends State<Home> with RouteAware {
  late final HomeViewModel _viewModel;
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchMode = false;
  bool _wasInSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel(
      repository: getIt<NotesRepository>(),
      initialNotes: widget.initialNotes,
    );
    _wasInSelectionMode = _viewModel.isInSelectionMode;
    if (widget.initialNotes == null) {
      // Navigation flows that do not receive the data loaded by the
      // splash screen fall back to loading the notes themselves.
      _viewModel.load();
    }
    _loadPreferences();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of<void>(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  /// Called when another route (editor, settings, ...) is pushed on top of
  /// Home. Dismiss the undo snack bar immediately so it does not linger if
  /// the user comes back before its timeout.
  @override
  void didPushNext() {
    ScaffoldMessenger.of(context).clearSnackBars();
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

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();

  Future<void> _loadPreferences() async {
    final SharedPreferences prefs = await _getPrefs();
    if (!prefs.containsKey('viewLayout')) {
      await prefs.setString('viewLayout', 'gridlist');
    }
    _viewModel.setViewLayout(prefs.getString('viewLayout') ?? 'gridlist');
    if (!prefs.containsKey('sortBy')) {
      await prefs.setString('sortBy', 'date');
    }
    _viewModel.setSortBy(prefs.getString('sortBy') ?? 'date');

    if (!prefs.containsKey('secondarySortBy')) {
      await prefs.setString('secondarySortBy', 'date');
    }
    _viewModel.setSecondarySortBy(prefs.getString('secondarySortBy') ?? 'date');

    if (!prefs.containsKey('sortAscending')) {
      await prefs.setBool('sortAscending', true);
    }
    _viewModel.setSortAscending(prefs.getBool('sortAscending') ?? true);
  }

  Future<void> _saveViewLayoutPref(String viewLayout) async {
    final SharedPreferences prefs = await _getPrefs();
    await prefs.setString('viewLayout', viewLayout);
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
          noteAction: NoteAction(kind: NoteActionKind.cancel, note: note),
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      await _viewModel.applyNoteAction(
        add: add,
        originalId: note.id,
        action: result,
      );
    }
    // The editor may persist changes directly (auto-save on bookmark/category/
    // pin, or the back-navigation "save" action) without returning a
    // NoteAction. Refresh the list so it always reflects the latest persisted
    // state.
    await _viewModel.load();
  }

  void _changeLayout(String viewLayout) {
    _viewModel.setViewLayout(viewLayout);
    _saveViewLayoutPref(viewLayout);
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
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(AppText.tr('note_deleted')),
          duration: const Duration(seconds: 3),
          // A SnackBar with an action defaults to persist: true, which makes
          // the timeout a no-op. Opt back into the timed auto-dismiss.
          persist: false,
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
              style: const TextStyle(fontSize: 12.0),
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

  List<Widget>? _buildAppBarActions() {
    if (_viewModel.isInSelectionMode) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: TextButton(
            onPressed: _viewModel.exitSelectionMode,
            child: Text(
              AppText.tr('cancel'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
          ),
        ),
      ];
    }
    if (_isSearchMode) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: TextButton(
            onPressed: _exitSearchMode,
            child: Text(
              AppText.tr('cancel'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
              ),
            ),
          ),
        ),
      ];
    }
    return <Widget>[
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: _enterSearchMode,
      ),
      const ThemeToggleButton(),
      PopupMenuButton<PopupItem>(
        icon: const Icon(Icons.more_vert),
        offset: const Offset(0, 56),
        elevation: 4.0,
        constraints: const BoxConstraints(minWidth: 160.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(appBorderRadius),
        ),
        onSelected: ((valueSelected) async {
          switch (valueSelected.value.toLowerCase()) {
            case "list":
              _changeLayout('list');
              break;
            case "gridlist":
              _changeLayout('gridlist');
              break;
            case "settings":
              await Navigator.of(context).pushNamed('/settings');
              _loadPreferences();
              await _viewModel.load();
              break;
          }
        }),
        itemBuilder: (BuildContext context) {
          final List<PopupItem> popupItems = [];
          menuItems.forEach((String key, PopupItem popupItem) {
            popupItems.add(popupItem);
          });
          return popupItems.map((PopupItem popupItem) {
            if (popupItem.value == 'separator') {
              return const PopupMenuDivider(height: 1.0) as PopupMenuEntry<PopupItem>;
            }
            return PopupMenuItem<PopupItem>(
              value: popupItem,
              height: 38.0,
              padding: EdgeInsets.zero,
              child: popupButton(
                context: context,
                popupItem: popupItem,
                layout: _viewModel.viewLayout,
                lang: LocaleController.instance.language,
              ),
            );
          }).toList();
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (BuildContext context, Widget? child) {
        return PageScaffold(
          title: AppText.tr('all_notes'),
          isHome: true,
          scaffoldKey: _scaffoldState,
          actions: _buildAppBarActions(),
          headerTrailing: _viewModel.isInSelectionMode
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
                                        'count': '${_viewModel.notesCount}',
                                      },
                                    )
                                  : AppText.tr('notes_selected', <String,
                                      String>{
                                      'count': '${_viewModel.selectedCount}',
                                      'total': '${_viewModel.notesCount}',
                                    }))
                              : AppText.tr(
                                  'single_note_selected',
                                  <String, String>{
                                    'count': '${_viewModel.selectedCount}',
                                  },
                                )),
                      style: const TextStyle(
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
                    color: mutedTextColor(context),
                    fontWeight: FontWeight.w400,
                    fontSize: 13.0,
                  ),
                ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(appPaddingMedium),
              sliver: _layoutChanger(_viewModel.notes, _viewModel.viewLayout),
            ),
          ],
          floatingActionButtonLocation: const FlushEndFabLocation(),
          floatingActionButton: AppFab(
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
                // TODO: No action needed for now, maybe show a hint?
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
        );
      },
    );
  }
}
