import 'package:flutter_test/flutter_test.dart';
import 'package:tano/fixtures/notes_fixtures.dart';
import 'package:tano/services/database.dart';

void main() {
  group('buildNotesFixtures', () {
    test('créé exactement 24 notes', () {
      expect(buildNotesFixtures().note, hasLength(24));
    });

    test('couvre toutes les catégories', () {
      final categories = buildNotesFixtures().note.map((n) => n.category).toSet();
      expect(
        categories,
        containsAll(<String?>['note', 'work', 'personal', 'travel', 'life', 'project', 'none']),
      );
    });

    test('mélange favoris et notes classiques', () {
      final notes = buildNotesFixtures().note;
      expect(notes.any((n) => n.important == true), isTrue);
      expect(notes.any((n) => n.important == false), isTrue);
    });

    test('les dates sont toutes différentes', () {
      final dates = buildNotesFixtures().note.map((n) => n.date).toSet();
      expect(dates, hasLength(24));
    });

    test('les notes ont un titre et un contenu non vides', () {
      for (final note in buildNotesFixtures().note) {
        expect(note.title, isNotEmpty);
        expect(note.content, isNotEmpty);
        expect(note.id, isNotEmpty);
      }
    });

    test('le JSON généré est lisible par le modèle', () {
      final db = buildNotesFixtures();
      final restored = dbFromJson(dbToJson(db));
      expect(restored.note, hasLength(24));
      expect(restored.note.first.title, db.note.first.title);
      expect(restored.note.first.important, db.note.first.important);
    });
  });
}
