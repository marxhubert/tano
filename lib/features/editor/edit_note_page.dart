import 'dart:async';
import 'package:tano/core/models/task.dart';
import 'package:tano/features/editor/task_list_editor.dart';
import 'package:tano/shared/widgets/privacy_guard.dart';
import 'package:tano/core/models/note_access_policy.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/models/folder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:open_filex/open_filex.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/features/editor/edit_note_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/config/feedback_controller.dart';
import 'package:tano/shared/config/fab_side_controller.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';
import 'package:tano/shared/widgets/entity_layout.dart';
import 'package:tano/shared/widgets/manageable_cover.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme_toggle.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/widgets/toast.dart';

class EditNote extends StatefulWidget {
  final bool add;
  final NoteAction noteAction;

  /// Whether the lock chain was already unlocked before opening this note.
  /// When true, following a link to a locked note does not prompt again.
  final bool authenticated;

  const EditNote({
    super.key,
    required this.add,
    required this.noteAction,
    this.authenticated = false,
  });

  @override
  State<EditNote> createState() => _EditNoteState();
}

class _EditNoteState extends State<EditNote>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final EditNoteViewModel _viewModel;
  final AttachmentsStore _attachmentsStore = AttachmentsStore();
  final TextEditingController _titleController = TextEditingController();
  late final LinkTextEditingController _contentController;
  final _descriptionController = LinkTextEditingController();
  bool _descriptionWasActive = false;
  final _descriptionFocus = FocusNode();
  bool _showDescription = false;
  Timer? _centerTimer;
  int _centerGeneration = 0;
  bool _userScrolling = false;
  double _taskScrollPadding = 100;
  final FocusNode _titleFocus = FocusNode();
  final FocusNode _contentFocus = FocusNode();
  bool _contentFocusHadFocus = false;

  /// Whether the content field was focused when the current pointer went
  /// down, used to restore the focus state after a checkbox tap.
  bool _contentWasFocusedOnPointerDown = true;

  /// Set while the toggle handler intentionally unfocuses the field, so the
  /// focus-loss cleanup does not run for that spurious focus change.
  bool _suppressFocusLossCleanup = false;
  int _noteContentLength = 0;
  final GlobalKey<ScaffoldState> _scaffoldState = GlobalKey<ScaffoldState>();
  final GlobalKey<AppFabState> _fabKey = GlobalKey<AppFabState>();
  final _taskEditorKey = GlobalKey<TaskListEditorState>();
  final GlobalKey _contentFieldKey = GlobalKey();
  final TextEditingController _findController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  bool _isFindMode = false;
  int _currentFindIndex = 0;
  late final AnimationController _highlightBlinkController;

  // Undo/redo history of snapshots.
  final List<
    ({String title, String content, String description, String? coverImage})
  >
  _history = [];
  int _historyIndex = 0;

  bool _canLock = false;

  @override
  void didChangeMetrics() => _queueCenterTaskFocus();

  /// Center the active caret after keyboard/FAB animations have settled.
  /// Use the outer document scrollable, not the nested reorderable list.
  int get _editorLinkCount =>
      _contentController.linkCount +
      (_viewModel.isTask ? _descriptionController.linkCount : 0);

  void _queueCenterTaskFocus({int? generation, int retries = 2}) {
    if ((!_viewModel.isTask && !_isFindMode) || _userScrolling) return;
    final request = generation ?? ++_centerGeneration;
    if (request != _centerGeneration) return;
    _centerTimer?.cancel();
    _centerTimer = Timer(const Duration(milliseconds: 320), () {
      if (!mounted ||
          request != _centerGeneration ||
          _userScrolling ||
          ModalRoute.of(context)?.isCurrent == false) {
        return;
      }
      final focusContext = _isFindMode
          ? (_viewModel.isTask
                ? _taskEditorKey.currentState?.selectedRowContext
                : _contentFieldKey.currentContext)
          : (_viewModel.isTask
                ? _taskEditorKey.currentState?.focusedRowContext ??
                      FocusManager.instance.primaryFocus?.context
                : FocusManager.instance.primaryFocus?.context);
      final root = focusContext?.findRenderObject();
      final fab = _fabKey.currentContext?.findRenderObject();
      final editorContext = _viewModel.isTask
          ? _taskEditorKey.currentContext
          : _contentFieldKey.currentContext;
      if (root == null || fab is! RenderBox || editorContext == null) {
        return;
      }
      final editable = _findRenderEditable(root);
      if (editable == null || !editable.attached) return;
      final selection = editable.selection;
      if ((selection == null || !selection.isValid) &&
          (_isFindMode || (editable.text?.toPlainText().isNotEmpty ?? false))) {
        return;
      }
      final effectiveSelection = selection != null && selection.isValid
          ? selection
          : const TextSelection.collapsed(offset: 0);
      final caret = _isFindMode
          ? _rangeRect(
              editable,
              effectiveSelection.start,
              effectiveSelection.end - effectiveSelection.start,
            )
          : editable.getLocalRectForCaret(effectiveSelection.extent);
      final y = editable.localToGlobal(caret.center).dy;
      final top = MediaQuery.paddingOf(context).top + kToolbarHeight;
      final bottom = fab.localToGlobal(Offset.zero).dy;
      if (bottom <= top) return;
      final viewportBottom =
          MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom;
      final padding = (viewportBottom - bottom + (bottom - top) / 2).clamp(
        100.0,
        MediaQuery.sizeOf(context).height,
      );
      if ((padding - _taskScrollPadding).abs() > 1) {
        setState(() => _taskScrollPadding = padding);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && request == _centerGeneration) {
            _queueCenterTaskFocus(generation: request, retries: retries);
          }
        });
        return;
      }

      final position = Scrollable.maybeOf(editorContext)?.position;
      if (position == null || !position.hasContentDimensions) return;
      final target = (position.pixels + y - (top + bottom) / 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((target - position.pixels).abs() > 1) {
        position
            .animateTo(
              target,
              duration: TanoMotion.base,
              curve: Curves.easeInOut,
            )
            .then((_) {
              // EditableText may reveal a newly attached caret after this scroll.
              // Allow bounded settling, but never restart after a user drag.
              if (mounted && request == _centerGeneration && retries > 0) {
                _queueCenterTaskFocus(
                  generation: request,
                  retries: retries - 1,
                );
              }
            });
      }
    });
  }

  bool _onEditorScroll(ScrollNotification notification) {
    if (notification.depth != 0) return false;
    final userStarted =
        notification is ScrollStartNotification &&
        notification.dragDetails != null;
    final userMoved =
        notification is UserScrollNotification &&
        notification.direction != ScrollDirection.idle;
    if (userStarted || userMoved) {
      _userScrolling = true;
      _centerGeneration++;
      _centerTimer?.cancel();
    } else if (notification is ScrollEndNotification) {
      _userScrolling = false;
    }
    return false;
  }

  void _onFabSideChanged() {
    if (!mounted) return;
    setState(() {});
    _queueCenterTaskFocus();
  }

  Future<void> _loadLockCapability() async {
    final available =
        getIt.isRegistered<AuthService>() &&
        await getIt<AuthService>().isAvailable();
    if (mounted) setState(() => _canLock = available);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FabSideController.instance.addListener(_onFabSideChanged);
    FabSideController.instance.load().then((_) => _onFabSideChanged());
    _loadLockCapability();
    _viewModel = EditNoteViewModel(
      repository: getIt<NotesRepository>(),
      add: widget.add,
      initialNote: widget.noteAction.note,
    );
    _descriptionController.text = _viewModel.description;
    _showDescription = _viewModel.description.isNotEmpty;
    _descriptionFocus.addListener(() {
      if (_descriptionFocus.hasFocus) _descriptionWasActive = true;
      _queueCenterTaskFocus();
    });
    _titleFocus.addListener(_queueCenterTaskFocus);
    _titleController.text =
        widget.noteAction.note?.title.replaceAll('\n', ' ') ?? '';

    _contentController = LinkTextEditingController(
      text: widget.noteAction.note?.content ?? '',
    );

    _highlightBlinkController =
        AnimationController(
          vsync: this,
          duration: TanoMotion.slow,
        )..addListener(() {
          _contentController.searchBlinkValue = _highlightBlinkController.value;
        });

    _loadActiveNoteIds();
    _contentFocus.addListener(_onContentFocusChanged);
    _contentFocusHadFocus = _contentFocus.hasFocus;
    _noteContentLength = widget.noteAction.note?.content.length ?? 0;
    _history.add((
      title: _titleController.text,
      content: _contentController.text,
      description: _descriptionController.text,
      coverImage: _viewModel.coverImage,
    ));
  }

  Future<void> _loadActiveNoteIds() async {
    final repository = getIt<NotesRepository>();
    final notes = await repository.loadNotes();
    if (mounted) {
      setState(() {
        _contentController.activeNoteIds = notes.map((n) => n.id).toSet();
        _descriptionController.activeNoteIds = _contentController.activeNoteIds;
      });
    }
  }

  @override
  void dispose() {
    _contentFocus.removeListener(_onContentFocusChanged);
    WidgetsBinding.instance.removeObserver(this);
    _centerGeneration++;
    _centerTimer?.cancel();
    FabSideController.instance.removeListener(_onFabSideChanged);
    _descriptionController.dispose();
    _descriptionFocus.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _titleFocus.dispose();
    _contentFocus.dispose();
    _findController.dispose();
    _findFocusNode.dispose();
    _highlightBlinkController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _enterFindMode() {
    _fabKey.currentState?.closeVerticalMenu();
    setState(() {
      _isFindMode = true;
    });
    _highlightBlinkController.repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _findFocusNode.requestFocus();
      }
    });
  }

  void _clearFind() {
    _findController.clear();
    _currentFindIndex = 0;
    _contentController.setSearchHighlight('', 0);
    setState(() {});
  }

  void _exitFindMode() {
    _findController.clear();
    _currentFindIndex = 0;
    _contentController.setSearchHighlight('', 0);
    _highlightBlinkController.stop();
    _highlightBlinkController.value = 1.0;
    _contentController.searchBlinkValue = 1.0;
    setState(() {
      _isFindMode = false;
    });
  }

  void _onFindChanged(String value) {
    _currentFindIndex = 0;
    if (value.isEmpty) {
      _contentController.setSearchHighlight('', 0);
      setState(() {});
      return;
    }
    final List<int> occurrences = _findOccurrences();
    if (occurrences.isEmpty) {
      _contentController.setSearchHighlight(value, 0);
      setState(() {});
      return;
    }
    _selectOccurrence(occurrences.first);
  }

  List<int> _findOccurrences() {
    return _contentController.searchOccurrences(_findController.text);
  }

  void _nextOccurrence() {
    final List<int> occurrences = _findOccurrences();
    if (occurrences.isEmpty) return;
    _currentFindIndex = (_currentFindIndex + 1) % occurrences.length;
    _selectOccurrence(occurrences[_currentFindIndex]);
  }

  void _prevOccurrence() {
    final List<int> occurrences = _findOccurrences();
    if (occurrences.isEmpty) return;
    _currentFindIndex =
        (_currentFindIndex - 1 + occurrences.length) % occurrences.length;
    _selectOccurrence(occurrences[_currentFindIndex]);
  }

  void _selectOccurrence(int start) {
    final String query = _findController.text;
    _contentController.selection = TextSelection(
      baseOffset: start,
      extentOffset: start + query.length,
    );
    _contentController.setSearchHighlight(query, _currentFindIndex);
    setState(() {});
    _scrollToOccurrence(start, query.length);
  }

  void _scrollToOccurrence(int start, int length) {
    _queueCenterTaskFocus();
  }

  RenderEditable? _findRenderEditable(RenderObject root) {
    if (root is RenderEditable) return root;
    RenderEditable? found;
    root.visitChildren((RenderObject child) {
      found ??= _findRenderEditable(child);
    });
    return found;
  }

  Rect _rangeRect(RenderEditable editable, int start, int length) {
    final Rect? rect = editable.getRectForComposingRange(
      TextRange(start: start, end: start + length),
    );
    if (rect != null && !rect.isEmpty) return rect;
    return editable.getLocalRectForCaret(TextPosition(offset: start));
  }

  int get _findTotal => _isFindMode ? _findOccurrences().length : 0;

  int get _findCurrent {
    if (!_isFindMode || _findController.text.isEmpty) return 0;
    final int total = _findTotal;
    return total > 0 ? _currentFindIndex + 1 : 0;
  }

  Future<bool> _tryStorage(Future<void> Function() operation) async {
    try {
      await operation();
      return true;
    } catch (_) {
      if (mounted) {
        await showAdaptiveAlert(
          context: context,
          title: AppText.tr('load_error_title'),
          message: AppText.tr('storage_recovery_message'),
        );
      }
      return false;
    }
  }

  Future<bool> _persistSafely(Note note) =>
      _tryStorage(() => _viewModel.persistSavedNote(note));

  Future<void> _saveNote() async {
    _cleanupEmptyChecklists();
    final Note note = _viewModel.buildNote(
      title: _titleController.text,
      content: _contentController.text,
    );
    if (!_viewModel.isValid(
      title: _titleController.text,
      content: _contentController.text,
    )) {
      showAdaptiveNotice(context, AppText.tr('content_empty'));
    } else {
      if (await _persistSafely(note) && mounted) {
        // The caller reloads; never pop a draft before its write succeeds.
        Navigator.pop(context);
      }
    }
  }

  void _deleteNote() {
    Navigator.pop(
      context,
      NoteAction(kind: NoteActionKind.delete, note: widget.noteAction.note),
    );
  }

  /// Moves the note to [folderId], or back home when null.
  Future<void> _moveTo(String? folderId) async {
    if (!mounted) return;
    final previousFolderId = _viewModel.folderId;
    _viewModel.folderId = folderId;
    final Note note = _viewModel.buildNote(
      title: _titleController.text,
      content: _contentController.text,
    );
    if (!await _persistSafely(note)) {
      _viewModel.folderId = previousFolderId;
      if (mounted) setState(() {});
      return;
    }
    if (!mounted) return;
    setState(() {});
    await FeedbackController.instance.impact();
    if (!mounted) return;
    await showMovedToast(context, count: 1, folderId: folderId);
  }

  /// The thin "|" separating two metadata values.
  Widget _metadataSeparator(BuildContext context) => Text(
    '|',
    style: metadataLineStyle(
      context,
    ).copyWith(color: mutedTextColor(context).withValues(alpha: 0.3)),
  );

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
      description: _descriptionController.text,
      coverImage: _viewModel.coverImage,
    );
    final last = _history[_historyIndex];
    if (last.description == current.description &&
        last.title == current.title &&
        last.content == current.content &&
        last.coverImage == current.coverImage) {
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
    ({String title, String content, String description, String? coverImage})
    old,
    ({String title, String content, String description, String? coverImage})
    current,
  ) {
    if (old.description != current.description) return false;
    final bool titleChanged = old.title != current.title;
    final bool contentChanged = old.content != current.content;
    final bool coverChanged = old.coverImage != current.coverImage;

    // Image changes never coalesce with text typing.
    if (coverChanged) return false;

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
    _descriptionController.text = snapshot.description;
    _viewModel.description = snapshot.description;
    _showDescription = snapshot.description.isNotEmpty;
    _contentController.setTextForRestore(snapshot.content);
    _viewModel.setCoverImage(snapshot.coverImage);
    _getNoteContentLength(snapshot.content);
    setState(() {});
  }

  Future<void> _save() async {
    _cleanupEmptyChecklists();
    if (!_viewModel.isValid(
      title: _titleController.text,
      content: _contentController.text,
    )) {
      showAdaptiveNotice(context, AppText.tr('content_empty'));
      return;
    }
    final note = _viewModel.buildNote(
      title: _titleController.text,
      content: _contentController.text,
    );
    if (!await _persistSafely(note)) return;
    // Keep the undo/redo history so the user can still revert to the
    // pre-save state after saving in place. Rebuild to gray the save button.
    if (mounted) setState(() {});
  }

  Future<void> _handleLinkTap([LinkTextEditingController? source]) async {
    final controller = source ?? _contentController;
    final offset = controller.selection.baseOffset;
    if (offset < 0) return;

    final String? noteId = controller.getLinkIdAt(offset);
    if (noteId == null || !mounted) return;

    final repository = getIt<NotesRepository>();
    final notes = await repository.loadNotes();
    if (!mounted) return;

    final targetNote = notes.firstWhere(
      (n) => n.id == noteId,
      orElse: () => Note(),
    );
    if (targetNote.id.isEmpty || !mounted) return;

    final folders = repository is FoldersRepository
        ? await (repository as FoldersRepository).loadFolders()
        : <Folder>[];
    final access = NoteAccessPolicy(folders);
    if (!access.isReachable(targetNote) || !mounted) return;

    // Only the already-open locked folder grants inherited access. A link
    // from any other note must authenticate its own protected destination.
    final sourceFolderId = _viewModel.folderId;
    bool authenticated =
        widget.authenticated &&
        sourceFolderId != null &&
        sourceFolderId == targetNote.folderId &&
        folders.any((folder) => folder.id == sourceFolderId && folder.isLocked);
    if (access.requiresAuthentication(targetNote) && !authenticated) {
      authenticated = await getIt<AuthService>().authenticate(
        reason: AppText.tr('auth_reason'),
      );
      if (!authenticated || !mounted) return;
    }

    // Save current note changes (if any) before navigating.
    final currentNote = _viewModel.buildNote(
      title: _titleController.text,
      content: _contentController.text,
    );
    if (_viewModel.isDirty(
      title: _titleController.text,
      content: _contentController.text,
    )) {
      if (!await _persistSafely(currentNote)) return;
    }
    if (!mounted) return;

    // Standard push to allow "Back" button to return naturally.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditNote(
          add: false,
          noteAction: NoteAction(kind: NoteActionKind.cancel, note: targetNote),
          authenticated: authenticated,
        ),
        fullscreenDialog: true,
      ),
    );
    if (!mounted) return;

    // Refresh state when returning in case the target note was changed.
    await _viewModel.load();
    _getNoteContentLength(_contentController.text);
  }

  /// Handles a tap inside the content: on a checklist title handle it places
  /// the caret into the title text (typed inline, right next to the icon),
  /// on a task item it toggles the checkbox, otherwise it delegates to link
  /// navigation.
  void _handleContentTap() {
    final int offset = _contentController.selection.baseOffset;
    if (offset < 0) return;
    final title = checklistTitleAt(_contentController.text, offset);
    if (title != null) {
      // The title is edited inline: put the caret at the end of the title
      // text so typing lands right next to the drag handle.
      _contentController.selection = TextSelection.collapsed(
        offset: title.lineEnd,
      );
      return;
    }
    final String? toggled = toggleTaskItemAt(_contentController.text, offset);
    if (toggled != null) {
      _contentController.value = TextEditingValue(
        text: toggled,
        selection: TextSelection.collapsed(
          offset: offset.clamp(0, toggled.length),
        ),
      );
      _getNoteContentLength(toggled);
      _recordEdit();
      // Toggling a checkbox must not activate focus (and open the keyboard):
      // restore the focus state from before the tap. The framework may
      // request focus again while the tap gesture settles, so re-check after
      // the frame as well.
      if (!_contentWasFocusedOnPointerDown) {
        void restoreFocus() {
          if (mounted &&
              !_contentWasFocusedOnPointerDown &&
              _contentFocus.hasFocus) {
            _suppressFocusLossCleanup = true;
            _contentFocus.unfocus();
            _suppressFocusLossCleanup = false;
          }
        }

        restoreFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) => restoreFocus());
      }
      return;
    }
    _handleLinkTap();
  }

  /// Inserts a checklist block (title line + one empty item) at the current
  /// caret, or at the end of the note when there is no focus.
  void _insertChecklist() {
    if (_viewModel.isTask) {
      _taskEditorKey.currentState?.addItem();
      return;
    }
    final int caret = _contentController.selection.isValid
        ? _contentController.selection.baseOffset
        : -1;
    final result = insertChecklistBlock(
      _contentController.text,
      hasFocus: _contentFocus.hasFocus,
      caret: caret,
    );
    _contentController.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.caret),
    );
    _getNoteContentLength(result.text);
    _recordEdit();
    _contentFocus.requestFocus();
  }

  Future<void> _selectCoverImage() async {
    final result = await FilePicker.pickFile(type: FileType.image);
    if (result == null) return;
    final String? sourcePath = result.path;
    if (sourcePath == null) return;

    final String name = await _attachmentsStore.import(sourcePath, result.name);
    _viewModel.setCoverImage(name);
    _recordEdit();
  }

  Future<void> _removeCoverImage() async {
    final String? name = _viewModel.coverImage;
    if (name == null) return;
    // We don't necessarily want to delete the file from disk here if it might
    // be used as an attachment too, but for simplicity we can just unset it.
    // If it's a dedicated cover image, we could call _attachmentsStore.remove(name).
    _viewModel.setCoverImage(null);
    _recordEdit();
  }

  /// Picks a file, copies it into the attachments store and persists the note.
  Future<void> _addAttachment() async {
    final PlatformFile? file = await FilePicker.pickFile();
    if (file == null) return;
    final String? sourcePath = file.path;
    if (sourcePath == null) return;

    final String name = await _attachmentsStore.import(sourcePath, file.name);
    final List<String> updated = List<String>.of(_viewModel.attachments)
      ..add(name);
    _viewModel.setAttachments(updated);
    await _persistAttachments();
  }

  /// Deletes an attached file and persists the updated note.
  Future<void> _removeAttachment(String name) async {
    // Persist the reference removal first. Startup GC protects other notes,
    // covers and trash that might share this file.
    final previous = List<String>.of(_viewModel.attachments);
    final List<String> updated = List<String>.of(_viewModel.attachments)
      ..remove(name);
    _viewModel.setAttachments(updated);
    if (!await _persistAttachments()) _viewModel.setAttachments(previous);
  }

  /// Opens an attached file with the system's default app.
  Future<void> _openAttachment(String name) async {
    final String path = await _attachmentsStore.materialize(name);
    await OpenFilex.open(path);
  }

  /// Persists the current note (including its attachments) immediately, so
  /// attachment changes are never lost.
  Future<bool> _persistAttachments() async {
    final Note note = _viewModel.buildNote(
      title: _titleController.text,
      content: _contentController.text,
    );
    return _persistSafely(note);
  }

  /// Runs when the content field loses focus: removes checklists left empty.
  void _onContentFocusChanged() {
    final bool hasFocus = _contentFocus.hasFocus;
    if (_contentFocusHadFocus && !hasFocus && !_suppressFocusLossCleanup) {
      _cleanupEmptyChecklists();
    }
    _contentFocusHadFocus = hasFocus;
  }

  /// Removes checklists that have no item text (and their optional title
  /// heading). Called before saves and when focus leaves the content field.
  void _cleanupEmptyChecklists() {
    final String before = _contentController.text;
    if (_viewModel.isTask) return;
    final String cleaned = cleanEmptyChecklists(before);
    if (cleaned == before) return;
    final int caret = _contentController.selection.baseOffset.clamp(
      0,
      cleaned.length,
    );
    _contentController.setTextForRestore(cleaned);
    _contentController.selection = TextSelection.collapsed(offset: caret);
    _getNoteContentLength(cleaned);
    _recordEdit();
  }

  Future<bool> _onWillPopCallback() async {
    _cleanupEmptyChecklists();
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
        return _persistSafely(note);
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: _onEditorScroll,
        child: _buildEditor(context),
      );

  Widget _buildEditor(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop || isPrivacyBlocked(context)) {
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
          final Color immersiveBg = getImmersiveBackgroundColor(isDark: isDark);

          final bool isDirty = _viewModel.isDirty(
            title: _titleController.text,
            content: _contentController.text,
          );
          final int contentChecklistCount = checklistCount(
            _contentController.text,
          );

          // A phone in portrait lets the cover bleed to both screen edges;
          // every other window aligns it with the content and rounds it.
          final Size viewport = MediaQuery.sizeOf(context);
          final bool coverFullBleed = !compactChrome(viewport);
          final double coverInset = coverFullBleed ? 0.0 : appPaddingMedium;
          final BorderRadius coverRadius = coverFullBleed
              ? BorderRadius.zero
              : BorderRadius.circular(appBorderRadius);

          return ProtectedContent(
            protected: _viewModel.isLocked || widget.authenticated,
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                _fabKey.currentState?.closeVerticalMenu();
              },
              child: PageScaffold(
                notebook: true,
                scaffoldKey: _scaffoldState,
                // The title and the metadata line share the content's inset, so
                // the three lines of the editor start on the same axis.
                titlePaddingLeft: appPaddingMedium,
                backgroundColor: immersiveBg,
                // Once the note is scrolled, show its title in the app bar and
                // slide it to the left while the undo/redo/save actions appear.
                alignAppBarTitleLeft: _hasEdits,
                title: widget.add
                    ? AppText.tr(_viewModel.isTask ? 'add_task' : 'add_note')
                    : AppText.tr(_viewModel.isTask ? 'edit_task' : 'edit_note'),
                // The reduced (scrolled) title carries the note's marks, in the
                // order "important + title + lock".
                headerMetadataLeading: _viewModel.important
                    ? reducedTitleBookmark()
                    : null,
                headerMetadataTrailing: _viewModel.isLocked
                    ? reducedTitleLock()
                    : null,
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
                  // In find mode only "Cancel" is shown: every other app-bar
                  // action (edits, theme toggle) is hidden.
                  if (_isFindMode)
                    CancelButton(onPressed: _exitFindMode)
                  else ...[
                    // While undo/redo/save are visible, the theme toggle steps
                    // aside to leave them the room.
                    if (_hasEdits) ...[
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Symbols.undo),
                        tooltip: AppText.tr('undo'),
                        onPressed: _canUndo ? _undo : null,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Symbols.redo),
                        tooltip: AppText.tr('redo'),
                        onPressed: _canRedo ? _redo : null,
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Symbols.save, size: 21.0),
                        tooltip: AppText.tr('save'),
                        onPressed: isDirty ? _save : null,
                      ),
                    ] else
                      const ThemeToggleButton(),
                  ],
                ],
                slivers: [
                  SliverPadding(
                    // Same inset as the title line and as the text below it.
                    padding: const EdgeInsets.symmetric(
                      horizontal: appPaddingMedium,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: appPaddingMedium,
                        ),
                        child: MetadataLine(
                          leading: Wrap(
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            // Tighter than the shared row gap: the lock, the
                            // date and the count read as one sentence.
                            spacing: 4.0,
                            runSpacing: 4.0,
                            children: [
                              if (_viewModel.isLocked) ...[
                                metadataGlyph(context, Symbols.lock),
                                _metadataSeparator(context),
                              ],
                              Text(
                                formatNoteDate(
                                  _viewModel.selectedDate.toString(),
                                ),
                                style: metadataLineStyle(context),
                              ),
                              _metadataSeparator(context),
                              Text(
                                _viewModel.isTask
                                    ? '${TaskContent.savedItems(_contentController.text).length} ${AppText.tr('tasks')}'
                                    : '${_noteContentLength.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]} ")} ${AppText.tr('chars')}',
                                style: metadataLineStyle(context),
                              ),
                            ],
                          ),
                          trailing: <Widget>[
                            // The same mark on a note and on a task:
                            // outlined, in the metadata's own ink, and a touch
                            // larger than the counts beside it.
                            if (_viewModel.important)
                              metadataGlyph(
                                context,
                                Symbols.bookmark,
                                fill: 0,
                                size: 16.0,
                              ),

                            if (!_viewModel.isTask && contentChecklistCount > 0)
                              metadataItem(
                                context,
                                Symbols.check_box,
                                'x$contentChecklistCount',
                              ),
                            if (_editorLinkCount > 0)
                              metadataItem(
                                context,
                                Symbols.sticky_note_2,
                                'x$_editorLinkCount',
                              ),
                            if (_viewModel.attachments.isNotEmpty)
                              metadataItem(
                                context,
                                Symbols.attachment,
                                'x${_viewModel.attachments.length}',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_viewModel.coverImage != null)
                    SliverToBoxAdapter(
                      child: ManageableCover(
                        name: _viewModel.coverImage!,
                        borderRadius: coverRadius,
                        lightDimAlpha: 0.0,
                        // Tighter gap above, under the metadata line.
                        padding: EdgeInsets.only(
                          top: appPaddingSmall,
                          bottom: appPaddingMedium,
                          left: coverInset,
                          right: coverInset,
                        ),
                        onRemove: _removeCoverImage,
                      ),
                    ),
                  if (_viewModel.isTask && _showDescription)
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: appPaddingMedium,
                        right: appPaddingMedium,
                        bottom: 8,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: TextField(
                          key: const ValueKey('task-description'),
                          controller: _descriptionController,
                          focusNode: _descriptionFocus,
                          maxLength: 500,
                          onTap: () {
                            _descriptionWasActive = true;
                            _handleLinkTap(_descriptionController);
                          },
                          maxLines: null,
                          style: const TextStyle(
                            fontSize: TanoText.label,
                            height: 1.8,
                          ),
                          decoration: InputDecoration(
                            hintText: AppText.tr('description'),
                            border: InputBorder.none,
                          ),
                          onChanged: (_) {
                            _viewModel.description =
                                _descriptionController.text;
                            _recordEdit();
                            _queueCenterTaskFocus();
                          },
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      12.0,
                      0.0,
                      12.0,
                      _viewModel.attachments.isEmpty
                          ? _taskScrollPadding
                          : 12.0,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _viewModel.isTask
                          ? TaskListEditor(
                              key: _taskEditorKey,
                              controller: _contentController,
                              autofocus: widget.add,
                              onChanged: _recordEdit,
                              onCaretChanged: () {
                                if (!_descriptionFocus.hasFocus &&
                                    !_isFindMode) {
                                  _descriptionWasActive = false;
                                }
                                _queueCenterTaskFocus();
                              },
                              onTapText: _handleContentTap,
                            )
                          : Listener(
                              onPointerDown: (_) {
                                _contentWasFocusedOnPointerDown =
                                    _contentFocus.hasFocus;
                              },
                              child: TextField(
                                key: _contentFieldKey,
                                maxLines: null,
                                minLines: 10,
                                showCursor: true,
                                autofocus: widget.add,
                                focusNode: _contentFocus,
                                controller: _contentController,
                                textInputAction: TextInputAction.newline,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: const TextStyle(
                                  fontSize: TanoText.body,
                                  fontFamily: 'TanoSerif',
                                  height: 2,
                                ),
                                decoration: InputDecoration(
                                  hintText: AppText.tr('add_note'),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                inputFormatters: <TextInputFormatter>[
                                  AutoTaskItemFormatter(),
                                ],
                                onChanged: (String content) {
                                  _getNoteContentLength(content);
                                  _recordEdit();
                                },
                                onTap: _handleContentTap,
                              ),
                            ),
                    ),
                  ),
                  if (_viewModel.attachments.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        appPaddingMedium,
                        0.0,
                        appPaddingMedium,
                        100.0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1.0),
                            const SizedBox(height: 14.0),
                            Row(
                              children: [
                                Icon(
                                  Symbols.attachment,
                                  size: 18.0,
                                  color: mutedTextColor(context),
                                ),
                                const SizedBox(width: appPaddingTight),
                                Text(
                                  AppText.tr(
                                    _viewModel.attachments.length > 1
                                        ? 'attachments'
                                        : 'attachment',
                                  ),
                                  style: TextStyle(
                                    fontSize: TanoText.label,
                                    fontWeight: FontWeight.w600,
                                    color: primaryTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            for (final String name in _viewModel.attachments)
                              _AttachmentRow(
                                name: name,
                                onOpen: () =>
                                    _tryStorage(() => _openAttachment(name)),
                                onRemove: () => _removeAttachment(name),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
                floatingActionButtonLocation: FlushFabLocation(
                  onLeft: FabSideController.instance.onLeft,
                ),
                floatingActionButton: AppFab(
                  key: _fabKey,
                  onLeft: FabSideController.instance.onLeft,
                  isEditorMode: true,
                  isAddMode: widget.add,
                  isImportant: _viewModel.important,
                  isLocked: _viewModel.isLocked,
                  isTaskMode: _viewModel.isTask,
                  onLayoutChanged: _queueCenterTaskFocus,
                  onDescriptionSelected: () {
                    _fabKey.currentState?.closeVerticalMenu();
                    setState(() => _showDescription = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _descriptionFocus.requestFocus();
                    });
                  },
                  canLock: _canLock,
                  currentCategory: _viewModel.category,
                  currentNoteId: _viewModel.id,
                  currentFolderId: _viewModel.folderId,
                  isFindMode: _isFindMode,
                  findCurrent: _findCurrent,
                  findTotal: _findTotal,
                  controller: _findController,
                  focusNode: _findFocusNode,
                  onSearchChanged: _onFindChanged,
                  onFindPrev: _prevOccurrence,
                  onFindNext: _nextOccurrence,
                  onFindReset: _clearFind,
                  onSave: _saveNote,
                  onColorLens:
                      () {}, // Placeholder for animation triggering if needed
                  onColorSelected: (String colorName) async {
                    _cleanupEmptyChecklists();
                    _viewModel.setCategory(colorName);
                    // Automatic immediate save of the theme change if valid
                    if (!await _tryStorage(
                      () => _viewModel.autoSaveThemeOrBookmark(
                        title: _titleController.text,
                        content: _contentController.text,
                      ),
                    )) {
                      return;
                    }
                  },
                  onMore:
                      () {}, // Placeholder for animation triggering if needed
                  onImageSelected: () {
                    _tryStorage(_selectCoverImage);
                    _fabKey.currentState?.closeVerticalMenu();
                  },
                  onChecklistSelected: () {
                    _insertChecklist();
                    _fabKey.currentState?.closeVerticalMenu();
                  },
                  onNoteLinkSelected: (Note selectedNote) {
                    final String linkPlaceholder =
                        "[[${selectedNote.id}:${selectedNote.title}]]";
                    if (_viewModel.isTask) {
                      if (_descriptionWasActive && _showDescription) {
                        final rawOffset =
                            _descriptionController.selection.baseOffset;
                        final offset = _descriptionController
                            .snapPositionOutOfLink(
                              rawOffset.clamp(
                                0,
                                _descriptionController.text.length,
                              ),
                            );
                        final text = _descriptionController.text.replaceRange(
                          offset,
                          offset,
                          linkPlaceholder,
                        );
                        if (text.characters.length > 500) {
                          showTanoToast(
                            context,
                            AppText.tr('description_limit'),
                          );
                          return;
                        }
                        _descriptionController.value = TextEditingValue(
                          text: text,
                          selection: TextSelection.collapsed(
                            offset: offset + linkPlaceholder.length,
                          ),
                        );
                        _viewModel.description = text;
                        _recordEdit();
                        _descriptionFocus.requestFocus();
                      } else {
                        _taskEditorKey.currentState?.insertText(
                          linkPlaceholder,
                        );
                      }
                      return;
                    }
                    final int cursorPosition = _contentController
                        .snapPositionOutOfLink(
                          _contentController.selection.baseOffset,
                        );
                    final String currentText = _contentController.text;

                    String newText;
                    int newCursorPosition;

                    // If no cursor (keyboard closed), insert at the beginning
                    if (cursorPosition <= 0) {
                      final String separator = currentText.isEmpty ? '' : '\n';
                      newText = '$linkPlaceholder $separator$currentText';
                      newCursorPosition = linkPlaceholder.length + 1;
                    } else {
                      final String before = currentText.substring(
                        0,
                        cursorPosition,
                      );
                      final String after = currentText.substring(
                        cursorPosition,
                      );
                      newText = '$before$linkPlaceholder $after';
                      newCursorPosition =
                          cursorPosition + linkPlaceholder.length + 1;
                    }

                    _contentController.value = TextEditingValue(
                      text: newText,
                      selection: TextSelection.collapsed(
                        offset: newCursorPosition,
                      ),
                    );
                    _getNoteContentLength(newText);
                    // A note-link insertion is a real edit: mark the note dirty.
                    _recordEdit();
                  },
                  onAttachmentSelected: () {
                    _fabKey.currentState?.closeVerticalMenu();
                    _tryStorage(_addAttachment);
                  },
                  onImportantSelected: () async {
                    _viewModel.toggleImportant();
                    if (!await _tryStorage(
                      () => _viewModel.autoSaveThemeOrBookmark(
                        title: _titleController.text,
                        content: _contentController.text,
                      ),
                    )) {
                      return;
                    }
                  },
                  onFindSelected: _enterFindMode,
                  onMoveTo: _moveTo,
                  onLockSelected: () async {
                    // Locking takes effect immediately (there is no prompt).
                    // Unlocking shows the system prompt, so close the keyboard
                    // first.
                    if (_viewModel.isLocked) {
                      FocusScope.of(context).unfocus();
                      await Future.delayed(const Duration(milliseconds: 200));
                      if (!mounted) return;
                    }

                    final previousLock = _viewModel.isLocked;
                    final LockToggleResult result = await _viewModel
                        .toggleLock();
                    // The gesture lives in a builder, so guard its own context.
                    if (!context.mounted) return;

                    if (result == LockToggleResult.unavailable) {
                      // No system credential: refuse rather than lock the note
                      // forever.
                      _fabKey.currentState?.closeVerticalMenu();
                      await showAdaptiveAlert(
                        context: context,
                        title: AppText.tr('lock_unavailable_title'),
                        message: AppText.tr('lock_requires_device_lock'),
                      );
                      return;
                    }
                    // A cancelled authentication leaves the menu open so the
                    // user can retry.
                    if (result == LockToggleResult.cancelled) return;

                    // Persist silently, exactly like the bookmark: the lock is
                    // effective immediately, no explicit save is needed.
                    if (!await _tryStorage(
                      () => _viewModel.autoSaveThemeOrBookmark(
                        title: _titleController.text,
                        content: _contentController.text,
                      ),
                    )) {
                      _viewModel.isLocked = previousLock;
                      if (mounted) setState(() {});
                      return;
                    }
                    _fabKey.currentState?.closeVerticalMenu();
                    await FeedbackController.instance.success();
                    if (!context.mounted) return;
                    await showLockToast(
                      context,
                      locked: result == LockToggleResult.locked,
                      folder: false,
                    );
                  },
                  onDeleteSelected: () async {
                    final bool? confirmDeletion = await getConfirmation(
                      context: context,
                      actionTitle: AppText.tr('delete_note'),
                      action: AppText.tr('delete'),
                    );
                    if (confirmDeletion == true) {
                      _deleteNote();
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One attachment row: an icon and the file name; tapping opens the file
/// with the system, and the trailing button removes the attachment.
class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({
    required this.name,
    required this.onOpen,
    required this.onRemove,
  });

  final String name;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: <Widget>[
          Icon(
            Symbols.file_present,
            size: 16.0,
            color: mutedTextColor(context),
          ),
          const SizedBox(width: 4.0),
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: TanoText.label,
                  color: primaryTextColor(context),
                ),
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: AppText.tr('delete'),
            icon: Icon(
              Symbols.close,
              size: 16.0,
              color: mutedTextColor(context),
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
