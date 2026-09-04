import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/notes_json_codec.dart';
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

    test('legacy category values normalize to the canonical default', () {
      expect(Note.fromJson({'category': 'none'}).category, 'nuage');
      expect(Note.fromJson({'category': 'neutral'}).category, 'nuage');
      expect(Note.fromJson({'category': ''}).category, 'nuage');
      expect(Note.fromJson({'category': 'menthe'}).category, 'menthe');
    });

    test('serializes and deserializes attachments', () {
      final note = Note(
        id: '1',
        title: 'a',
        attachments: <String>['x.txt', 'y.pdf'],
      );
      final restored = Note.fromJson(note.toJson());
      expect(restored.attachments, <String>['x.txt', 'y.pdf']);
    });

    test('missing attachments default to an empty list', () {
      expect(Note.fromJson(<String, dynamic>{}).attachments, isEmpty);
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
      expect(restored.category, 'nuage');
    });
  });

  group('notes JSON codec', () {
    test('encodes and decodes the JSON', () {
      final notes = <Note>[
        Note(id: '1', title: 'a', content: 'x', important: true),
        Note(id: '2', title: 'b', content: 'y', important: false),
      ];

      final restored = decodeNotes(encodeNotes(notes));

      expect(restored, hasLength(2));
      expect(restored[0].title, 'a');
      expect(restored[0].important, true);
      expect(restored[1].title, 'b');
      expect(restored[1].important, false);
    });

    test('decodes an empty note list', () {
      expect(decodeNotes('{"notes": []}'), isEmpty);
    });

    test('handles a JSON without the notes key', () {
      expect(decodeNotes('{}'), isEmpty);
    });
  });
}
