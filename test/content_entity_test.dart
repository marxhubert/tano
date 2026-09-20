import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/task.dart';
import 'package:tano/core/models/project.dart';
import 'package:tano/core/models/content_entity.dart';
import 'package:tano/shared/config/card_sorting.dart';

void main() {
  test(
    'nullable fields distinguish preserving and explicitly clearing values',
    () {
      final note = Note(
        id: 'n',
        folderId: 'f',
        coverImage: 'cover',
        deletedAt: 'date',
      );
      expect(note.copyWith(title: 'changed').coverImage, 'cover');
      expect(note.copyWith(coverImage: null).coverImage, isNull);
      expect(note.copyWith(folderId: null).folderId, isNull);
      expect(note.copyWith(deletedAt: null).deletedAt, isNull);
      expect(Folder(coverImage: 'cover').withoutCover().coverImage, isNull);
      expect(
        Project(deletedAt: 'date').copyWith(deletedAt: null).deletedAt,
        isNull,
      );
      expect(Task(folderId: 'f').copyWith(folderId: null).folderId, isNull);
    },
  );
  test('all entity types use the same bookmark and title sorting', () {
    final entries = <ContentEntity>[
      Note(title: 'Zulu'),
      Folder(name: 'Alpha'),
      Task(title: 'Beta', important: true),
      Project(name: 'Gamma'),
    ];
    expect(
      const EntitySorting<ContentEntity>(
        by: 'alpha',
      ).sort(entries).map((e) => e.label),
      ['Beta', 'Alpha', 'Gamma', 'Zulu'],
    );
  });
}
