import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/database.dart';
import 'package:tano/core/models/note.dart';

void main() {
  group('Note', () {
    test('sérialise et désérialise une note', () {
      final note = Note(
        id: '123',
        title: 'Titre',
        content: 'Contenu',
        date: '2026-08-12 10:00:00.000',
        important: true,
        category: 'work',
      );

      final json = note.toJson();
      final restored = Note.fromJson(json);

      expect(restored.id, '123');
      expect(restored.title, 'Titre');
      expect(restored.content, 'Contenu');
      expect(restored.date, '2026-08-12 10:00:00.000');
      expect(restored.important, true);
      expect(restored.category, 'work');
    });

    test('important est conservé quand false', () {
      final note = Note(id: '1', title: 'a', important: false);
      final restored = Note.fromJson(note.toJson());
      expect(restored.important, false);
    });

    test('les champs absents ont des valeurs par défaut sûres', () {
      final restored = Note.fromJson(<String, dynamic>{});
      expect(restored.id, isNull);
      expect(restored.important, false);
      expect(restored.category, isNull);
    });
  });

  group('Database', () {
    test('encode et décode le JSON', () {
      final db = Database(
        note: [
          Note(id: '1', title: 'a', content: 'x', important: true),
          Note(id: '2', title: 'b', content: 'y', important: false),
        ],
      );

      final restored = dbFromJson(dbToJson(db));

      expect(restored.note, hasLength(2));
      expect(restored.note[0].title, 'a');
      expect(restored.note[0].important, true);
      expect(restored.note[1].title, 'b');
      expect(restored.note[1].important, false);
    });

    test('liste de notes vide par défaut', () {
      expect(Database().note, isEmpty);
      expect(dbFromJson('{"notes": []}').note, isEmpty);
    });

    test('gère un JSON sans clé notes', () {
      expect(dbFromJson('{}').note, isEmpty);
    });
  });
}
