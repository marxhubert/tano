import 'package:flutter_test/flutter_test.dart';
import 'package:tano/features/search/search_view_model.dart';
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
}

Note _note(String id, {String? title, String? content, String? date}) {
  return Note(
    id: id,
    title: title ?? 'Title $id',
    content: content ?? 'Content $id',
    date: date ?? '2026-08-01 10:00:00.000',
    important: false,
    category: 'none',
  );
}

void main() {
  group('SearchViewModel', () {
    test(
      'load() loads and sorts the notes by date (newest first)',
      () async {
        final vm = SearchViewModel(
          repository: _InMemoryNotesRepository(<Note>[
            _note('1', date: '2026-08-01 10:00:00.000'),
            _note('2', date: '2026-09-01 10:00:00.000'),
          ]),
        );

        await vm.load();

        vm.search('title');
        expect(vm.results.first.id, '2');
      },
    );

    test('search() filters by title, case-insensitively', () async {
      final vm = SearchViewModel(
        repository: _InMemoryNotesRepository(<Note>[
          _note('1', title: 'Groceries'),
          _note('2', title: 'Project kickoff'),
        ]),
      );
      await vm.load();

      vm.search('grocer');

      expect(vm.resultCount, 1);
      expect(vm.results.first.id, '1');
    });

    test('search() also filters by content', () async {
      final vm = SearchViewModel(
        repository: _InMemoryNotesRepository(<Note>[
          _note('1', content: 'Call the dentist'),
          _note('2', content: 'Nothing to do with it'),
        ]),
      );
      await vm.load();

      vm.search('dentist');

      expect(vm.resultCount, 1);
      expect(vm.results.first.id, '1');
    });

    test('search() with an empty query clears the results', () async {
      final vm = SearchViewModel(
        repository: _InMemoryNotesRepository(<Note>[_note('1')]),
      );
      await vm.load();

      vm.search('title');
      expect(vm.hasResults, isTrue);

      vm.search('');

      expect(vm.hasResults, isFalse);
    });

    test(
      'applyNoteAction replaces the right note in the full list',
      () async {
        final repository = _InMemoryNotesRepository(<Note>[
          _note('1', title: 'Alpha'),
          _note('2', title: 'Beta'),
          _note('3', title: 'Gamma'),
        ]);
        final vm = SearchViewModel(repository: repository);
        await vm.load();

        vm.search('alpha');
        final Note found = vm.results.single;
        final Note edited = Note(
          id: found.id,
          title: 'Alpha modified',
          content: found.content,
          date: found.date,
          important: found.important,
          category: found.category,
        );

        await vm.applyNoteAction(
          original: found,
          action: NoteAction(kind: NoteActionKind.save, note: edited),
        );

        expect(repository.notes.map((n) => n.title), contains('Alpha modified'));
        // The update targets the note by identity even though the result list
        // is only a subset of the full list.
        expect(repository.notes[0].title, 'Alpha modified');
      },
    );

    test('applyNoteAction deletes the note', () async {
      final repository = _InMemoryNotesRepository(<Note>[
        _note('1', title: 'Alpha'),
        _note('2', title: 'Beta'),
      ]);
      final vm = SearchViewModel(repository: repository);
      await vm.load();

      vm.search('beta');
      final Note found = vm.results.single;

      await vm.applyNoteAction(
        original: found,
        action: NoteAction(kind: NoteActionKind.delete),
      );

      expect(repository.notes, hasLength(1));
      expect(repository.notes.first.id, '1');
      expect(vm.hasResults, isFalse);
    });
  });
}
