import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/repositories/notes_fixtures.dart';
import 'package:tano/core/models/database.dart';

void main() {
  group('buildNotesFixtures', () {
    test('creates exactly 24 notes', () {
      expect(buildNotesFixtures(), hasLength(24));
    });

    test('covers all the categories', () {
      final categories = buildNotesFixtures().map((n) => n.category).toSet();
      expect(
        categories,
        containsAll(<String?>[
          'menthe',
          'citron',
          'peche',
          'lavande',
          'rose',
          'azur',
          'sable',
          'sauge',
          'bonbon',
          'nuage',
        ]),
      );
    });

    test('mixes favorites and regular notes', () {
      final notes = buildNotesFixtures();
      expect(notes.any((n) => n.important == true), isTrue);
      expect(notes.any((n) => n.important == false), isTrue);
    });

    test('the dates are all different', () {
      final dates = buildNotesFixtures().map((n) => n.date).toSet();
      expect(dates, hasLength(24));
    });

    test('the notes have a non-empty title and content', () {
      for (final note in buildNotesFixtures()) {
        expect(note.title, isNotEmpty);
        expect(note.content, isNotEmpty);
        expect(note.id, isNotEmpty);
      }
    });

    test('the generated JSON is readable by the model', () {
      final notes = buildNotesFixtures();
      final restored = dbFromJson(dbToJson(Database(note: notes)));
      expect(restored.note, hasLength(24));
      expect(restored.note.first.title, notes.first.title);
      expect(restored.note.first.important, notes.first.important);
    });
  });
}
