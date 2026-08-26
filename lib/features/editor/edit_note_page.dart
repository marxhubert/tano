import 'package:flutter/material.dart';
import 'package:tano/features/editor/edit_note_view_model.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/shared/widgets/menu.dart';
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

  Future<void> _handleLinkTap() async {
    final offset = _contentController.selection.baseOffset;
    if (offset < 0) return;

    final String? noteId = _contentController.getLinkIdAt(offset);
    if (noteId != null && context.mounted) {
      final repository = getIt<NotesRepository>();
      final notes = await repository.loadNotes();
      final targetNote = notes.firstWhere((n) => n.id == noteId, orElse: () => Note());
      
      if (targetNote.id.isNotEmpty && context.mounted) {
        // Save current note changes if any before navigating
        final currentNote = _viewModel.buildNote(
          title: _titleController.text, 
          content: _contentController.text
        );
        
        if (_viewModel.isDirty(title: _titleController.text, content: _contentController.text)) {
           await _viewModel.persistSavedNote(currentNote);
        }

        if (context.mounted) {
          // Standard push to allow "Back" button to return naturally
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
          
          // Refresh state when returning in case the target note was changed
          if (context.mounted) {
            await _viewModel.load();
            _getNoteContentLength(_contentController.text);
          }
        }
      }
    }
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
              titleHint: AppText.tr('title_here'),
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
                const ThemeToggleButton(),
                IconButton(
                  icon: Icon(
                    _viewModel.important
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: _viewModel.important ? tanoAmber : null,
                  ),
                  onPressed: () async {
                    _viewModel.toggleImportant();
                    await _viewModel.autoSaveThemeOrBookmark(
                      title: _titleController.text,
                      content: _contentController.text,
                    );
                  },
                ),
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
                  final int cursorPosition = _contentController.selection.baseOffset;
                  final String currentText = _contentController.text;
                  
                  String newText;
                  int newCursorPosition;
                  
                  // If no cursor (keyboard closed), insert at the beginning
                  if (cursorPosition <= 0) {
                    newText = linkPlaceholder + " " + (currentText.isEmpty ? "" : "\n") + currentText;
                    newCursorPosition = linkPlaceholder.length + 1;
                  } else {
                    newText = currentText.substring(0, cursorPosition) + 
                              linkPlaceholder + " " + 
                              currentText.substring(cursorPosition);
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
