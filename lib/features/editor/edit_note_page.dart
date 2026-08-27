import 'package:flutter/material.dart';
import 'package:tano/features/editor/edit_note_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/app_fab.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';

class EditNote extends StatefulWidget {
  final bool add;
  final int index;
  final NoteAction noteAction;
  final Note? sourceNote;

  const EditNote({
    super.key,
    required this.add,
    required this.index,
    required this.noteAction,
    this.sourceNote,
  });

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote> {
  late final EditNoteViewModel _viewModel;
  late NoteAction _noteAction;
  final TextEditingController _titleController = TextEditingController();
  late final LinkTextEditingController _contentController;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  int _noteContentLength = 0;
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  final GlobalKey<AppFabState> _fabKey = GlobalKey<AppFabState>();

  // Undo/redo history of (title, content) snapshots.
  final List<({String title, String content})> _history = [];
  int _historyIndex = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = EditNoteViewModel(
      repository: getIt<NotesRepository>(),
      add: widget.add,
      initialNote: widget.noteAction.note,
    );
    _noteAction =
        NoteAction(kind: NoteActionKind.cancel, note: widget.noteAction.note);
    _titleController.text =
        widget.noteAction.note?.title.replaceAll('\n', ' ') ?? '';
    
    _contentController = LinkTextEditingController(
      text: widget.noteAction.note?.content ?? '',
      linkColor: tanoAmber,
    );
    
    _loadActiveNoteIds();
    _noteContentLength = widget.noteAction.note?.content.length ?? 0;
    _history.add(
      (title: _titleController.text, content: _contentController.text),
    );
  }

  Future<void> _loadActiveNoteIds() async {
    final repository = getIt<NotesRepository>();
    final notes = await repository.loadNotes();
    if (mounted) {
      setState(() {
        _contentController.activeNoteIds = notes.map((n) => n.id).toSet();
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _saveNote({required NoteAction noteAction}) {
    final Note note = _viewModel.buildNote(
      title: _titleController.text,
      content: _contentController.text,
    );
    if (!_viewModel.isValid(
      title: _titleController.text,
      content: _contentController.text,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.tr('content_empty'))));
    } else {
      noteAction.note = note;
      noteAction.kind = NoteActionKind.save;
      Navigator.pop(context, noteAction);
    }
  }

  void _deleteNote(NoteAction noteAction) {
    noteAction.kind = NoteActionKind.delete;
    Navigator.pop(context, noteAction);
  }

  void _getNoteContentLength(String content) {
    setState(() {
      _noteContentLength = content.length;
    });
  }

  bool get _canUndo => _historyIndex > 0;
  bool get _canRedo => _historyIndex < _history.length - 1;

  /// True once the user has made at least one edit since opening the note.
  /// The undo/redo/save actions stay visible after an in-place save so the
  /// user can still revert to the pre-save state.
  bool get _hasEdits => _history.length > 1;

  /// Records the current text state after a user edit, truncating any redo
  /// entries that may have accumulated after the current position. Consecutive
  /// single-character insertions that continue the same "word"/"space" run are
  /// coalesced into a single undo step.
  void _recordEdit() {
    final current = (
      title: _titleController.text,
      content: _contentController.text,
    );
    final last = _history[_historyIndex];
    if (last.title == current.title && last.content == current.content) {
      return; // no actual change
    }
    if (_historyIndex + 1 < _history.length) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    final bool coalesce = _historyIndex > 0 && _shouldCoalesce(last, current);
    if (coalesce) {
      _history[_historyIndex] = current;
    } else {
      _history.add(current);
      _historyIndex = _history.length - 1;
    }
    setState(() {});
  }

  /// Whether [current] continues the same "word"/"space"/"newline" typing run
  /// as [old].
  bool _shouldCoalesce(
    ({String title, String content}) old,
    ({String title, String content}) current,
  ) {
    final bool titleChanged = old.title != current.title;
    final bool contentChanged = old.content != current.content;
    if (titleChanged && contentChanged) return false;
    if (titleChanged) {
      return _coalescesSingleCharInsertion(old.title, current.title);
    }
    if (contentChanged) {
      return _coalescesSingleCharInsertion(old.content, current.content);
    }
    return false;
  }

  /// True when [newText] is [oldText] plus a single trailing character of the
  /// same class (word, space or newline) as the previous trailing character.
  bool _coalescesSingleCharInsertion(String oldText, String newText) {
    if (newText.length != oldText.length + 1) return false;
    if (!newText.startsWith(oldText)) return false;
    if (oldText.isEmpty) return false;
    final String inserted = newText.substring(oldText.length);
    final String lastOld = oldText[oldText.length - 1];
    return _charKind(inserted) == _charKind(lastOld);
  }

  /// Word characters, spaces and newlines are distinct undo boundaries.
  int _charKind(String char) {
    if (char == '\n') return 2;
    if (char == ' ') return 1;
    return 0;
  }

  void _undo() {
    if (!_canUndo) return;
    _historyIndex--;
    _restoreHistory();
  }

  void _redo() {
    if (!_canRedo) return;
    _historyIndex++;
    _restoreHistory();
  }

  void _restoreHistory() {
    final snapshot = _history[_historyIndex];
    _titleController.text = snapshot.title;
    _contentController.setTextForRestore(snapshot.content);
    _getNoteContentLength(snapshot.content);
    setState(() {});
  }

  Future<void> _save() async {
    if (!_viewModel.isValid(
      title: _titleController.text,
      content: _contentController.text,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.tr('content_empty'))));
      return;
    }
    final note = _viewModel.buildNote(
      title: _titleController.text,
      content: _contentController.text,
    );
    await _viewModel.persistSavedNote(note);
    // Keep the undo/redo history so the user can still revert to the
    // pre-save state after saving in place. Rebuild to gray the save button.
    if (mounted) setState(() {});
  }

  Future<void> _handleLinkTap() async {
    final offset = _contentController.selection.baseOffset;
    if (offset < 0) return;

    final String? noteId = _contentController.getLinkIdAt(offset);
    if (noteId == null || !mounted) return;

    final repository = getIt<NotesRepository>();
    final notes = await repository.loadNotes();
    if (!mounted) return;

    final targetNote =
        notes.firstWhere((n) => n.id == noteId, orElse: () => Note());
    if (targetNote.id.isEmpty || !mounted) return;

    // Save current note changes (if any) before navigating.
    final currentNote = _viewModel.buildNote(
      title: _titleController.text,
      content: _contentController.text,
    );
    if (_viewModel.isDirty(
      title: _titleController.text,
      content: _contentController.text,
    )) {
      await _viewModel.persistSavedNote(currentNote);
    }
    if (!mounted) return;

    // Standard push to allow "Back" button to return naturally.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNote(
          add: false,
          index: -1,
          noteAction: NoteAction(note: targetNote),
        ),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;

    // Refresh state when returning in case the target note was changed.
    await _viewModel.load();
    _getNoteContentLength(_contentController.text);
  }

  Future<bool> _onWillPopCallback() async {
    final String title = _titleController.text;
    final String content = _contentController.text;

    // If the note is empty, we don't care about theme/bookmark changes,
    // we just let the user leave without any prompt.
    if (!_viewModel.isValid(title: title, content: content)) {
      return true;
    }

    if (_viewModel.isDirty(title: title, content: content)) {
      final bool? confirm = await getConfirmation(
        context: context,
        actionTitle: AppText.tr('save_before_leave'),
        action: AppText.tr('save'),
      );
      if (confirm == true) {
        final Note note = _viewModel.buildNote(title: title, content: content);
        await _viewModel.persistSavedNote(note);
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final bool canLeave = await _onWillPopCallback();
        if (canLeave && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: ListenableBuilder(
        listenable: _viewModel,
        builder: (BuildContext context, Widget? child) {
          final bool isDark = Theme.of(context).brightness == Brightness.dark;
          final Color noteColor = themeCategory(
            _viewModel.category,
            true,
            brightness: Theme.of(context).brightness,
          );
          final Color immersiveBg =
              getImmersiveBackgroundColor(noteColor, isDark: isDark);

          final bool isDirty = _viewModel.isDirty(
            title: _titleController.text,
            content: _contentController.text,
          );

          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              _fabKey.currentState?.closeVerticalMenu();
            },
            child: PageScaffold(
              scaffoldKey: _scaffoldState,
              backgroundColor: immersiveBg,
              titlePaddingLeft: 12.0,
              title:
                  widget.add ? AppText.tr('add_note') : AppText.tr('edit_note'),
              titleController: _titleController,
              titleFocusNode: _titleFocus,
              titleHint: AppText.tr('title_here'),
              titleOnChanged: (String _) => _recordEdit(),
              onPop: () async {
                final bool willPop = await _onWillPopCallback();
                if (willPop && context.mounted) {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/home',
                      (Route<dynamic> route) => false,
                    );
                  }
                }
              },
              actions: [
                if (_hasEdits) ...[
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.undo),
                    onPressed: _canUndo ? _undo : null,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.redo),
                    onPressed: _canRedo ? _redo : null,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.save, size: 21.0),
                    onPressed: isDirty ? _save : null,
                  ),
                ],
                const ThemeToggleButton(),
              ],
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8.0,
                              runSpacing: 4.0,
                              children: [
                                Text(
                                  formatNoteDate(_viewModel.selectedDate.toString()),
                                  style: TextStyle(
                                    color: mutedTextColor(context),
                                    fontSize: 11.0,
                                  ),
                                ),
                                Text(
                                  '|',
                                  style: TextStyle(
                                    color: mutedTextColor(context).withValues(alpha: 0.3),
                                    fontSize: 11.0,
                                  ),
                                ),
                                Text(
                                  '${_noteContentLength.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]} ")} ${AppText.tr('chars')}',
                                  style: TextStyle(
                                    color: mutedTextColor(context),
                                    fontSize: 11.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_contentController.linkCount > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sticky_note_2,
                                  size: 12.0,
                                  color: mutedTextColor(context),
                                ),
                                Text(
                                  'x${_contentController.linkCount}',
                                  style: TextStyle(
                                    color: mutedTextColor(context),
                                    fontSize: 11.0,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 100.0),
                  sliver: SliverToBoxAdapter(
                    child: TextField(
                      maxLines: null,
                      minLines: 10,
                      showCursor: true,
                      autofocus: widget.add,
                      focusNode: _contentFocus,
                      controller: _contentController,
                      textInputAction: TextInputAction.newline,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 14.4, height: 1.8),
                      decoration: InputDecoration(
                        hintText: AppText.tr('add_note'),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (String content) {
                        _getNoteContentLength(content);
                        _recordEdit();
                      },
                      onTap: _handleLinkTap,
                    ),
                  ),
                ),
              ],
              floatingActionButtonLocation: const FlushEndFabLocation(),
              floatingActionButton: AppFab(
                key: _fabKey,
                isEditorMode: true,
                isAddMode: widget.add,
                isPinned: _viewModel.isPinned,
                isImportant: _viewModel.important,
                currentCategory: _viewModel.category,
                currentNoteId: _viewModel.id,
                onSave: () => _saveNote(noteAction: _noteAction),
                onColorLens: () {}, // Placeholder for animation triggering if needed
                onColorSelected: (String colorName) async {
                  _viewModel.setCategory(colorName);
                  // Automatic immediate save of the theme change if valid
                  await _viewModel.autoSaveThemeOrBookmark(
                    title: _titleController.text,
                    content: _contentController.text,
                  );
                },
                onMore: () {}, // Placeholder for animation triggering if needed
                onImageSelected: () {}, // TODO: Implement image selection
                onChecklistSelected: () {}, // TODO: Implement checklist
                onLinkSelected: () {
                   _fabKey.currentState?.closeVerticalMenu();
                },
                onNoteLinkSelected: (Note selectedNote) {
                  final String linkPlaceholder = "[[${selectedNote.id}:${selectedNote.title}]]";
                  final int cursorPosition = _contentController.snapPositionOutOfLink(_contentController.selection.baseOffset);
                  final String currentText = _contentController.text;
                  
                  String newText;
                  int newCursorPosition;
                  
                  // If no cursor (keyboard closed), insert at the beginning
                  if (cursorPosition <= 0) {
                    final String separator = currentText.isEmpty ? '' : '\n';
                    newText = '$linkPlaceholder $separator$currentText';
                    newCursorPosition = linkPlaceholder.length + 1;
                  } else {
                    final String before = currentText.substring(0, cursorPosition);
                    final String after = currentText.substring(cursorPosition);
                    newText = '$before$linkPlaceholder $after';
                    newCursorPosition = cursorPosition + linkPlaceholder.length + 1;
                  }
                  
                  _contentController.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newCursorPosition),
                  );
                  _getNoteContentLength(newText);
                },
                onAttachmentSelected: () {}, // TODO: Implement attachment selection
                onPinSelected: () async {
                  _viewModel.togglePin();
                  await _viewModel.autoSaveThemeOrBookmark(
                    title: _titleController.text,
                    content: _contentController.text,
                  );
                },
                onImportantSelected: () async {
                  _viewModel.toggleImportant();
                  await _viewModel.autoSaveThemeOrBookmark(
                    title: _titleController.text,
                    content: _contentController.text,
                  );
                },
                onFindSelected: () {}, // TODO: Implement Find in note
                onMoveSelected: () {}, // TODO: Implement Move to
                onCollaboratorsSelected: () {}, // TODO: Implement Collaborators
                onShareSelected: () {}, // TODO: Implement Share
                onLockSelected: () {}, // TODO: Implement Lock
                onDeleteSelected: () async {
                  final bool? confirmDeletion = await getConfirmation(
                    context: context,
                    actionTitle: AppText.tr('delete_note'),
                    action: AppText.tr('delete'),
                  );
                  if (confirmDeletion == true) {
                    _deleteNote(_noteAction);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
