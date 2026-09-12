import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/notes/home_view_model.dart';

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
  Future<void> togglePin(String id) async {
    final int i = notes.indexWhere((Note n) => n.id == id);
    if (i != -1) notes[i] = notes[i].copyWith(isPinned: !notes[i].isPinned);
  }

  @override
  Future<void> toggleLock(String id, {String? password}) async {}
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
  Future<void> seedFixtures() async {}

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
  Future<void> toggleFolderPin(String id) async {
    final int i = folders.indexWhere((Folder f) => f.id == id);
    if (i != -1) {
      folders[i] = folders[i].copyWith(isPinned: !folders[i].isPinned);
    }
  }

  @override
  Future<String> nextFolderName() async {
    final Set<String> names = folders.map((Folder f) => f.name).toSet();
    int i = 1;
    while (names.contains('Folder $i')) {
      i++;
    }
    return 'Folder $i';
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
    test('empty name falls back to the next "Folder X"', () async {
      final _FakeRepo repo = _FakeRepo();
      final HomeViewModel vm = _vm(repo);
      await vm.addFolder('');
      expect(vm.folders.single.name, 'Folder 1');

      await vm.addFolder('   ');
      expect(vm.folders.map((Folder f) => f.name), containsAll(<String>['Folder 1', 'Folder 2']));
    });

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

    test('page title stays "all_notes" without folders', () async {
      final _FakeRepo repo = _FakeRepo(notes: <Note>[_note()]);
      final HomeViewModel vm = _vm(repo);
      expect(vm.hasFolders, isFalse);
      expect(vm.pageTitleKey, 'all_notes');
    });

    test('a pinned folder stays first in its group', () async {
      final _FakeRepo repo = _FakeRepo(
        folders: <Folder>[
          _folder(id: 'a', name: 'Alpha'),
          _folder(id: 'b', name: 'Beta'),
        ],
      );
      final HomeViewModel vm = _vm(repo);
      await vm.togglePin('b');
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
    test('deleting a folder also trashes its notes', () async {
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
      // The folder content goes to the trash with it.
      expect(vm.notes, isEmpty);
      expect(repo.notes.single.isDeleted, isTrue);
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
}
