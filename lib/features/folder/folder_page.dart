import 'package:flutter/material.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

/// Shows the notes filed in a single folder.
class FolderPage extends StatefulWidget {
  const FolderPage({super.key, required this.folder});

  final Folder folder;

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<Note> _notes = <Note>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final List<Note> all = await getIt<NotesRepository>().loadNotes();
    if (!mounted) return;
    setState(() {
      _notes = all
          .where((Note note) => note.folderId == widget.folder.id)
          .toList();
      _loading = false;
    });
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
          authenticated: widget.folder.isLocked,
        ),
      ),
    );
    if (result != null && result.note != null) {
      await getIt<NotesRepository>().upsertNote(result.note!);
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: widget.folder.name,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _openNote(
            add: true,
            note: Note(folderId: widget.folder.id, category: widget.folder.category),
          ),
        ),
      ],
      slivers: <Widget>[
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
