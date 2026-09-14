import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/cover_image.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/folder_card_bodies.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';

/// Structural safety net for the card bodies, now that every screen uses
/// [EntityCard]: relative positions (metadata at the bottom, cover halves,
/// markers) and the title line limits, rather than golden pixels.
Widget _host(Widget card, {double width = 160.0, double height = 200.0}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: width, height: height, child: card),
      ),
    ),
  );
}

Note _note({String? coverImage, bool isPinned = false, bool important = false}) {
  return Note(
    id: 'n1',
    title: 'Alpha title',
    content: 'Body text',
    date: '2026-01-01 00:00:00.000',
    coverImage: coverImage,
    isPinned: isPinned,
    important: important,
    attachments: const <String>['a.txt'],
  );
}

Widget _noteCard(
  Note note, {
  bool isList = false,
  bool isSelected = false,
  bool isInSelectionMode = false,
}) {
  return EntityCard(
    kind: EntityKind.note,
    category: note.category,
    title: note.title,
    subtitle: formatNoteDate(note.date),
    coverImage: note.coverImage,
    isPinned: note.isPinned,
    isImportant: note.important,
    isSelected: isSelected,
    isInSelectionMode: isInSelectionMode,
    isListLayout: isList,
    builder: (BuildContext context, Color textColor, bool hasCover) => isList
        ? buildNoteListContent(
            note: note,
            textColor: textColor,
            activeNoteIds: const <String>{},
            hasCover: hasCover,
          )
        : buildNoteGridContent(
            note: note,
            textColor: textColor,
            activeNoteIds: const <String>{},
            hasCover: hasCover,
          ),
  );
}

Widget _folderCard(
  Folder folder, {
  required int noteCount,
  bool isList = false,
}) {
  return EntityCard(
    kind: EntityKind.folder,
    category: folder.category,
    title: folder.name,
    subtitle: 'x$noteCount',
    subtitleIcon: Icons.description_outlined,
    isListLayout: isList,
    builder: (BuildContext context, Color textColor, bool hasCover) => isList
        ? buildFolderListContent(
            folder: folder,
            noteCount: noteCount,
            textColor: textColor,
            hasCover: hasCover,
          )
        : buildFolderGridContent(
            folder: folder,
            noteCount: noteCount,
            textColor: textColor,
            hasCover: hasCover,
          ),
  );
}

Folder _folder({String? coverImage}) => Folder(
      id: 'f1',
      name: 'Studies',
      date: '2026-01-01 00:00:00.000',
      coverImage: coverImage,
    );

void main() {
  group('note grid', () {
    testWidgets('glues the metadata to the bottom, left aligned',
        (tester) async {
      await tester.pumpWidget(_host(_noteCard(_note())));

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect meta = tester.getRect(find.byIcon(Symbols.attachment));

      expect(card.bottom - meta.bottom, closeTo(4.0, 1.0));
      expect(meta.left, closeTo(card.left + 8.0, 2.0));
    });

    testWidgets('fills the top half with the cover and stops the title at 2',
        (tester) async {
      await tester.pumpWidget(_host(_noteCard(_note(coverImage: 'cover.png'))));

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect cover = tester.getRect(find.byType(CoverImage));

      expect(cover.top, closeTo(card.top, 1.0));
      expect(cover.height, closeTo(card.height / 2, 1.0));
      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 2);
    });

    testWidgets('lets the title reach three lines without a cover',
        (tester) async {
      await tester.pumpWidget(_host(_noteCard(_note())));

      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 3);
    });
  });

  group('note list', () {
    testWidgets('fills the left third with the cover', (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(coverImage: 'cover.png', isPinned: true), isList: true),
          width: 300.0,
          height: 92.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect cover = tester.getRect(find.byType(CoverImage));
      final Rect pin = tester.getRect(find.byIcon(Symbols.push_pin));

      expect(cover.left, closeTo(card.left, 1.0));
      expect(cover.width, closeTo(card.width / 3, 1.0));
      expect(pin.left, greaterThanOrEqualTo(cover.right));
    });

    testWidgets('stops the title at one line with a cover, two without',
        (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(coverImage: 'cover.png'), isList: true),
          width: 300.0,
          height: 92.0,
        ),
      );
      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 1);

      await tester.pumpWidget(
        _host(_noteCard(_note(), isList: true), width: 300.0, height: 92.0),
      );
      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 2);
    });
  });

  group('selection overlay', () {
    testWidgets('sits in the top-right corner when selected', (tester) async {
      await tester.pumpWidget(
        _host(_noteCard(_note(), isSelected: true, isInSelectionMode: true)),
      );

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Offset mark = tester.getCenter(find.byIcon(Icons.check_circle));

      expect(mark.dx, greaterThan(card.center.dx));
      expect(mark.dy, lessThan(card.center.dy));
    });
  });

  group('folder', () {
    testWidgets('grid puts the name on top and the metadata at the bottom',
        (tester) async {
      await tester.pumpWidget(_host(_folderCard(_folder(), noteCount: 3)));

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect name = tester.getRect(find.text('Studies'));
      final Rect meta = tester.getRect(find.byIcon(Symbols.description));

      expect(name.top, lessThan(meta.top));
      expect(card.bottom - meta.bottom, closeTo(4.0, 1.0));
      // No folder glyph any more: the watermark replaces it.
      expect(find.byIcon(Icons.folder_open), findsNothing);
    });

    testWidgets('list centres the name and its metadata', (tester) async {
      await tester.pumpWidget(
        _host(
          _folderCard(_folder(), noteCount: 3, isList: true),
          width: 300.0,
          height: 92.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect name = tester.getRect(find.text('Studies'));
      final Rect meta = tester.getRect(find.byIcon(Symbols.description));

      expect(meta.top, greaterThanOrEqualTo(name.bottom - 1.0));
      // Centred block: it does not touch either edge.
      expect(name.top, greaterThan(card.top + 8.0));
      expect(meta.bottom, lessThan(card.bottom - 8.0));
    });
  });

  group('pin and bookmark', () {
    testWidgets('a pinned note shows the pin first in the metadata',
        (tester) async {
      await tester.pumpWidget(_host(_noteCard(_note(isPinned: true))));

      final Rect pin = tester.getRect(find.byIcon(Symbols.push_pin));
      final Rect counts = tester.getRect(find.byIcon(Symbols.attachment));

      expect(pin.center.dy, closeTo(counts.center.dy, 1.0));
      expect(pin.left, lessThan(counts.left));
    });

    testWidgets('a pinned folder shows the pin first in the metadata',
        (tester) async {
      final Folder folder = Folder(
        id: 'f1',
        name: 'Studies',
        date: '2026-01-01 00:00:00.000',
        isPinned: true,
      );
      await tester.pumpWidget(_host(_folderCard(folder, noteCount: 3)));

      final Rect pin = tester.getRect(find.byIcon(Symbols.push_pin));
      final Rect count = tester.getRect(find.byIcon(Symbols.description));

      expect(pin.center.dy, closeTo(count.center.dy, 1.0));
      expect(pin.left, lessThan(count.left));
    });

    testWidgets('a bookmarked note puts the bookmark at the top right',
        (tester) async {
      await tester.pumpWidget(_host(_noteCard(_note(important: true))));

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect bookmark = tester.getRect(find.byIcon(Icons.bookmark));

      // Flush with the top: the glyph bearing is compensated, so the icon box
      // may sit a couple of pixels above the card edge.
      expect(bookmark.top, lessThanOrEqualTo(card.top + 0.5));
      expect(bookmark.top, greaterThanOrEqualTo(card.top - 3.0));
      expect(card.right - bookmark.right, closeTo(2.0, 1.0));
    });

    testWidgets('a covered grid anchors the bookmark under the cover',
        (tester) async {
      await tester.pumpWidget(
        _host(_noteCard(_note(coverImage: 'cover.png', important: true))),
      );

      final Rect cover = tester.getRect(find.byType(CoverImage));
      final Rect bookmark = tester.getRect(find.byIcon(Icons.bookmark));

      expect(bookmark.top, lessThanOrEqualTo(cover.bottom + 0.5));
      expect(bookmark.top, greaterThanOrEqualTo(cover.bottom - 3.0));
    });
  });
}
