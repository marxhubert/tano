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
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/app_fab.dart';
import 'package:tano/shared/widgets/confirm.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/page_layout.dart';
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

  late Folder _folder;
  List<Note> _notes = <Note>[];
  bool _loading = true;

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
    _load();
  }

  Future<void> _load() async {
    final List<Note> all = await getIt<NotesRepository>().loadNotes();
    if (!mounted) return;
    setState(() {
      _notes = all.where((Note note) => note.folderId == _folder.id).toList();
      _loading = false;
    });
  }

  Future<void> _save(Folder folder) async {
    await _foldersRepository?.upsertFolder(folder);
    if (!mounted) return;
    setState(() => _folder = folder);
  }

  Future<void> _openNote({required bool add, required Note note}) async {
    final NoteAction? result = await Navigator.push<NoteAction>(
      context,
      MaterialPageRoute<NoteAction>(
        builder: (BuildContext context) => EditNote(
          add: add,
          index: -1,
          noteAction: NoteAction(kind: NoteActionKind.cancel, note: note),
          // Inside a locked folder the folder authentication already happened.
          authenticated: _folder.isLocked,
        ),
      ),
    );
    if (result != null && result.note != null) {
      await getIt<NotesRepository>().upsertNote(result.note!);
    }
    await _load();
  }

  Note _newNote() =>
      Note(folderId: _folder.id, category: _folder.category);

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
      // Locking is refused when the device cannot authenticate.
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

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: _folder.name,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _openNote(add: true, note: _newNote()),
        ),
      ],
      floatingActionButtonLocation: const FlushEndFabLocation(),
      floatingActionButton: AppFab(
        key: _fabKey,
        isEditorMode: true,
        isFolderMode: true,
        isPinned: _folder.isPinned,
        isImportant: _folder.important,
        isLocked: _folder.isLocked,
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
      ),
      slivers: <Widget>[
        if (_folder.coverImage != null)
          SliverToBoxAdapter(
            child: FutureBuilder<String>(
              future: _attachmentsStore.materialize(_folder.coverImage!),
              builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 0.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(appBorderRadius),
                    child: Image.file(
                      File(snapshot.data!),
                      height: 160.0,
                      width: double.infinity,
                      fit: BoxFit.cover,
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
        else if (_notes.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                AppText.tr('folder_empty'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.0, color: mutedTextColor(context)),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(appPaddingMedium),
            sliver: SliverList.separated(
              itemCount: _notes.length,
              itemBuilder: (BuildContext context, int index) {
                final Note note = _notes[index];
                return NoteCard(
                  note: note,
                  onTap: () => _openNote(add: false, note: note),
                  builder: (BuildContext context, Color textColor) => ListTile(
                    title: Text(
                      note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.0,
                        color: textColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (BuildContext context, int index) =>
                  const SizedBox(height: 8.0),
            ),
          ),
      ],
    );
  }
}
