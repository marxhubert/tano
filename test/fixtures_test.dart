import 'package:flutter_test/flutter_test.dart';
import 'package:tano/fixtures/notes_fixtures.dart';
import 'package:tano/models/database.dart';

void main() {
  group('buildNotesFixtures', () {
    test('créé exactement 24 notes', () {
      expect(buildNotesFixtures(), hasLength(24));
    });

    test('couvre toutes les catégories', () {
      final categories = buildNotesFixtures().map((n) => n.category).toSet();
      expect(
        categories,
        containsAll(<String?>[
          'note',
          'work',
          'personal',
          'travel',
          'life',
          'project',
          'none',
        ]),
      );
    });

    test('mélange favoris et notes classiques', () {
      final notes = buildNotesFixtures();
      expect(notes.any((n) => n.important == true), isTrue);
      expect(notes.any((n) => n.important == false), isTrue);
    });

    test('les dates sont toutes différentes', () {
      final dates = buildNotesFixtures().map((n) => n.date).toSet();
      expect(dates, hasLength(24));
    });

    test('les notes ont un titre et un contenu non vides', () {
      for (final note in buildNotesFixtures()) {
        expect(note.title, isNotEmpty);
        expect(note.content, isNotEmpty);
        expect(note.id, isNotEmpty);
      }
    });

    test('le JSON généré est lisible par le modèle', () {
      final notes = buildNotesFixtures();
      final restored = dbFromJson(dbToJson(Database(note: notes)));
      expect(restored.note, hasLength(24));
      expect(restored.note.first.title, notes.first.title);
      expect(restored.note.first.important, notes.first.important);
    });
  });
}
