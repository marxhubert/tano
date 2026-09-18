import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note_access_policy.dart';

void main() {
  final policy = NoteAccessPolicy([
    Folder(id: 'open'),
    Folder(id: 'locked', isLocked: true),
    Folder(id: 'trash', isDeleted: true),
  ]);
  test('locked folders protect even notes without their own lock', () {
    final note = Note(folderId: 'locked');
    expect(policy.isReachable(note), isTrue);
    expect(policy.requiresAuthentication(note), isTrue);
    expect(policy.isSearchable(note), isFalse);
  });
  test(
    'trash and missing parents cannot be reached through search or links',
    () {
      for (final id in ['trash', 'missing']) {
        expect(policy.isReachable(Note(folderId: id)), isFalse);
        expect(policy.isSearchable(Note(folderId: id)), isFalse);
      }
      expect(policy.isSearchable(Note(folderId: 'open')), isTrue);
      expect(policy.isSearchable(Note()), isTrue);
    },
  );
  test(
    'folder search stays scoped and never includes individually locked notes',
    () {
      expect(
        policy.isSearchableInFolder(Note(folderId: 'open'), 'open'),
        isTrue,
      );
      expect(
        policy.isSearchableInFolder(Note(folderId: 'locked'), 'open'),
        isFalse,
      );
      expect(policy.isSearchableInFolder(Note(), 'open'), isFalse);
      expect(
        policy.isSearchableInFolder(Note(folderId: 'locked'), 'locked'),
        isTrue,
      );
      expect(
        policy.isSearchableInFolder(
          Note(folderId: 'locked', isLocked: true),
          'locked',
        ),
        isFalse,
      );
    },
  );
}
