@Tags(<String>['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/main.dart';
import 'golden_setup.dart';

class _PreviewRepository extends Fake implements NotesRepository {
  final notes = <Note>[
    Note(
      id: 'a',
      title: 'A quiet morning',
      content: 'A place for the things worth keeping.',
      date: '2026-09-21 08:30:00.000',
      category: 'nuage',
      important: true,
    ),
    Note(
      id: 'b',
      title: 'Things to explore',
      content: 'A new trail. A small garden.',
      date: '2026-09-20 10:00:00.000',
      category: 'sable',
    ),
    Note(
      id: 'c',
      title: 'Reading notes',
      content: 'Attention is the beginning of discovery.',
      date: '2026-09-19 10:00:00.000',
      category: 'lavande',
    ),
    Note(
      id: 'd',
      title: 'Weekend list',
      content: 'Bread, flowers, a long walk.',
      date: '2026-09-18 10:00:00.000',
      category: 'menthe',
    ),
    Note(
      id: 'e',
      title: 'Small discoveries',
      content: 'The best ideas arrive when we slow down.',
      date: '2026-09-17 10:00:00.000',
      category: 'peche',
    ),
    Note(
      id: 'f',
      title: 'Letters',
      content: 'A letter to an old friend.',
      date: '2026-09-16 10:00:00.000',
      category: 'rose',
    ),
  ];
  @override
  Future<List<Note>> loadNotes() async => notes;
  @override
  Future<void> upsertNote(Note note) async {}
}

/// The tablet side of the responsive policy: three columns in portrait, five in
/// landscape, with the centred content column and the paper FAB.
void main() {
  setUpAll(loadGoldenFonts);
  for (final mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    for (final entry in <(String, Size)>[
      ('tablet_portrait', Size(768, 1024)),
      ('tablet_landscape', Size(1024, 768)),
    ]) {
      testWidgets('paper ${entry.$1} ${mode.name}', (
        WidgetTester tester,
      ) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        PackageInfo.setMockInitialValues(
          appName: 'TanoNote',
          packageName: 'test.tano',
          version: '1.0',
          buildNumber: '1',
          buildSignature: '',
        );
        await getIt.reset();
        getIt.registerSingleton<NotesRepository>(_PreviewRepository());
        tester.view.physicalSize = entry.$2;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          RepaintBoundary(
            key: goldenKey,
            child: Tano(themeMode: mode),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(goldenKey),
          matchesGoldenFile('goldens/paper_${entry.$1}_${mode.name}.png'),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
