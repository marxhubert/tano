import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/widgets/cover_image.dart';
import 'package:tano/shared/widgets/folder_card.dart';
import 'package:tano/shared/widgets/note_card.dart';
import 'package:tano/shared/widgets/note_card_content.dart';

/// Structural safety net for the shared cards.
///
/// These tests freeze the *layout contracts* of [NoteCard] and [FolderCard]
/// before they are merged into a single `EntityCard` (refactoring lot 2):
/// relative positions (counts glued to the bottom, markers after the cover,
/// metadata under the name) rather than golden pixels, so they stay stable
/// across platforms and font rendering.
Widget _host(Widget card, {double? width, double? height}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: height, child: card),
      ),
    ),
  );
}

Widget _noteCard(
  Note note, {
  bool isList = false,
  bool isSelected = false,
  bool isInSelectionMode = false,
}) {
  return NoteCard(
    note: note,
    isListLayout: isList,
    coverImage: note.coverImage,
    isSelected: isSelected,
    isInSelectionMode: isInSelectionMode,
    builder: (BuildContext context, Color textColor) => isList
        ? buildNoteListContent(
            note: note,
            textColor: textColor,
            activeNoteIds: const <String>{},
          )
        : buildNoteGridContent(
            note: note,
            textColor: textColor,
            activeNoteIds: const <String>{},
          ),
  );
}

Widget _folderCard(
  Folder folder, {
  required int noteCount,
  bool isList = false,
  bool isSelected = false,
  bool isInSelectionMode = false,
}) {
  return FolderCard(
    folder: folder,
    noteCount: noteCount,
    isListLayout: isList,
    coverImage: folder.coverImage,
    isSelected: isSelected,
    isInSelectionMode: isInSelectionMode,
  );
}

Note _note({
  String title = 'Alpha title',
  String? coverImage,
  bool isPinned = false,
  bool important = false,
  bool isLocked = false,
  List<String> attachments = const <String>[],
}) {
  return Note(
    id: 'n1',
    title: title,
    content: 'Body text',
    date: '2026-01-01 00:00:00.000',
    coverImage: coverImage,
    isPinned: isPinned,
    important: important,
    isLocked: isLocked,
    attachments: attachments,
  );
}

Folder _folder({
  String name = 'Studies',
  String? coverImage,
  bool isPinned = false,
  bool important = false,
  bool isLocked = false,
}) {
  return Folder(
    id: 'f1',
    name: name,
    date: '2026-01-01 00:00:00.000',
    coverImage: coverImage,
    isPinned: isPinned,
    important: important,
    isLocked: isLocked,
  );
}

void main() {
  group('NoteCard grid', () {
    testWidgets('glues the counts to the bottom of the card', (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(attachments: <String>['a.txt'])),
          width: 160.0,
          height: 160.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(NoteCard));
      final Rect counts = tester.getRect(find.byIcon(Icons.attachment));

      expect(counts.bottom, lessThanOrEqualTo(card.bottom));
      expect(card.bottom - counts.bottom, lessThanOrEqualTo(8.0));
    });

    testWidgets('fills the top half with the cover and pushes the title down',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(coverImage: 'cover.png')),
          width: 160.0,
          height: 160.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(NoteCard));
      final Rect cover = tester.getRect(find.byType(CoverImage));

      // The card border insets the cover by half a pixel per side.
      expect(cover.top, closeTo(card.top, 1.0));
      expect(cover.left, closeTo(card.left, 1.0));
      expect(cover.width, closeTo(card.width, 1.0));
      expect(cover.height, closeTo(card.height / 2, 1.0));

      final double titleTop = tester.getTopLeft(find.text('Alpha title')).dy;
      expect(titleTop, greaterThanOrEqualTo(cover.bottom));
    });

    testWidgets('keeps the markers after the cover, never on top of it',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(
            _note(coverImage: 'cover.png', isPinned: true, important: true),
          ),
          width: 160.0,
          height: 160.0,
        ),
      );

      final Rect cover = tester.getRect(find.byType(CoverImage));
      final Rect pin = tester.getRect(find.byIcon(Icons.push_pin));
      final Rect bookmark = tester.getRect(find.byIcon(Icons.bookmark));

      expect(pin.top, greaterThanOrEqualTo(cover.bottom));
      expect((bookmark.center.dy - cover.bottom).abs(), lessThanOrEqualTo(8.0));
    });

    testWidgets('limits the title to three lines without a cover',
        (tester) async {
      await tester.pumpWidget(
        _host(_noteCard(_note()), width: 160.0, height: 160.0),
      );

      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 3);
    });

    testWidgets('limits the title to two lines with a cover', (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(coverImage: 'cover.png')),
          width: 160.0,
          height: 160.0,
        ),
      );

      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 2);
    });
  });

  group('NoteCard list', () {
    testWidgets('fills the left third with the cover', (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(
            _note(coverImage: 'cover.png', isPinned: true),
            isList: true,
          ),
          width: 300.0,
          height: 120.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(NoteCard));
      final Rect cover = tester.getRect(find.byType(CoverImage));
      final Rect pin = tester.getRect(find.byIcon(Icons.push_pin));

      expect(cover.left, closeTo(card.left, 1.0));
      expect(cover.top, closeTo(card.top, 1.0));
      expect(cover.width, closeTo(card.width / 3, 1.0));
      expect(pin.left, greaterThanOrEqualTo(cover.right));
    });

    testWidgets('limits the title to two lines', (tester) async {
      await tester.pumpWidget(
        _host(_noteCard(_note(), isList: true), width: 300.0, height: 120.0),
      );

      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 2);
    });
  });

  group('NoteCard locked template', () {
    testWidgets('hides the cover and shows the lock, title and date',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(coverImage: 'cover.png', isLocked: true)),
          width: 160.0,
          height: 160.0,
        ),
      );

      expect(find.byType(CoverImage), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      // The locked overlay is stacked on top of the regular content, so the
      // title is present twice: once underneath, once in the template.
      expect(find.text('Alpha title'), findsWidgets);
    });

    testWidgets('is identical in the list layout: lock, title and date',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(coverImage: 'cover.png', isLocked: true), isList: true),
          width: 300.0,
          height: 100.0,
        ),
      );

      expect(find.byType(CoverImage), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Alpha title'), findsWidgets);
    });
  });

  group('NoteCard selection overlay', () {
    testWidgets('sits in the top-right corner when selected', (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(), isSelected: true, isInSelectionMode: true),
          width: 160.0,
          height: 160.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(NoteCard));
      final Offset mark = tester.getCenter(find.byIcon(Icons.check_circle));

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(mark.dx, greaterThan(card.center.dx));
      expect(mark.dy, lessThan(card.center.dy));
    });

    testWidgets('shows an empty circle when not selected', (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(), isInSelectionMode: true),
          width: 160.0,
          height: 160.0,
        ),
      );

      expect(find.byIcon(Icons.panorama_fish_eye), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });

  group('FolderCard grid', () {
    testWidgets('puts the icon on top and the metadata under the name',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _folderCard(_folder(), noteCount: 3),
          width: 160.0,
          height: 160.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(FolderCard));
      final Rect icon = tester.getRect(find.byIcon(Icons.folder_open));
      final Rect name = tester.getRect(find.text('Studies'));
      final Rect meta = tester.getRect(find.byIcon(Icons.description_outlined));

      expect(icon.top, lessThan(name.top));
      expect(name.bottom, lessThanOrEqualTo(meta.top + 1.0));
      expect(card.bottom - meta.bottom, lessThanOrEqualTo(8.0));
    });

    testWidgets('keeps the metadata without overflowing when covered',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _folderCard(_folder(coverImage: 'folder.png'), noteCount: 3),
          // The real cell of the three-column grid on a regular phone.
          width: 112.0,
          height: 125.0,
        ),
      );

      expect(tester.takeException(), isNull);

      final Rect card = tester.getRect(find.byType(FolderCard));
      final Rect meta = tester.getRect(find.byIcon(Icons.description_outlined));
      expect(meta.bottom, lessThanOrEqualTo(card.bottom));
      // The folder glyph is dropped to leave the lower half to the metadata.
      expect(find.byIcon(Icons.folder_open), findsNothing);
    });
  });

  group('FolderCard list', () {
    testWidgets('keeps a minimum height and the icon left of the name',
        (tester) async {
      await tester.pumpWidget(
        _host(_folderCard(_folder(), noteCount: 0, isList: true), width: 300.0),
      );

      final Rect card = tester.getRect(find.byType(FolderCard));
      final Rect icon = tester.getRect(find.byIcon(Icons.folder_open));
      final Rect name = tester.getRect(find.text('Studies'));

      expect(card.height, greaterThanOrEqualTo(69.0));
      expect(icon.right, lessThanOrEqualTo(name.left));
    });

    testWidgets('grows with a cover and shifts the content past it',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _folderCard(
            _folder(coverImage: 'folder.png'),
            noteCount: 0,
            isList: true,
          ),
          width: 300.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(FolderCard));
      final Rect cover = tester.getRect(find.byType(CoverImage));

      expect(card.height, greaterThanOrEqualTo(85.0));
      expect(cover.left, closeTo(card.left, 1.0));
      expect(cover.width, closeTo(card.width / 3, 1.0));
      expect(
        tester.getTopLeft(find.text('Studies')).dx,
        greaterThanOrEqualTo(cover.right),
      );
    });
  });

  group('FolderCard locked template', () {
    testWidgets('hides the cover and the selection circle, shows the lock',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _folderCard(
            _folder(coverImage: 'folder.png', isLocked: true),
            noteCount: 0,
            isInSelectionMode: true,
          ),
          width: 160.0,
          height: 160.0,
        ),
      );

      expect(find.byType(CoverImage), findsNothing);
      expect(find.byIcon(Icons.key), findsOneWidget);
      expect(find.byIcon(Icons.panorama_fish_eye), findsNothing);
      expect(find.byIcon(Icons.check_circle), findsNothing);
    });
  });
}
