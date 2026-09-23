import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/config/service_locator.dart';
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

Note _note({String? coverImage, bool important = false}) {
  return Note(
    id: 'n1',
    title: 'Alpha title',
    content: 'Body text',
    date: '2026-01-01 00:00:00.000',
    coverImage: coverImage,
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
    subtitleIcon: Symbols.description,
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
  for (final list in [false, true]) {
    for (final cover in [false, true]) {
      testWidgets(
        'task card counts description links and respects cover: $list/$cover',
        (tester) async {
          final note = Note(
            id: 'task',
            kind: EntityKind.task,
            title: 'Task title',
            description: '[[n:Note]]',
            content: List.generate(4, (i) => '- [ ] [[n:Note]]').join('\n'),
          );
          final builder = list ? buildNoteListContent : buildNoteGridContent;
          await tester.pumpWidget(
            _host(
              builder(
                note: note,
                textColor: Colors.black,
                activeNoteIds: {'n'},
                hasCover: cover,
              ),
              width: 300,
            ),
          );
          expect(find.text('x5'), findsOneWidget);
          final checkbox = find.byIcon(Symbols.check_box_outline_blank);
          expect(checkbox, cover ? findsNothing : findsNWidgets(4));
          if (!cover) {
            expect(
              tester.getTopLeft(checkbox.first).dx,
              closeTo(tester.getTopLeft(find.text('Task title')).dx, 0.1),
            );
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  setUp(() {
    if (!getIt.isRegistered<AttachmentsStore>()) {
      getIt.registerLazySingleton<AttachmentsStore>(() => AttachmentsStore());
    }
  });

  group('note grid', () {
    testWidgets('glues the metadata to the bottom, left aligned', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_noteCard(_note())));

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect meta = tester.getRect(find.byIcon(Symbols.attachment));

      expect(card.bottom - meta.bottom, closeTo(8.0, 1.0));
      expect(meta.left, closeTo(card.left + 12.0, 2.0));
    });

    testWidgets('fills the top half with the cover and stops the title at 2', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_noteCard(_note(coverImage: 'cover.png'))));

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect cover = tester.getRect(find.byType(CoverImage));

      expect(cover.top, closeTo(card.top, 1.0));
      expect(cover.height, closeTo(card.height / 2, 1.0));
      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 2);
    });

    testWidgets('covered cards fit a small two-column phone grid', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _noteCard(
            Note(
              id: 'small',
              title: 'A long title that should fit without overflowing',
              content: 'Body',
              date: '2026-01-01 00:00:00.000',
              coverImage: 'cover.png',
              attachments: const <String>['a.txt'],
            ),
          ),
          width: 136.0,
          height: 151.0,
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('lets the title reach three lines without a cover', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_noteCard(_note())));

      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 3);
    });
  });

  group('note list', () {
    testWidgets('fills the left third with the cover', (tester) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(coverImage: 'cover.png'), isList: true),
          width: 300.0,
          height: 112.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect cover = tester.getRect(find.byType(CoverImage));

      expect(cover.left, closeTo(card.left, 1.0));
      expect(cover.width, closeTo(card.width / 3, 1.0));
    });

    testWidgets('stops the title at one line with a cover, two without', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(coverImage: 'cover.png'), isList: true),
          width: 300.0,
          height: 112.0,
        ),
      );
      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 1);

      await tester.pumpWidget(
        _host(_noteCard(_note(), isList: true), width: 300.0, height: 112.0),
      );
      expect(tester.widget<Text>(find.text('Alpha title')).maxLines, 2);
    });
  });

  group('selection overlay', () {
    testWidgets('selection control does not cover the list date', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _noteCard(_note(), isList: true, isInSelectionMode: true),
          width: 340.0,
          height: 100.0,
        ),
      );
      final Rect date = tester.getRect(find.text(formatNoteDate(_note().date)));
      final Rect selection = tester.getRect(find.byIcon(Symbols.circle));
      expect(date.right, lessThanOrEqualTo(selection.left));
      expect(tester.takeException(), isNull);
    });

    testWidgets('sits in the top-right corner when selected', (tester) async {
      await tester.pumpWidget(
        _host(_noteCard(_note(), isSelected: true, isInSelectionMode: true)),
      );

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Offset mark = tester.getCenter(find.byIcon(Symbols.check_circle));

      expect(mark.dx, greaterThan(card.center.dx));
      expect(mark.dy, lessThan(card.center.dy));
    });
  });

  group('folder', () {
    testWidgets('grid puts the name on top and the metadata at the bottom', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_folderCard(_folder(), noteCount: 3)));

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect name = tester.getRect(find.text('Studies'));
      final Rect meta = tester.getRect(find.byIcon(Symbols.sticky_note_2));

      expect(name.top, lessThan(meta.top));
      expect(card.bottom - meta.bottom, closeTo(8.0, 1.0));
      // The folder keeps the corner watermark; the other kinds dropped theirs.
      expect(find.byIcon(Symbols.folder_open), findsOneWidget);
    });

    testWidgets('list centres the name and its metadata', (tester) async {
      await tester.pumpWidget(
        _host(
          _folderCard(_folder(), noteCount: 3, isList: true),
          width: 300.0,
          height: 112.0,
        ),
      );

      final Rect card = tester.getRect(find.byType(EntityCard));
      final Rect name = tester.getRect(find.text('Studies'));
      final Rect meta = tester.getRect(find.byIcon(Symbols.sticky_note_2));

      expect(meta.top, greaterThanOrEqualTo(name.bottom - 1.0));
      // Centred block: it does not touch either edge.
      expect(name.top, greaterThan(card.top + 8.0));
      expect(meta.bottom, lessThan(card.bottom - 8.0));
    });
  });

  group('bookmark', () {
    testWidgets('a bookmarked note shows the marker first in the metadata', (
      tester,
    ) async {
      await tester.pumpWidget(_host(_noteCard(_note(important: true))));

      final Rect mark = tester.getRect(find.byIcon(Symbols.bookmark));
      final Rect counts = tester.getRect(find.byIcon(Symbols.attachment));

      expect(mark.center.dy, closeTo(counts.center.dy, 1.0));
      expect(mark.left, lessThan(counts.left));
    });
  });
}
