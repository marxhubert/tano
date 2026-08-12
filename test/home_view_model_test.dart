import 'package:flutter_test/flutter_test.dart';
import 'package:tano/application/home_view_model.dart';
import 'package:tano/domain/notes_repository.dart';
import 'package:tano/models/note.dart';
import 'package:tano/utils/action.dart';

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
    content: 'Contenu $id',
    date: date ?? '2026-08-01 10:00:00.000',
    important: important,
    category: category ?? 'none',
  );
}

void main() {
  group('HomeViewModel', () {
    test('tri les notes par date (plus récentes d\'abord)', () {
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

    test('load() recharge les notes depuis le repository', () async {
      final repository = _InMemoryNotesRepository(<Note>[_note('1')]);
      final vm = HomeViewModel(repository: repository);

      await vm.load();

      expect(vm.notesCount, 1);
      expect(vm.notes.first.id, '1');
    });

    test('toggleFavorite inverse le statut et persiste', () async {
      final repository = _InMemoryNotesRepository(<Note>[_note('1')]);
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: repository.notes,
      );

      vm.toggleFavorite(0);

      expect(vm.notes[0].important, isTrue);
      expect(repository.notes[0].important, isTrue);
    });

    test('setSortBy réordonne selon le tri choisi', () {
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

    test('setViewLayout ignore les valeurs inconnues', () {
      final vm = HomeViewModel(repository: _InMemoryNotesRepository());

      vm.setViewLayout('bogus');

      expect(vm.viewLayout, 'list');
    });

    test(
      'la sélection multiple supprime toutes les notes sélectionnées',
      () async {
        final repository = _InMemoryNotesRepository();
        final vm = HomeViewModel(
          repository: repository,
          initialNotes: <Note>[_note('1'), _note('2'), _note('3')],
        );

        vm.enterSelectionMode(0);
        vm.toggleSelection(2);

        expect(vm.hasSelection, isTrue);
        expect(vm.selectedCount, 2);

        await vm.deleteSelected();

        expect(vm.notesCount, 1);
        expect(vm.notes.first.id, '2');
        expect(vm.isInSelectionMode, isFalse);
        expect(vm.actionButtons, 'add');
        expect(repository.notes, hasLength(1));
      },
    );

    test('applyNoteAction ajoute une note', () async {
      final repository = _InMemoryNotesRepository();
      final vm = HomeViewModel(repository: repository);

      await vm.applyNoteAction(
        add: true,
        index: -1,
        action: NoteAction(action: 'Save', note: _note('9')),
      );

      expect(vm.notesCount, 1);
      expect(vm.notes.first.id, '9');
      expect(repository.notes, hasLength(1));
    });

    test('applyNoteAction remplace la note modifiée', () async {
      final repository = _InMemoryNotesRepository();
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: <Note>[
          _note('1', title: 'Avant'),
          _note('2'),
        ],
      );

      await vm.applyNoteAction(
        add: false,
        index: 0,
        action: NoteAction(
          action: 'Save',
          note: _note('1', title: 'Après'),
        ),
      );

      expect(vm.notes[0].title, 'Après');
      expect(repository.notes[0].title, 'Après');
    });

    test('applyNoteAction supprime la note', () async {
      final repository = _InMemoryNotesRepository();
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: <Note>[_note('1'), _note('2')],
      );

      await vm.applyNoteAction(
        add: false,
        index: 0,
        action: NoteAction(action: 'Delete'),
      );

      expect(vm.notesCount, 1);
      expect(vm.notes.first.id, '2');
    });

    test('removeNote retire une note (glisser-pour-supprimer)', () async {
      final repository = _InMemoryNotesRepository();
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: <Note>[_note('1'), _note('2')],
      );

      await vm.removeNote(1);

      expect(vm.notesCount, 1);
      expect(vm.notes.first.id, '1');
      expect(repository.notes, hasLength(1));
    });

    test('exitSelectionMode vide la sélection', () {
      final vm = HomeViewModel(
        repository: _InMemoryNotesRepository(),
        initialNotes: <Note>[_note('1'), _note('2')],
      );

      vm.enterSelectionMode(0);
      vm.selectAll();
      vm.exitSelectionMode();

      expect(vm.isInSelectionMode, isFalse);
      expect(vm.hasSelection, isFalse);
    });
  });
}
