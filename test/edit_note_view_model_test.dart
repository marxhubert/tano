import 'package:flutter_test/flutter_test.dart';
import 'package:tano/application/edit_note_view_model.dart';
import 'package:tano/domain/notes_repository.dart';
import 'package:tano/models/note.dart';

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

void main() {
  group('EditNoteViewModel', () {
    test('buildNote utilise le titre quand il est fourni', () {
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: true,
      );

      final note = vm.buildNote(title: 'Mon titre', content: 'Un contenu');

      expect(note.title, 'Mon titre');
      expect(note.content, 'Un contenu');
    });

    test('buildNote utilise le début du contenu comme titre si vide', () {
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: true,
      );

      final note = vm.buildNote(title: '', content: 'Un long contenu de note');

      expect(note.title, 'Un long contenu de');
      expect(note.content, 'Un long contenu de note');
    });

    test('buildNote gère un contenu vide sans erreur', () {
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: true,
      );

      final note = vm.buildNote(title: '', content: '');

      expect(note.title, '');
      expect(note.content, '');
    });

    test('isDirty est faux quand rien n\'a changé', () {
      final note = Note(
        id: '1',
        title: 'Titre',
        content: 'Contenu',
        date: '2026-08-01 10:00:00.000',
        important: false,
        category: 'none',
      );
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: false,
        initialNote: note,
      );

      expect(vm.isDirty(title: 'Titre', content: 'Contenu'), isFalse);
    });

    test('isDirty est vrai quand le contenu change', () {
      final note = Note(
        id: '1',
        title: 'Titre',
        content: 'Contenu',
        date: '2026-08-01 10:00:00.000',
      );
      final vm = EditNoteViewModel(
        repository: _InMemoryNotesRepository(),
        add: false,
        initialNote: note,
      );

      expect(vm.isDirty(title: 'Titre', content: 'Autre contenu'), isTrue);
    });

    test('persistSavedNote ajoute une nouvelle note', () async {
      final repository = _InMemoryNotesRepository(<Note>[
        Note(
          id: '1',
          title: 'Existante',
          content: 'x',
          date: '2026-08-01 10:00:00.000',
        ),
      ]);
      final vm = EditNoteViewModel(repository: repository, add: true);

      await vm.persistSavedNote(
        Note(
          id: '42',
          title: 'Nouvelle',
          content: 'y',
          date: '2026-08-02 10:00:00.000',
        ),
      );

      expect(repository.notes, hasLength(2));
      expect(repository.notes.any((n) => n.id == '42'), isTrue);
    });

    test('persistSavedNote remplace la note existante par son id', () async {
      final repository = _InMemoryNotesRepository(<Note>[
        Note(
          id: '1',
          title: 'Avant',
          content: 'x',
          date: '2026-08-01 10:00:00.000',
        ),
        Note(
          id: '2',
          title: 'Intacte',
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
          title: 'Après',
          content: 'z',
          date: '2026-08-01 10:00:00.000',
        ),
      );

      expect(repository.notes, hasLength(2));
      expect(repository.notes[0].title, 'Après');
      expect(repository.notes[1].title, 'Intacte');
    });

    test('toggleImportant et setCategory modifient l\'état et notifient', () {
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
