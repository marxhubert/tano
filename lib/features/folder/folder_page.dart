import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/secure_preferences.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/app_fab.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/note_card_content.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Shows the notes filed in a single folder and its organisation actions.
class FolderPage extends StatefulWidget {
  const FolderPage({super.key, required this.folder});

  final Folder folder;

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
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
  bool _showRemoveCoverButton = false;

  /// Cached cover materialization, so rebuilding the page does not restart
  /// the future and flash the placeholder.
  String? _coverName;
  Future<String>? _coverFuture;
  String _searchQuery = '';
  String _viewLayout = 'gridlist';
  bool _isSelectionMode = false;
  final Set<String> _selected = <String>{};

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
  void dispose() {
    _titleFocusNode.removeListener(_onTitleFocusChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    final SecurePreferences prefs = await SecurePreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _viewLayout = prefs.getString('viewLayout') ?? 'gridlist';
    });
  }

  Future<void> _load() async {
    final List<Note> all = await getIt<NotesRepository>().loadNotes();
    if (!mounted) return;
    setState(() {
      _activeNoteIds = all
          .where((Note note) => !note.isDeleted)
          .map((Note note) => note.id)
          .toSet();
      _notes = all.where((Note note) => note.folderId == _folder.id).toList();
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
    await _foldersRepository?.upsertFolder(folder);
    if (!mounted) return;
    setState(() => _folder = folder);
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
      authenticated = await AuthService.instance.authenticate(
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

  /// Removes the cover image, mirroring a note's cover removal.
  Future<void> _removeCover() async {
    if (_folder.coverImage == null) return;
    await _save(_folder.withoutCover());
    if (!mounted) return;
    setState(() => _showRemoveCoverButton = false);
  }

  /// Materializes the cover once per file name.
  Future<String> _coverPath(String name) {
    if (_coverName != name || _coverFuture == null) {
      _coverName = name;
      _coverFuture = _attachmentsStore.materialize(name);
    }
    return _coverFuture!;
  }

  Future<void> _toggleLock() async {
    if (!_folder.isLocked) {
      if (!await AuthService.instance.isAvailable()) {
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
    final bool authenticated = await AuthService.instance.authenticate(
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

    final NotesRepository repository = getIt<NotesRepository>();
    for (final Note note in await repository.loadNotes()) {
      if (note.folderId == _folder.id) {
        await repository.trashNote(note.id);
      }
    }
    await _foldersRepository?.trashFolder(_folder.id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _enterSelection(String id) {
    // Keep the search active: the selection stays scoped to the results.
    setState(() {
      _selected.add(id);
      _isSelectionMode = true;
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selected.remove(id)) {
        _selected.add(id);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selected.clear();
      _isSelectionMode = false;
    });
    // Leaving the selection never brings the search back.
    if (_isSearchMode) _exitSearchMode();
  }

  /// Title of the delete confirmation, based on the current selection.
  String _deleteActionTitle() {
    final int count = _selected.length;
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
    for (final String id in _selected.toList()) {
      await repository.trashNote(id);
    }
    if (!mounted) return;
    setState(() {
      _notes.removeWhere((Note note) => _selected.contains(note.id));
      _selected.clear();
      _isSelectionMode = false;
    });
    // Leaving the selection never brings the search back.
    if (_isSearchMode) _exitSearchMode();
  }

  /// Moves the selected notes to another folder, or back home.
  Future<void> _moveSelected() async {
    final NotesRepository repository = getIt<NotesRepository>();
    final List<Folder> folders =
        await _foldersRepository?.loadFolders() ?? const <Folder>[];
    if (!mounted) return;
    final String? target = await showAdaptiveChoice<String>(
      context: context,
      title: AppText.tr('option_move'),
      choices: <AdaptiveChoice<String>>[
        AdaptiveChoice<String>(label: AppText.tr('no_folder'), value: ''),
        for (final Folder folder in folders)
          if (folder.id != _folder.id)
            AdaptiveChoice<String>(label: folder.name, value: folder.id),
      ],
    );
    if (target == null || !mounted) return;
    final List<Note> selected = _notes
        .where((Note note) => _selected.contains(note.id))
        .toList();
    for (final Note note in selected) {
      await repository.upsertNote(
        target.isEmpty
            ? note.withoutFolder()
            : note.copyWith(folderId: target),
      );
    }
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _isSelectionMode = false;
    });
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

  /// Trailing text on the title line, mirroring the home page.
  Widget? _buildHeaderTrailing(BuildContext context) {
    if (_isSelectionMode) {
      // Exactly the home page's wording: single, x/y or all selected. While
      // searching, the total is the number of results.
      final int count = _selected.length;
      final int total = _visibleNotes.length;
      final String label = count == 0
          ? AppText.tr('no_note_selected')
          : (count > 1
                ? (count == total
                      ? AppText.tr('all_notes_selected', <String, String>{
                          'count': '$count',
                        })
                      : AppText.tr('notes_selected', <String, String>{
                          'count': '$count',
                          'total': '$total',
                        }))
                : AppText.tr('single_note_selected', <String, String>{
                    'count': '$count',
                  }));
      return Flexible(
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w400,
              fontSize: 12.0,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }
    // While searching, show how many notes match.
    if (_resultsVisible) {
      return Text(
        _noteCountLabel(_visibleNotes.length),
        style: TextStyle(
          color: mutedTextColor(context),
          fontWeight: FontWeight.w400,
          fontSize: 13.0,
        ),
      );
    }
    // With no flag to show, the count goes back to the right of the title.
    if (_hasFolderFlags) return null;
    return Text(
      _noteCountLabel(_notes.length),
      style: TextStyle(
        color: mutedTextColor(context),
        fontWeight: FontWeight.w400,
        fontSize: 13.0,
      ),
    );
  }

  /// Whether the folder has any flag worth a dedicated metadata line.
  bool get _hasFolderFlags =>
      _folder.isLocked || _folder.important || _folder.isPinned;

  /// Metadata line, mirroring a note's: the note count on the left and the
  /// folder flags (lock, bookmark, pin) on the right, only when they are set.
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
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${_notes.length} ${_notes.length > 1 ? AppText.tr('notes') : AppText.tr('note')}',
                  style: TextStyle(
                    color: mutedTextColor(context),
                    fontSize: 11.0,
                  ),
                ),
              ),
              if (_folder.isLocked) _metadataIcon(Icons.lock_outline, context),
              if (_folder.important)
                _metadataIcon(Icons.bookmark, context, color: tanoAmber),
              if (_folder.isPinned)
                _metadataIcon(Icons.push_pin, context, size: 14.0, dy: 2.0),
            ],
          ),
        ),
      ),
    );
  }

  /// One flag icon. [dy] shifts the glyph downward without moving its layout
  /// box, so an icon with a foot (the pin) hangs below the others like the
  /// descender of a "g" or "y" in a word.
  Widget _metadataIcon(
    IconData icon,
    BuildContext context, {
    Color? color,
    double size = 12.0,
    double dy = 0.0,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Transform.translate(
        offset: Offset(0.0, dy),
        child: Icon(
          icon,
          size: size,
          color: color ?? mutedTextColor(context),
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
      headerTrailing: _buildHeaderTrailing(context),
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
                  fontSize: 24.0,
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
      actions: _isSelectionMode
          ? <Widget>[
              TextButton(
                onPressed: _exitSelection,
                child: Text(
                  AppText.tr('cancel'),
                  style: const TextStyle(fontSize: 17.0),
                ),
              ),
            ]
          : _isSearchMode
          ? <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton(
                  onPressed: _exitSearchMode,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    AppText.tr('cancel'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 17.0,
                      color: tanoTeal,
                    ),
                  ),
                ),
              ),
            ]
          : <Widget>[
              // Add first, as requested on the folder page.
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _openNote(add: true, note: _newNote()),
              ),
              IconButton(
                icon: const Icon(Icons.search),
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
        isSelectionMode: _isSelectionMode,
        isSearchMode: _isSearchMode,
        collapsedByDefault: true,
        controller: _searchController,
        focusNode: _searchFocusNode,
        isPinned: _folder.isPinned,
        isImportant: _folder.important,
        isLocked: _folder.isLocked,
        isTitleEditing: _isEditingTitle,
        currentCategory: _folder.category,
        onAddNote: () => _openNote(add: true, note: _newNote()),
        onImageSelected: () {
          _fabKey.currentState?.closeVerticalMenu();
          _selectCover();
        },
        onColorSelected: (String name) =>
            _save(_folder.copyWith(category: name)),
        onPinSelected: () =>
            _save(_folder.copyWith(isPinned: !_folder.isPinned)),
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
        onMoveSelected: _moveSelected,
        onClearSelection: () => setState(() => _selected.clear()),
        onSelectAll: () => setState(
          // Only the notes currently shown (search results included).
          () => _selected.addAll(_visibleNotes.map((Note note) => note.id)),
        ),
      ),
      slivers: <Widget>[
        if (!_loading && _hasFolderFlags && !_resultsVisible)
          _buildMetadata(context),
        if (_folder.coverImage != null && !_resultsVisible)
          SliverToBoxAdapter(
            child: FutureBuilder<String>(
              future: _coverPath(_folder.coverImage!),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (!snapshot.hasData) {
                  // Reserve the cover's height from the first frame so the
                  // page does not jump when the image finishes loading.
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
                    child: _CoverPlaceholder(),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
                  child: TapRegion(
                    // Tapping elsewhere hides the remove button.
                    onTapOutside: (_) {
                      if (_showRemoveCoverButton) {
                        setState(() => _showRemoveCoverButton = false);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(appBorderRadius),
                      child: Stack(
                        children: <Widget>[
                          GestureDetector(
                            // Long press reveals the remove button, exactly
                            // like a note's cover.
                            onLongPress: () {
                              setState(() {
                                _showRemoveCoverButton =
                                    !_showRemoveCoverButton;
                              });
                            },
                            child: Stack(
                              children: <Widget>[
                                Image.file(
                                  File(snapshot.data!),
                                  height: 160.0,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                // Dark mode dims the cover, like a note's.
                                if (Theme.of(context).brightness ==
                                    Brightness.dark)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (_showRemoveCoverButton)
                            Positioned(
                              top: 8.0,
                              right: 8.0,
                              child: GestureDetector(
                                onTap: () async {
                                  final bool? confirm = await getConfirmation(
                                    context: context,
                                    actionTitle: AppText.tr('delete_photo'),
                                    action: AppText.tr('delete'),
                                  );
                                  if (confirm == true) {
                                    await _removeCover();
                                  }
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4.0,
                                        offset: Offset(0.0, 2.0),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                    size: 24.0,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
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
        child: Center(
          child: Text(
            _isSearchMode
                ? AppText.tr('no_note_found')
                : AppText.tr('folder_empty'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.0, color: mutedTextColor(context)),
          ),
        ),
      );
    }

    if (_viewLayout == 'list') {
      return SliverPadding(
        padding: const EdgeInsets.all(appPaddingMedium),
        sliver: SliverList.separated(
          itemCount: notes.length,
          itemBuilder: (BuildContext context, int index) =>
              _card(notes[index], isList: true),
          separatorBuilder: (BuildContext context, int index) =>
              const SizedBox(height: 8.0),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(appPaddingMedium),
      sliver: SliverGrid.count(
        crossAxisCount: gridCrossAxisCount(context),
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.9,
        children: notes
            .map((Note note) => _card(note, isList: false))
            .toList(),
      ),
    );
  }

  Widget _card(Note note, {required bool isList}) {
    return NoteCard(
      note: note,
      isListLayout: isList,
      isSelected: _selected.contains(note.id),
      isInSelectionMode: _isSelectionMode,
      onSelectionToggle: () => _toggleSelection(note.id),
      onLongPress: () => _enterSelection(note.id),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(note.id);
        } else {
          _openNote(add: false, note: note);
        }
      },
      // Same body as the home page cards.
      builder: (BuildContext context, Color textColor) => isList
          ? buildNoteListContent(
              note: note,
              textColor: textColor,
              activeNoteIds: _activeNoteIds,
            )
          : buildNoteGridContent(
              note: note,
              textColor: textColor,
              activeNoteIds: _activeNoteIds,
            ),
    );
  }
}

/// Neutral block shown while a cover image is read from disk, so the page
/// keeps its layout and does not jump when the image appears.
class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(appBorderRadius),
      child: SizedBox(
        height: 160.0,
        width: double.infinity,
        child: ColoredBox(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05),
          child: Center(
            child: Icon(
              Icons.image_outlined,
              size: 28.0,
              color: mutedTextColor(context).withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
