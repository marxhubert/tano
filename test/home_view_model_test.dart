import 'package:flutter_test/flutter_test.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/action.dart';

class _InMemoryNotesRepository implements NotesRepository {
  _InMemoryNotesRepository([List<Note>? notes]) : notes = notes ?? <Note>[];

  final List<Note> notes;

  @override
  Future<List<Note>> loadNotes() async => List<Note>.of(notes);

  @override
  Future<void> saveNotes(List<Note> notes) async {
    this.notes
      ..clear()
      ..addAll(notes);
  }

  @override
  Future<void> trashNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) notes[index] = notes[index].copyWith(isDeleted: true);
  }

  @override
  Future<void> restoreNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) notes[index] = notes[index].copyWith(isDeleted: false);
  }

  @override
  Future<void> togglePin(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) notes[index] = notes[index].copyWith(isPinned: !notes[index].isPinned);
  }

  @override
  Future<void> toggleLock(String id, {String? password}) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) notes[index] = notes[index].copyWith(isLocked: !notes[index].isLocked);
  }
}

Note _note(
  String id, {
  String? title,
  String? date,
  bool important = false,
  String? category,
}) {
  return Note(
    id: id,
    title: title ?? 'Note $id',
    content: 'Content $id',
    date: date ?? '2026-08-01 10:00:00.000',
    important: important,
    category: category ?? 'none',
  );
}

void main() {
  group('HomeViewModel', () {
    test('sorts the notes by date (newest first by default)', () {
      final vm = HomeViewModel(
        repository: _InMemoryNotesRepository(),
        initialNotes: <Note>[
          _note('1', date: '2026-08-01 10:00:00.000'),
          _note('2', date: '2026-09-01 10:00:00.000'),
        ],
      );

      expect(vm.notes.first.id, '2');
      expect(vm.notesCount, 2);
    });

    test('sorts the notes by date (oldest first when descending)', () {
      final vm = HomeViewModel(
        repository: _InMemoryNotesRepository(),
        initialNotes: <Note>[
          _note('1', date: '2026-08-01 10:00:00.000'),
          _note('2', date: '2026-09-01 10:00:00.000'),
        ],
      );

      vm.setSortAscending(false);

      expect(vm.notes.first.id, '1');
    });

    test('load() reloads the notes from the repository', () async {
      final repository = _InMemoryNotesRepository(<Note>[_note('1')]);
      final vm = HomeViewModel(repository: repository);

      await vm.load();

      expect(vm.notesCount, 1);
      expect(vm.notes.first.id, '1');
    });

    test('toggleFavorite flips the status and persists', () async {
      final repository = _InMemoryNotesRepository(<Note>[_note('1')]);
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: repository.notes,
      );

      vm.toggleFavorite('1');

      expect(vm.notes[0].important, isTrue);
      expect(repository.notes[0].important, isTrue);
    });

    test('setSortBy reorders according to the chosen sorting', () {
      final vm = HomeViewModel(
        repository: _InMemoryNotesRepository(),
        initialNotes: <Note>[
          _note('1', title: 'Zebra'),
          _note('2', title: 'Alpha'),
        ],
      );

      vm.setSortBy('alpha');

      expect(vm.notes.first.id, '2');
    });

    test('setViewLayout ignores unknown values', () {
      final vm = HomeViewModel(repository: _InMemoryNotesRepository());

      vm.setViewLayout('bogus');

      expect(vm.viewLayout, 'gridlist');
    });

    test(
      'multiple selection deletes all the selected notes',
      () async {
        final initialNotes = <Note>[_note('1'), _note('2'), _note('3')];
        final repository = _InMemoryNotesRepository(List.from(initialNotes));
        final vm = HomeViewModel(
          repository: repository,
          initialNotes: initialNotes,
        );

        vm.enterSelectionMode('1');
        vm.toggleSelection('3');

        expect(vm.hasSelection, isTrue);
        expect(vm.selectedCount, 2);

        await vm.deleteSelected();

        expect(vm.notesCount, 1);
        expect(vm.notes.first.id, '2');
        expect(vm.isInSelectionMode, isFalse);
        expect(vm.actionButtons, 'add');
        
        // In Phase 2, notes are not removed from repository but marked as deleted
        expect(repository.notes.where((n) => !n.isDeleted), hasLength(1));
      },
    );

    test('applyNoteAction adds a note', () async {
      final repository = _InMemoryNotesRepository();
      final vm = HomeViewModel(repository: repository);

      await vm.applyNoteAction(
        add: true,
        originalId: '',
        action: NoteAction(kind: NoteActionKind.save, note: _note('9')),
      );

      expect(vm.notesCount, 1);
      expect(vm.notes.first.id, '9');
      expect(repository.notes, hasLength(1));
    });

    test('applyNoteAction replaces the modified note', () async {
      final repository = _InMemoryNotesRepository();
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: <Note>[
          _note('1', title: 'Before'),
          _note('2'),
        ],
      );

      await vm.applyNoteAction(
        add: false,
        originalId: '1',
        action: NoteAction(
          kind: NoteActionKind.save,
          note: _note('1', title: 'After'),
        ),
      );

      expect(vm.notes[0].title, 'After');
      expect(repository.notes[0].title, 'After');
    });

    test('applyNoteAction deletes the note', () async {
      final repository = _InMemoryNotesRepository();
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: <Note>[_note('1'), _note('2')],
      );

      await vm.applyNoteAction(
        add: false,
        originalId: '1',
        action: NoteAction(kind: NoteActionKind.delete),
      );

      expect(vm.notesCount, 1);
      expect(vm.notes.first.id, '2');
    });

    test('removeNote removes a note (swipe-to-delete)', () async {
      final initialNotes = <Note>[_note('1'), _note('2')];
      final repository = _InMemoryNotesRepository(List.from(initialNotes));
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: initialNotes,
      );

      await vm.removeNote('2');

      expect(vm.notesCount, 1);
      expect(vm.notes.first.id, '1');
      // In Phase 2, notes are not removed from repository but marked as deleted
      expect(repository.notes.where((n) => !n.isDeleted), hasLength(1));
    });

    test('exitSelectionMode clears the selection', () {
      final vm = HomeViewModel(
        repository: _InMemoryNotesRepository(),
        initialNotes: <Note>[_note('1'), _note('2')],
      );

      vm.enterSelectionMode('1');
      vm.selectAll();
      vm.exitSelectionMode();

      expect(vm.isInSelectionMode, isFalse);
      expect(vm.hasSelection, isFalse);
    });
  });
}
