@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/folder_card_bodies.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';

import 'golden_setup.dart';

/// The two real card boxes: the grid tile and the compact list row.
const Size _grid = Size(176.0, 196.0);
const Size _list = Size(340.0, 100.0);

Note _note() => Note(
  id: 'n1',
  title: 'Idées en vrac pour la semaine',
  content: 'Acheter du pain\nAppeler le plombier\nRanger le garage',
  date: '2026-02-01 09:00:00.000',
  category: 'nuage',
);

Note _task() => Note(
  kind: EntityKind.task,
  id: 't1',
  title: 'Préparer la release',
  content: '- [x] Tests\n- [ ] Notes de version\n- [ ] Tag',
  date: '2026-02-03 08:00:00.000',
  category: 'azur',
);

Note _project() => Note(
  id: 'p1',
  title: 'Refonte du site',
  content: 'Cadrage en cours, trois pages à reprendre.',
  date: '2026-02-05 08:00:00.000',
  category: 'lavande',
);

Folder _folder() => Folder(
  id: 'f1',
  name: 'Projets en cours',
  date: '2026-02-01 09:00:00.000',
  category: 'peche',
);

EntityCard _card(
  EntityKind kind, {
  required bool isList,
  bool isImportant = false,
  bool isLocked = false,
  bool isSelected = false,
  bool isInSelectionMode = false,
}) {
  Note note() => switch (kind) {
    EntityKind.task => _task(),
    EntityKind.project => _project(),
    _ => _note(),
  };

  Widget body(BuildContext context, Color textColor, bool hasCover) {
    if (kind == EntityKind.folder) {
      return isList
          ? buildFolderListContent(
              folder: _folder(),
              noteCount: 3,
              textColor: textColor,
              hasCover: hasCover,
            )
          : buildFolderGridContent(
              folder: _folder(),
              noteCount: 3,
              textColor: textColor,
              hasCover: hasCover,
            );
    }
    return isList
        ? buildNoteListContent(
            note: note().copyWith(important: isImportant),
            textColor: textColor,
            activeNoteIds: const <String>{},
            hasCover: hasCover,
          )
        : buildNoteGridContent(
            note: note().copyWith(important: isImportant),
            textColor: textColor,
            activeNoteIds: const <String>{},
            hasCover: hasCover,
          );
  }

  return EntityCard(
    kind: kind,
    category: kind == EntityKind.folder ? 'peche' : note().category,
    title: kind == EntityKind.folder ? _folder().name : note().title,
    // The locked template draws the second line itself.
    subtitle: kind == EntityKind.folder ? 'x3' : formatNoteDate(note().date),
    subtitleIcon: kind == EntityKind.folder ? Icons.notes : null,
    isImportant: isImportant,
    isLocked: isLocked,
    isSelected: isSelected,
    isInSelectionMode: isInSelectionMode,
    isListLayout: isList,
    builder: body,
  );
}

/// One card per state, so a single image shows what a polish can break.
List<EntityCard> _states({required bool isList}) => <EntityCard>[
  _card(EntityKind.note, isList: isList),
  _card(EntityKind.note, isList: isList, isImportant: true),
  _card(EntityKind.note, isList: isList, isLocked: true),
  _card(EntityKind.note, isList: isList, isInSelectionMode: true),
  _card(
    EntityKind.note,
    isList: isList,
    isInSelectionMode: true,
    isSelected: true,
  ),
];

Widget _sheet({required bool isList}) {
  final List<EntityCard> cards = _states(isList: isList);
  return isList
      ? Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final EntityCard card in cards)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: SizedBox.fromSize(size: _list, child: card),
              ),
          ],
        )
      : Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (final EntityCard card in cards)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: SizedBox.fromSize(size: _grid, child: card),
              ),
          ],
        );
}

void main() {
  setUpAll(loadGoldenFonts);

  for (final Brightness brightness in Brightness.values) {
    final String theme = brightness.name;

    for (final EntityKind kind in EntityKind.values) {
      testWidgets('grid · ${kind.name} · $theme', (WidgetTester tester) async {
        await pumpGolden(
          tester,
          brightness: brightness,
          child: SizedBox.fromSize(
            size: _grid,
            child: _card(kind, isList: false),
          ),
        );
        await expectLater(
          find.byKey(goldenKey),
          matchesGoldenFile('goldens/grid_${kind.name}_$theme.png'),
        );
      });

      testWidgets('list · ${kind.name} · $theme', (WidgetTester tester) async {
        await pumpGolden(
          tester,
          brightness: brightness,
          child: SizedBox.fromSize(
            size: _list,
            child: _card(kind, isList: true),
          ),
        );
        await expectLater(
          find.byKey(goldenKey),
          matchesGoldenFile('goldens/list_${kind.name}_$theme.png'),
        );
      });
    }

    testWidgets('states · grid · $theme', (WidgetTester tester) async {
      await pumpGolden(
        tester,
        brightness: brightness,
        child: _sheet(isList: false),
      );
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/states_grid_$theme.png'),
      );
    });

    testWidgets('states · list · $theme', (WidgetTester tester) async {
      await pumpGolden(
        tester,
        brightness: brightness,
        child: _sheet(isList: true),
      );
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/states_list_$theme.png'),
      );
    });
  }
}
