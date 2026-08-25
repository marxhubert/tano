import 'package:flutter_test/flutter_test.dart';
import 'package:tano/features/editor/edit_note_view_model.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';

class _InMemoryNotesRepository implements NotesRepository {
  _InMemoryNotesRepository([List<Note>? notes]) : notes = notes ?? <Note>[];

  final List<Note> notes;

  @override
  Future<List<Note>> loadNotes() async => notes.where((n) => !n.isDeleted).toList();

  @override
  Future<List<Note>> loadTrashNotes() async => notes.where((n) => n.isDeleted).toList();

  @override
  Future<void> upsertNote(Note note) async {
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
  }

  @override
  Future<void> trashNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now().toString(),
      );
    }
  }

  @override
  Future<void> restoreNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(
        isDeleted: false,
        deletedAt: null,
      );
    }
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

  @override
  Future<void> deleteNotePermanently(String id) async {
    notes.removeWhere((n) => n.id == id);
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    return notes
        .where((n) =>
            !n.isDeleted &&
            (n.title.toLowerCase().contains(query.toLowerCase()) ||
                n.content.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }
}

void main() {
  group('EditNoteViewModel', () {
    test('buildNote uses the title when provided', () {
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: true,
      );

      final note = vm.buildNote(title: 'My title', content: 'Some content');

      expect(note.title, 'My title');
      expect(note.content, 'Some content');
    });

    test('buildNote uses the start of the content as title when empty', () {
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: true,
      );

      final note = vm.buildNote(title: '', content: 'A fairly long note content');

      expect(note.title, 'A fairly long note');
      expect(note.content, 'A fairly long note content');
    });

    test('buildNote handles empty content without error', () {
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: true,
      );

      final note = vm.buildNote(title: '', content: '');

      expect(note.title, '');
      expect(note.content, '');
    });

    test('isDirty is false when nothing changed', () {
      final note = Note(
        id: '1',
        title: 'Title',
        content: 'Content',
        date: '2026-08-01 10:00:00.000',
        important: false,
        category: 'none',
      );
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: false,
        initialNote: note,
      );

      expect(vm.isDirty(title: 'Title', content: 'Content'), isFalse);
    });

    test('isDirty is true when the content changes', () {
      final note = Note(
        id: '1',
        title: 'Title',
        content: 'Content',
        date: '2026-08-01 10:00:00.000',
      );
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: false,
        initialNote: note,
      );

      expect(vm.isDirty(title: 'Title', content: 'Other content'), isTrue);
    });

    test('persistSavedNote adds a new note', () async {
      final repository = _InMemoryNotesRepository(<Note>[
        Note(
          id: '1',
          title: 'Existing',
          content: 'x',
          date: '2026-08-01 10:00:00.000',
        ),
      ]);
      final vm = EditNoteViewModel(repository: repository, add: true);

      await vm.persistSavedNote(
        Note(
          id: '42',
          title: 'New',
          content: 'y',
          date: '2026-08-02 10:00:00.000',
        ),
      );

      expect(repository.notes, hasLength(2));
      expect(repository.notes.any((n) => n.id == '42'), isTrue);
    });

    test('persistSavedNote replaces the existing note by its id', () async {
      final repository = _InMemoryNotesRepository(<Note>[
        Note(
          id: '1',
          title: 'Before',
          content: 'x',
          date: '2026-08-01 10:00:00.000',
        ),
        Note(
          id: '2',
          title: 'Untouched',
          content: 'y',
          date: '2026-08-02 10:00:00.000',
        ),
      ]);
      final vm = EditNoteViewModel(
        repository: repository,
        add: false,
        initialNote: repository.notes.first,
      );

      await vm.persistSavedNote(
        Note(
          id: '1',
          title: 'After',
          content: 'z',
          date: '2026-08-01 10:00:00.000',
        ),
      );

      expect(repository.notes, hasLength(2));
      expect(repository.notes[0].title, 'After');
      expect(repository.notes[1].title, 'Untouched');
    });

    test('toggleImportant and setCategory update the state and notify', () {
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: true,
      );
      int notifications = 0;
      vm.addListener(() => notifications++);

      vm.toggleImportant();
      vm.setCategory('work');

      expect(vm.important, isTrue);
      expect(vm.category, 'work');
      expect(notifications, 2);
    });
  });
}
