import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/folder.dart';

void main() {
  group('Folder', () {
    test('createdAt and updatedAt default to the date', () {
      final folder = Folder(id: '1', date: '2026-08-12 10:00:00.000');
      expect(folder.createdAt, '2026-08-12 10:00:00.000');
      expect(folder.updatedAt, '2026-08-12 10:00:00.000');
    });

    test('serializes and deserializes createdAt and updatedAt', () {
      final folder = Folder(
        id: '1',
        name: 'Studies',
        date: '2026-08-12 10:00:00.000',
        createdAt: '2026-08-01 09:00:00.000',
        updatedAt: '2026-08-13 11:00:00.000',
        coverImage: 'cover.png',
      );

      final restored = Folder.fromJson(folder.toJson());

      expect(restored.createdAt, '2026-08-01 09:00:00.000');
      expect(restored.updatedAt, '2026-08-13 11:00:00.000');
      expect(restored.coverImage, 'cover.png');
    });

    test('rows without createdAt/updatedAt fall back to the date', () {
      final restored = Folder.fromJson(<String, dynamic>{
        'id': '1',
        'date': '2026-08-12 10:00:00.000',
      });

      expect(restored.createdAt, '2026-08-12 10:00:00.000');
      expect(restored.updatedAt, '2026-08-12 10:00:00.000');
    });
  });
}
