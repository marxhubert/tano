import 'package:flutter/foundation.dart';
import 'package:tano/core/models/content_entity.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';

/// The archive: the documents set aside out of Home and their folders.
///
/// A folder can never be archived, so this view model only holds documents.
class ArchiveViewModel extends ChangeNotifier {
  ArchiveViewModel({required this.repository});

  final NotesRepository repository;

  List<Note> _docs = <Note>[];
  Set<String> _activeNoteIds = <String>{};

  /// The archived documents, newest archive first.
  List<Note> get docs => List.unmodifiable(_docs);

  bool get isEmpty => _docs.isEmpty;

  /// IDs of the notes still in Home, for link styling in the excerpts.
  Set<String> get activeNoteIds => _activeNoteIds;

  ArchiveRepository? get _archive =>
      repository is ArchiveRepository ? repository as ArchiveRepository : null;

  Future<void> load() async {
    final ArchiveRepository? archive = _archive;
    _docs = archive == null
        ? <Note>[]
        : List<Note>.of(await archive.loadArchivedNotes());
    _docs.sort((Note a, Note b) => _newestFirst(a.archivedAt, b.archivedAt));
    _activeNoteIds = activeEntityIds(await repository.loadNotes());
    notifyListeners();
  }

  /// Takes [ids] back to Home: they leave the archive.
  Future<void> restore(List<String> ids) async {
    final ArchiveRepository? archive = _archive;
    if (archive == null || ids.isEmpty) return;
    await archive.restoreArchivedNotes(ids);
    _docs.removeWhere((Note note) => ids.contains(note.id));
    notifyListeners();
  }

  /// Deletes [ids] for good. The caller authenticates locked content first.
  Future<void> deletePermanently(List<String> ids) async {
    if (ids.isEmpty) return;
    for (final String id in ids) {
      await repository.deleteNotePermanently(id);
    }
    _docs.removeWhere((Note note) => ids.contains(note.id));
    notifyListeners();
  }

  static int _newestFirst(String? a, String? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }
}
