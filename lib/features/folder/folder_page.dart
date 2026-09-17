import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/shared/controllers/selection_controller.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/shared/config/card_sorting.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/shared/config/route_observer.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/manageable_cover.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/empty_state.dart';

/// Shows the notes filed in a single folder and its organisation actions.
class FolderPage extends StatefulWidget {
  const FolderPage({super.key, required this.folder});

  final Folder folder;

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> with RouteAware {
  final GlobalKey<AppFabState> _fabKey = GlobalKey<AppFabState>();
  final AttachmentsStore _attachmentsStore = AttachmentsStore();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();

  late Folder _folder;
  List<Note> _notes = <Note>[];
  Set<String> _activeNoteIds = <String>{};
  bool _loading = true;
  bool _isSearchMode = false;
  bool _searchStarted = false;
  bool _isEditingTitle = false;
  String _searchQuery = '';
  String _viewLayout = 'gridlist';
  String _sortBy = 'date';
  String _secondarySortBy = 'date';
  bool _sortAscending = true;
  final SelectionController _selection = SelectionController();

  FoldersRepository? get _foldersRepository {
    final NotesRepository repository = getIt<NotesRepository>();
    return repository is FoldersRepository
        ? repository as FoldersRepository
        : null;
  }

  @override
  void initState() {
    super.initState();
    _folder = widget.folder;
    _titleFocusNode.addListener(_onTitleFocusChanged);
    _loadPreferences();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of<void>(context);
    if (route != null) {
      routeObserver.subscribe(this, route);
    }
  }

  /// Called when another route (the editor, ...) is pushed on top of this page.
  /// Fold the FAB once the page is fully covered, so it is already back in its
  /// resting form when the user returns.
  @override
  void didPushNext() {
    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _fabKey.currentState?.collapse();
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    _selection.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _viewLayout = prefs.getString('viewLayout') ?? 'gridlist';
      _sortBy = prefs.getString('sortBy') ?? 'date';
      _secondarySortBy = prefs.getString('secondarySortBy') ?? 'date';
      _sortAscending = prefs.getBool('sortAscending') ?? true;
      _notes = _sorted(_notes);
    });
  }

  /// Notes sorted like the home screen: pinned first, then the chosen
  /// criterion. Without this the folder kept the raw repository order.
  List<Note> _sorted(List<Note> notes) => NoteSorting(
        by: _sortBy,
        secondaryBy: _secondarySortBy,
        ascending: _sortAscending,
      ).sort(notes);

  Future<void> _load() async {
    final List<Note> all = await getIt<NotesRepository>().loadNotes();
    if (!mounted) return;
    setState(() {
      _activeNoteIds = all
          .where((Note note) => !note.isDeleted)
          .map((Note note) => note.id)
          .toSet();
      _notes = _sorted(
        all.where((Note note) => note.folderId == _folder.id).toList(),
      );
      _loading = false;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _enterSearchMode() {
    setState(() {
      _isSearchMode = true;
      _searchStarted = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _isSearchMode) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _exitSearchMode() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchMode = false;
      _searchStarted = false;
      _searchQuery = '';
    });
  }

  Future<void> _save(Folder folder) async {
    final Folder updated =
        folder.copyWith(updatedAt: DateTime.now().toString());
    await _foldersRepository?.upsertFolder(updated);
    if (!mounted) return;
    setState(() => _folder = updated);
  }

  void _onTitleFocusChanged() {
    if (!_titleFocusNode.hasFocus) {
      _exitTitleEdit();
    }
  }

  /// Puts the folder title in edit mode: the name becomes an editable field,
  /// the caret blinks right after it and the keyboard opens.
  void _startTitleEdit() {
    _fabKey.currentState?.closeVerticalMenu();
    _titleController.text = _folder.name;
    _titleController.selection = TextSelection.collapsed(
      offset: _folder.name.length,
    );
    setState(() => _isEditingTitle = true);
  }

  /// Leaves title edit mode and silently stores the new name when it changed.
  Future<void> _exitTitleEdit() async {
    if (!_isEditingTitle) return;
    final String name = _titleController.text.trim();
    setState(() => _isEditingTitle = false);
    _titleFocusNode.unfocus();
    if (name.isEmpty || name == _folder.name) return;
    await _save(_folder.copyWith(name: name));
  }

  Future<void> _openNote({required bool add, required Note note}) async {
    // Opening a note leaves the search: coming back shows the whole folder.
    if (_isSearchMode) _exitSearchMode();
    // A locked note always asks for the system credential, unless the folder
    // itself is locked: opening it already authenticated the user.
    bool authenticated = _folder.isLocked;
    if (note.isLocked && !authenticated) {
      authenticated = await getIt<AuthService>().authenticate(
        reason: AppText.tr('auth_reason'),
      );
      if (!authenticated || !mounted) return;
    }
    final NoteAction? result = await Navigator.push<NoteAction>(
      context,
      MaterialPageRoute<NoteAction>(
        builder: (BuildContext context) => EditNote(
          add: add,
          index: -1,
          noteAction: NoteAction(kind: NoteActionKind.cancel, note: note),
          authenticated: authenticated,
        ),
      ),
    );
    if (result != null && result.note != null) {
      await getIt<NotesRepository>().upsertNote(result.note!);
    }
    await _load();
  }

  Note _newNote() => Note(folderId: _folder.id, category: _folder.category);

  Future<void> _selectCover() async {
    final PlatformFile? result = await FilePicker.pickFile(
      type: FileType.image,
    );
    final String? path = result?.path;
    if (path == null) return;
    final String name = await _attachmentsStore.import(path, result!.name);
    await _save(_folder.copyWith(coverImage: name));
  }

  Future<void> _toggleLock() async {
    if (!_folder.isLocked) {
      if (!await getIt<AuthService>().isAvailable()) {
        if (!mounted) return;
        await showAdaptiveAlert(
          context: context,
          title: AppText.tr('lock_unavailable_title'),
          message: AppText.tr('lock_requires_device_lock'),
        );
        return;
      }
      await _save(_folder.copyWith(isLocked: true));
      return;
    }
    final bool authenticated = await getIt<AuthService>().authenticate(
      reason: AppText.tr('auth_reason'),
    );
    if (!authenticated || !mounted) return;
    await _save(_folder.copyWith(isLocked: false));
  }

  Future<void> _delete() async {
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: AppText.tr('delete_folder'),
      action: AppText.tr('delete'),
      message: AppText.tr('delete_folder_question', <String, String>{
        'count': '${_notes.length}',
      }),
    );
    if (confirm != true || !mounted) return;

    // The folder keeps its notes: they stay filed and travel with it.
    await _foldersRepository?.trashFolder(_folder.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _enterSelection(String id) {
    // Keep the search active: the selection stays scoped to the results.
    setState(() => _selection.enter(id));
  }

  void _toggleSelection(String id) {
    setState(() => _selection.toggle(id));
  }

  void _exitSelection() {
    setState(_selection.exit);
    // Leaving the selection never brings the search back.
    if (_isSearchMode) _exitSearchMode();
  }

  /// Title of the delete confirmation, based on the current selection.
  String _deleteActionTitle() {
    final int count = _selection.count;
    final int total = _visibleNotes.length;
    if (count > 1) {
      return count == total
          ? AppText.tr('delete_all_notes')
          : AppText.tr('delete_notes', <String, String>{'count': '$count'});
    }
    return AppText.tr('delete_note');
  }

  Future<void> _deleteSelected() async {
    final bool? confirm = await getConfirmation(
      context: context,
      actionTitle: _deleteActionTitle(),
      action: AppText.tr('delete'),
    );
    if (confirm != true || !mounted) return;
    final NotesRepository repository = getIt<NotesRepository>();
    for (final String id in _selection.ids) {
      await repository.trashNote(id);
    }
    if (!mounted) return;
    setState(() {
      _notes.removeWhere((Note note) => _selection.contains(note.id));
      _selection.exit();
    });
    // Leaving the selection never brings the search back.
    if (_isSearchMode) _exitSearchMode();
  }

  /// Moves the selected notes to [folderId], or back home when null.
  Future<void> _moveTo(String? folderId) async {
    final NotesRepository repository = getIt<NotesRepository>();
    final List<Note> selected = _notes
        .where((Note note) => _selection.contains(note.id))
        .toList();
    for (final Note note in selected) {
      await repository.upsertNote(
        folderId == null
            ? note.withoutFolder()
            : note.copyWith(folderId: folderId),
      );
    }
    if (!mounted) return;
    setState(_selection.exit);
    // Leaving the selection never brings the search back.
    if (_isSearchMode) _exitSearchMode();
    await _load();
  }

  /// Notes shown: the folder content, filtered by the local search. A locked
  /// note never shows up in the search results.
  List<Note> get _visibleNotes {
    final String query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _notes;
    return _notes
        .where((Note note) =>
            !note.isLocked &&
            (note.title.toLowerCase().contains(query) ||
                note.content.toLowerCase().contains(query)))
        .toList();
  }

  /// True once the user has actually typed in the search field: only then
  /// does the page switch to the results presentation.
  bool get _resultsVisible => _isSearchMode && _searchStarted;

  String _noteCountLabel(int count) =>
      '$count ${count > 1 ? AppText.tr('notes') : AppText.tr('note')}';

  /// Metadata on the title line, mirroring the home page: the selection while
  /// selecting, the result count while searching, the note count otherwise.
  String? get _headerMetadata {
    if (_selection.isActive) {
      // While searching, the total is the number of results.
      final int count = _selection.count;
      final int total = _visibleNotes.length;
      if (count == 0) return AppText.tr('no_note_selected');
      if (count > 1 && count == total) {
        return AppText.tr('all_notes_selected', <String, String>{
          'count': '$count',
        });
      }
      if (count > 1) {
        return AppText.tr('notes_selected', <String, String>{
          'count': '$count',
          'total': '$total',
        });
      }
      return AppText.tr('single_note_selected', <String, String>{
        'count': '$count',
      });
    }
    if (_resultsVisible) return _noteCountLabel(_visibleNotes.length);
    // With a flag line below, the count only lives there.
    if (_hasFolderFlags) return null;
    return _noteCountLabel(_notes.length);
  }

  /// Whether the folder has any flag worth a dedicated metadata line.
  bool get _hasFolderFlags => _folder.isLocked || _folder.important;

  /// Metadata line, mirroring a note's: the note count on the left and the
  /// folder flags (lock, bookmark) on the right, only when they are set.
  Widget _buildMetadata(BuildContext context) {
    return SliverPadding(
      key: const ValueKey<String>('folder_metadata'),
      // Same horizontal padding as the page title, so the note count lines up
      // with it.
      padding: const EdgeInsets.symmetric(horizontal: appPaddingLarge),
      sliver: SliverToBoxAdapter(
        child: Padding(
          // Tight gap below, towards the cover image.
          padding: const EdgeInsets.only(
            top: appPaddingMedium,
            bottom: 6.0,
          ),
          child: MetadataLine(
            leading: Text(
              _noteCountLabel(_notes.length),
              style: metadataLineStyle(context),
            ),
            trailing: <Widget>[
              if (_folder.isLocked)
                metadataGlyph(context, Symbols.lock),
              if (_folder.important)
                metadataGlyph(
                  context,
                  Symbols.label_important,
                  color: tanoAmber,
                  fill: 1.0,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The folder's colour theming tints the page, exactly like a note.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color folderColor = themeCategory(
      _folder.category,
      true,
      brightness: Theme.of(context).brightness,
    );
    final Color immersiveBg = getImmersiveBackgroundColor(
      folderColor,
      isDark: isDark,
    );
    // The folder's FAB always rests in its reduced form; tapping it expands
    // the action bar. This keeps it from hiding the notes or the cover.
    return PageScaffold(
      backgroundColor: immersiveBg,
      // The folder name is always the page title, even in selection mode.
      title: _resultsVisible
          ? AppText.tr('search_results')
          : _folder.name,
      headerMetadata: _headerMetadata,
      // Nothing but the illustration: it must hold its place.
      freezeBody: !_loading && _visibleNotes.isEmpty,
      titleWidget: _isEditingTitle
          ? TapRegion(
              onTapOutside: (_) => _exitTitleEdit(),
              child: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                maxLength: 54,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _exitTitleEdit(),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: TanoText.pageTitle,
                  letterSpacing: -0.41,
                  color: getTextColor(
                    Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  counter: Offstage(),
                ),
              ),
            )
          : null,
      actions: _selection.isActive
          ? <Widget>[CancelButton(onPressed: _exitSelection)]
          : _isSearchMode
          ? <Widget>[CancelButton(onPressed: _exitSearchMode)]
          : <Widget>[
              // Add first, as requested on the folder page.
              IconButton(
                icon: const Icon(Symbols.add_notes),
                tooltip: AppText.tr('add_note'),
                onPressed: () => _openNote(add: true, note: _newNote()),
              ),
              IconButton(
                icon: const Icon(Symbols.search),
                tooltip: AppText.tr('search'),
                onPressed: _enterSearchMode,
              ),
              const ThemeToggleButton(),
            ],
      floatingActionButtonLocation: const FlushEndFabLocation(),
      // A single, stable FAB for both modes: only the icons animate when the
      // selection mode toggles, the FAB box itself does not move.
      floatingActionButton: AppFab(
        key: _fabKey,
        isEditorMode: true,
        isFolderMode: true,
        isSelectionMode: _selection.isActive,
        // Moving needs at least one selected note.
        canMove: _selection.isNotEmpty,
        canDelete: _selection.isNotEmpty,
        isSearchMode: _isSearchMode,
        collapsedByDefault: true,
        controller: _searchController,
        focusNode: _searchFocusNode,
        isImportant: _folder.important,
        isLocked: _folder.isLocked,
        isTitleEditing: _isEditingTitle,
        currentCategory: _folder.category,
        currentFolderId: _folder.id,
        onAddNote: () => _openNote(add: true, note: _newNote()),
        onImageSelected: () {
          _fabKey.currentState?.closeVerticalMenu();
          _selectCover();
        },
        onColorSelected: (String name) =>
            _save(_folder.copyWith(category: name)),
        onImportantSelected: () =>
            _save(_folder.copyWith(important: !_folder.important)),
        onLockSelected: _toggleLock,
        onDeleteSelected: _delete,
        onEditTitle: _startTitleEdit,
        onSearchChanged: (String value) {
          setState(() {
            _searchQuery = value;
            // Only from the first typed letter does the page switch to the
            // results presentation.
            if (value.trim().isNotEmpty) {
              _searchStarted = true;
            }
          });
        },
        onReset: _clearSearch,
        onDelete: _deleteSelected,
        onMoveTo: _moveTo,
        onClearSelection: () => setState(_selection.clear),
        onSelectAll: () => setState(
          // Only the notes currently shown (search results included).
          () => _selection.selectAll(_visibleNotes.map((Note note) => note.id)),
        ),
      ),
      slivers: <Widget>[
        if (!_loading && _hasFolderFlags && !_resultsVisible)
          _buildMetadata(context),
        if (_folder.coverImage != null && !_resultsVisible)
          SliverToBoxAdapter(
            child: ManageableCover(
              name: _folder.coverImage!,
              height: 160.0,
              // Tighter gap below, towards the notes grid / list.
              padding: const EdgeInsets.only(
                top: appPaddingMedium,
                bottom: appPaddingSmall,
              ),
              onRemove: () async {
                await _save(_folder.withoutCover());
              },
            ),
          ),
        if (_loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator.adaptive()),
          )
        else
          _buildNotes(),
      ],
    );
  }

  Widget _buildNotes() {
    final List<Note> notes = _visibleNotes;
    if (notes.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: emptyState(
          context,
          _isSearchMode
              ? AppText.tr('no_note_found')
              : AppText.tr('folder_empty'),
          image: _isSearchMode ? EmptyArt.search : EmptyArt.folder,
        ),
      );
    }

    final bool isList = _viewLayout == 'list';
    return SliverPadding(
      padding: const EdgeInsets.all(appPaddingMedium),
      sliver: EntitySliver<Note>(
        items: notes,
        isList: isList,
        cardBuilder: (BuildContext context, Note note) =>
            _card(note, isList: isList),
      ),
    );
  }

  Widget _card(Note note, {required bool isList}) {
    return EntityCard(
      kind: EntityKind.note,
      category: note.category,
      title: note.title,
      subtitle: formatNoteDate(note.date),
      coverImage: note.coverImage,
      isImportant: note.important,
      isLocked: note.isLocked,
      isListLayout: isList,
      isSelected: _selection.contains(note.id),
      isInSelectionMode: _selection.isActive,
      onSelectionToggle: () => _toggleSelection(note.id),
      onLongPress: () => _enterSelection(note.id),
      onTap: () {
        if (_selection.isActive) {
          _toggleSelection(note.id);
        } else {
          _openNote(add: false, note: note);
        }
      },
      // Same body as the home page cards.
      builder: (BuildContext context, Color textColor, bool hasCover) => isList
          ? buildNoteListContent(
              note: note,
              textColor: textColor,
              activeNoteIds: _activeNoteIds,
              hasCover: hasCover,
            )
          : buildNoteGridContent(
              note: note,
              textColor: textColor,
              activeNoteIds: _activeNoteIds,
              hasCover: hasCover,
            ),
    );
  }
}

