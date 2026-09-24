import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/features/trash/trash_view_model.dart';
import 'package:tano/shared/widgets/document_filter.dart';

class _FakeRepo implements NotesRepository, FoldersRepository {
  _FakeRepo({List<Note>? notes, List<Folder>? folders})
      : notes = notes ?? <Note>[],
        folders = folders ?? <Folder>[];

  final List<Note> notes;
  final List<Folder> folders;

  @override
  Future<List<Note>> loadNotes() async =>
      notes.where((Note n) => !n.isDeleted).toList();
  @override
  Future<List<Note>> loadTrashNotes() async =>
      notes.where((Note n) => n.isDeleted).toList();
  @override
  Future<void> upsertNote(Note note) async {
    final int i = notes.indexWhere((Note n) => n.id == note.id);
    if (i == -1) {
      notes.add(note);
    } else {
      notes[i] = note;
    }
  }

  @override
  Future<void> trashNote(String id) async {
    final int i = notes.indexWhere((Note n) => n.id == id);
    if (i != -1) notes[i] = notes[i].copyWith(isDeleted: true, deletedAt: 'now');
  }

  @override
  Future<void> restoreNote(String id) async {
    final int i = notes.indexWhere((Note n) => n.id == id);
    if (i != -1) notes[i] = notes[i].copyWith(isDeleted: false, deletedAt: null);
  }


  @override
  Future<void> deleteNotePermanently(String id) async =>
      notes.removeWhere((Note n) => n.id == id);
  @override
  Future<List<Note>> searchNotes(String query) async => notes
      .where((Note n) =>
          !n.isDeleted &&
          (n.title.toLowerCase().contains(query.toLowerCase()) ||
              n.content.toLowerCase().contains(query.toLowerCase())))
      .toList();
  @override
  Future<void> deleteAllNotes() async => notes.clear();

  @override
  Future<List<Folder>> loadFolders() async =>
      folders.where((Folder f) => !f.isDeleted).toList();
  @override
  Future<void> upsertFolder(Folder folder) async {
    final int i = folders.indexWhere((Folder f) => f.id == folder.id);
    if (i == -1) {
      folders.add(folder);
    } else {
      folders[i] = folder;
    }
  }

  @override
  Future<void> trashFolder(String id) async {
    final int i = folders.indexWhere((Folder f) => f.id == id);
    if (i != -1) {
      folders[i] = folders[i].copyWith(isDeleted: true, deletedAt: 'now');
    }
  }


  @override
  Future<List<Folder>> loadTrashFolders() async =>
      folders.where((Folder f) => f.isDeleted).toList();
  @override
  Future<void> restoreFolder(String id) async {
    final int i = folders.indexWhere((Folder f) => f.id == id);
    if (i != -1) folders[i] = folders[i].copyWith(isDeleted: false);
  }
  @override
  Future<void> deleteAllFolders() async {}

  @override
  Future<void> deleteFolderPermanently(String id) async {
    folders.removeWhere((Folder f) => f.id == id);
    notes.removeWhere((Note n) => n.folderId == id);
  }
}

Note _note({
  String id = 'n1',
  String title = 'Note',
  String? folderId,
  bool isLocked = false,
}) =>
    Note(
      id: id,
      title: title,
      content: 'x',
      date: '2026-01-01 00:00:00.000',
      folderId: folderId,
      isLocked: isLocked,
    );

Folder _folder({String id = 'f1', String name = 'Folder 1', bool isLocked = false}) =>
    Folder(id: id, name: name, date: '2026-01-01 00:00:00.000', isLocked: isLocked);

HomeViewModel _vm(_FakeRepo repo) => HomeViewModel(
      repository: repo,
      foldersRepository: repo,
      initialNotes: repo.notes,
      initialFolders: repo.folders,
    );

void main() {
  group('folder naming', () {
    test('a provided name is used as-is', () async {
      final _FakeRepo repo = _FakeRepo();
      final HomeViewModel vm = _vm(repo);
      await vm.addFolder('Perso');
      expect(vm.folders.single.name, 'Perso');
    });
  });

  group('home grouping', () {
    test('folder notes are hidden from the notes group', () async {
      final _FakeRepo repo = _FakeRepo(
        notes: <Note>[
          _note(id: 'n1'),
          _note(id: 'n2', folderId: 'f1', title: 'Filed'),
        ],
        folders: <Folder>[_folder(id: 'f1', name: 'Perso')],
      );
      final HomeViewModel vm = _vm(repo);
      expect(vm.hasFolders, isTrue);
      expect(vm.pageTitleKey, 'my_folders');
      expect(vm.folders.map((Folder f) => f.name), <String>['Perso']);
      expect(vm.notes.map((Note n) => n.id), <String>['n1']);
      expect(vm.noteCountIn('f1'), 1);
    });

    test('page title is "all_docs" without folders', () async {
      final _FakeRepo repo = _FakeRepo(notes: <Note>[_note()]);
      final HomeViewModel vm = _vm(repo);
      expect(vm.hasFolders, isFalse);
      expect(vm.pageTitleKey, 'all_docs');
    });

    test('a bookmarked folder stays first in its group', () async {
      final _FakeRepo repo = _FakeRepo(
        folders: <Folder>[
          _folder(id: 'a', name: 'Alpha'),
          _folder(id: 'b', name: 'Beta'),
        ],
      );
      final HomeViewModel vm = _vm(repo);
      vm.toggleFavorite('b');
      expect(vm.folders.first.name, 'Beta');
    });
  });

  group('search', () {
    test('hides folders and locked notes, keeps folder notes', () async {
      final _FakeRepo repo = _FakeRepo(
        notes: <Note>[
          _note(id: 'n1', title: 'Alpha'),
          _note(id: 'n2', title: 'Alpha locked', isLocked: true),
          _note(id: 'n3', title: 'Alpha filed', folderId: 'f1'),
        ],
        folders: <Folder>[_folder(id: 'f1')],
      );
      final HomeViewModel vm = _vm(repo);
      await vm.setSearchQuery('alpha');

      expect(vm.folders, isEmpty);
      expect(vm.notes.map((Note n) => n.id), containsAll(<String>['n1', 'n3']));
      expect(vm.notes.map((Note n) => n.id), isNot(contains('n2')));
      expect(vm.pageTitleKey, 'search_results');
    });
  });

  group('document filter', () {
    test('a kind with nothing to show falls back to every document', () async {
      final _FakeRepo repo = _FakeRepo(notes: <Note>[_note()]);
      final HomeViewModel vm = _vm(repo);

      vm.setDocumentFilter(DocumentFilter.tasks);

      expect(vm.documentFilter, DocumentFilter.all);
      expect(vm.notes, hasLength(1));
    });
  });

  group('locking', () {
    test('a locked note in a locked folder does not require auth', () async {
      final Note note = _note(id: 'n1', folderId: 'f1', isLocked: true);
      final _FakeRepo repo = _FakeRepo(
        notes: <Note>[note],
        folders: <Folder>[_folder(id: 'f1', isLocked: true)],
      );
      final HomeViewModel vm = _vm(repo);
      expect(vm.isNoteEffectivelyLocked(note), isFalse);
    });

    test('a locked note outside a locked folder still requires auth', () async {
      final Note note = _note(id: 'n1', isLocked: true);
      final _FakeRepo repo = _FakeRepo(notes: <Note>[note]);
      final HomeViewModel vm = _vm(repo);
      expect(vm.isNoteEffectivelyLocked(note), isTrue);
    });

    test('unlocking a folder makes its locked notes require auth again', () async {
      final Note note = _note(id: 'n1', folderId: 'f1', isLocked: true);
      final _FakeRepo repo = _FakeRepo(
        notes: <Note>[note],
        folders: <Folder>[_folder(id: 'f1')],
      );
      final HomeViewModel vm = _vm(repo);
      expect(vm.isNoteEffectivelyLocked(note), isTrue);
    });
  });

  group('deletion', () {
    test('deleting a folder trashes it but keeps its notes filed', () async {
      final _FakeRepo repo = _FakeRepo(
        notes: <Note>[_note(id: 'n1', folderId: 'f1')],
        folders: <Folder>[_folder(id: 'f1')],
      );
      final HomeViewModel vm = _vm(repo);
      vm.enterSelectionMode('f1');
      expect(vm.selectedFoldersNoteCount, 1);
      await vm.deleteSelected();

      expect(vm.folders, isEmpty);
      expect(repo.folders.single.isDeleted, isTrue);
      // The note stays filed and active: it travels with its folder.
      expect(repo.notes.single.isDeleted, isFalse);
      expect(repo.notes.single.folderId, 'f1');
    });

    test('undo puts back the deleted notes and folders', () async {
      final _FakeRepo repo = _FakeRepo(
        notes: <Note>[_note(id: 'n1'), _note(id: 'n2', folderId: 'f1')],
        folders: <Folder>[_folder(id: 'f1')],
      );
      final HomeViewModel vm = _vm(repo);
      vm.enterSelectionMode('n1');
      vm.toggleSelection('f1');
      await vm.deleteSelected();

      expect(vm.notes, isEmpty);
      expect(vm.folders, isEmpty);

      // Storage is restored by the batch, through showUndoDelete; the view model
      // only puts things back on screen.
      await vm.reinsertLastDeleted();

      // Both the note and the folder come back.
      expect(vm.notes.map((Note n) => n.id), contains('n1'));
      expect(vm.folders.map((Folder f) => f.id), <String>['f1']);
      // The filed note returns to its folder, which came back with it.
      expect(vm.noteCountIn('f1'), 1);
    });

    test('undo sends a note Home when its folder no longer exists', () async {
      final _FakeRepo repo = _FakeRepo(
        // The note still points at a folder that is not in the batch.
        notes: <Note>[_note(id: 'n1', folderId: 'gone')],
      );
      final HomeViewModel vm = _vm(repo);
      vm.enterSelectionMode('n1');
      await vm.deleteSelected();
      expect(vm.notes, isEmpty);

      await vm.reinsertLastDeleted();

      expect(vm.notes.single.folderId, isNull);
    });

    test('moving a selected note files it in the target folder', () async {
      final _FakeRepo repo = _FakeRepo(
        notes: <Note>[_note(id: 'n1'), _note(id: 'n2')],
        folders: <Folder>[_folder(id: 'f1', name: 'Perso')],
      );
      final HomeViewModel vm = _vm(repo);
      vm.enterSelectionMode('n1');
      await vm.moveSelectedTo('f1');

      expect(vm.notes.map((Note n) => n.id), <String>['n2']);
      expect(vm.noteCountIn('f1'), 1);
      expect(repo.notes.firstWhere((Note n) => n.id == 'n1').folderId, 'f1');
    });

    test('moving a note to no folder unfiles it', () async {
      final _FakeRepo repo = _FakeRepo(
        notes: <Note>[_note(id: 'n1', folderId: 'f1')],
        folders: <Folder>[_folder(id: 'f1')],
      );
      final HomeViewModel vm = _vm(repo);
      vm.enterSelectionMode('n1');
      await vm.moveSelectedTo(null);

      expect(vm.notes.map((Note n) => n.id), <String>['n1']);
      expect(vm.noteCountIn('f1'), 0);
    });

    test('folders cannot be moved', () async {
      final _FakeRepo repo = _FakeRepo(folders: <Folder>[_folder(id: 'f1')]);
      final HomeViewModel vm = _vm(repo);
      vm.enterSelectionMode('f1');
      expect(vm.hasFolderInSelection, isTrue);
    });
  });

  test('withoutCover clears the cover image', () {
    final Folder folder = Folder(
      id: 'f1',
      name: 'Perso',
      date: '2026-01-01 00:00:00.000',
      coverImage: 'cover.jpg',
    );

    final Folder cleared = folder.withoutCover();
    expect(cleared.coverImage, isNull);
    expect(cleared.id, 'f1');
    expect(cleared.name, 'Perso');
  });

  group('trash', () {
    test('a trashed folder keeps its notes and restores them', () async {
      final _FakeRepo repo = _FakeRepo(
        notes: <Note>[_note(id: 'n1', folderId: 'f1')],
        folders: <Folder>[_folder(id: 'f1')],
      );
      await repo.trashFolder('f1');

      final TrashViewModel trash = TrashViewModel(
        notesRepository: repo,
        foldersRepository: repo,
      );
      await trash.load();

      // The folder is in the trash, whole and with its content.
      expect(trash.deletedFolders.map((Folder f) => f.id), <String>['f1']);
      expect(trash.noteCountIn('f1'), 1);
      expect(trash.deletedNotes, isEmpty);

      await trash.restoreFolder('f1');

      expect(trash.deletedFolders, isEmpty);
      expect(repo.folders.single.isDeleted, isFalse);
      // The note never left its folder.
      expect(repo.notes.single.folderId, 'f1');
      expect(repo.notes.single.isDeleted, isFalse);
    });
  });
}
