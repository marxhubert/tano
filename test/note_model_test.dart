import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/database.dart';
import 'package:tano/core/models/note.dart';

void main() {
  group('Note', () {
    test('serializes and deserializes a note', () {
      final note = Note(
        id: '123',
        title: 'Title',
        content: 'Content',
        date: '2026-08-12 10:00:00.000',
        important: true,
        category: 'work',
      );

      final json = note.toJson();
      final restored = Note.fromJson(json);

      expect(restored.id, '123');
      expect(restored.title, 'Title');
      expect(restored.content, 'Content');
      expect(restored.date, '2026-08-12 10:00:00.000');
      expect(restored.important, true);
      expect(restored.category, 'work');
    });

    test('important is preserved when false', () {
      final note = Note(id: '1', title: 'a', important: false);
      final restored = Note.fromJson(note.toJson());
      expect(restored.important, false);
    });

    test('missing fields have safe default values', () {
      final restored = Note.fromJson(<String, dynamic>{});
      expect(restored.id, '');
      expect(restored.important, false);
      expect(restored.category, 'none');
    });
  });

  group('NotesJsonData', () {
    test('encodes and decodes the JSON', () {
      final db = NotesJsonData(
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

    test('empty note list by default', () {
      expect(NotesJsonData().note, isEmpty);
      expect(dbFromJson('{"notes": []}').note, isEmpty);
    });

    test('handles a JSON without the notes key', () {
      expect(dbFromJson('{}').note, isEmpty);
    });
  });
}
