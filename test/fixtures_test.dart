import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/notes_json_codec.dart';
import 'package:tano/core/repositories/notes_fixtures.dart';

void main() {
  // Built once: generating ~110 long notes is heavy, and the fixed seed makes
  // the set fully reproducible.
  final TanoFixtures fixtures = buildFixtures();

  group('buildFixtures', () {
    test('creates 5 folders, exactly one of them empty', () {
      expect(fixtures.folders, hasLength(5));

      final List<int> sizes = <int>[
        for (final Folder folder in fixtures.folders)
          fixtures.notes.where((Note n) => n.folderId == folder.id).length,
      ];
      expect(sizes.where((int s) => s == 0), hasLength(1));
      for (final int size in sizes.where((int s) => s > 0)) {
        expect(size, inInclusiveRange(15, 27));
      }
    });

    test('creates 33 notes that are not filed in any folder', () {
      expect(
        fixtures.notes.where((Note n) => n.folderId == null),
        hasLength(33),
      );
    });

    test('every note has a 450..630 word text', () {
      for (final Note note in fixtures.notes) {
        final String text = note.content.split('\n\n').first;
        final int words = text
            .split(RegExp(r'\s+'))
            .where((String w) => w.isNotEmpty)
            .length;
        expect(words, inInclusiveRange(450, 630));
      }
    });

    test('only 2 folders are locked, never the empty one', () {
      expect(
        fixtures.folders.where((Folder f) => !f.isLocked),
        hasLength(3),
      );
      final Folder empty = fixtures.folders.firstWhere(
        (Folder f) => fixtures.notes.every((Note n) => n.folderId != f.id),
      );
      expect(empty.isLocked, isFalse);
    });

    test('folder notes respect the pin/bookmark/lock constraints', () {
      final List<Note> filed = fixtures.notes
          .where((Note n) => n.folderId != null)
          .toList();

      expect(filed.where((Note n) => n.isPinned).length, lessThanOrEqualTo(3));
      expect(filed.where((Note n) => n.important).length, lessThanOrEqualTo(6));
      expect(filed.where((Note n) => n.isLocked), hasLength(3));
      // No pinned or bookmarked note is locked.
      expect(
        filed.where((Note n) => n.isLocked && (n.isPinned || n.important)),
        isEmpty,
      );
      // 10 folder notes have nothing but their text and theme.
      expect(
        filed.where((Note n) => n.content.split('\n\n').length == 1),
        hasLength(10),
      );
    });

    test('unfiled notes respect the pin/bookmark/lock constraints', () {
      final List<Note> loose = fixtures.notes
          .where((Note n) => n.folderId == null)
          .toList();

      expect(loose.where((Note n) => n.isPinned).length, lessThanOrEqualTo(6));
      expect(loose.where((Note n) => n.important).length, lessThanOrEqualTo(12));
      expect(loose.where((Note n) => n.isLocked), hasLength(9));
      // No pinned or bookmarked note is locked.
      expect(
        loose.where((Note n) => n.isLocked && (n.isPinned || n.important)),
        isEmpty,
      );
      expect(
        loose.where((Note n) => !n.isPinned && !n.isLocked && !n.important),
        hasLength(15),
      );
      // 12 unfiled notes have nothing but their text and theme.
      expect(
        loose.where((Note n) => n.content.split('\n\n').length == 1),
        hasLength(12),
      );
    });

    test('rich notes carry 3..12 inserted notes and 1..3 checklists', () {
      final RegExp links = RegExp(r'\[\[');
      final RegExp checklists = RegExp(r'^## ', multiLine: true);
      final RegExp items = RegExp(r'^- \[[ x]\]', multiLine: true);

      bool seenRich = false;
      for (final Note note in fixtures.notes) {
        if (note.content.split('\n\n').length == 1) continue;
        seenRich = true;

        final int linkCount = links.allMatches(note.content).length;
        final int checklistCount = checklists.allMatches(note.content).length;
        final int itemCount = items.allMatches(note.content).length;

        expect(linkCount, inInclusiveRange(3, 12));
        expect(checklistCount, inInclusiveRange(1, 3));
        expect(itemCount, greaterThanOrEqualTo(checklistCount * 6));
        expect(itemCount, lessThanOrEqualTo(checklistCount * 15));
      }
      expect(seenRich, isTrue);
    });

    test('covers all the categories', () {
      final Set<String> categories =
          fixtures.notes.map((Note n) => n.category).toSet();
      expect(
        categories,
        containsAll(<String>[
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

    test('the dates are all different', () {
      final Set<String> dates =
          fixtures.notes.map((Note n) => n.date).toSet();
      expect(dates, hasLength(fixtures.notes.length));
    });

    test('the notes have a non-empty title, content and id', () {
      for (final Note note in fixtures.notes) {
        expect(note.title, isNotEmpty);
        expect(note.content, isNotEmpty);
        expect(note.id, isNotEmpty);
      }
    });

    test('the generated JSON is readable by the model', () {
      final List<Note> restored = decodeNotes(encodeNotes(fixtures.notes));
      expect(restored, hasLength(fixtures.notes.length));
      expect(restored.first.title, fixtures.notes.first.title);
      expect(restored.first.important, fixtures.notes.first.important);
    });
  });
}
