import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/task.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/main.dart';
import 'golden_setup.dart';

class _PreviewRepository extends Fake implements NotesRepository {
  final notes = <Note>[
    Note(
      id: 'journal',
      title: 'A quiet morning',
      content:
          'A place for the things worth keeping.\n\nWalk before the city wakes. Write a few lines. Make room for a new idea.\n\n## Small discoveries\nThe best ideas arrive when we slow down.',
      date: '2026-09-21 08:30:00.000',
      category: 'nuage',
      important: true,
    ),
    Task(
      id: 'week',
      title: 'This week',
      description: 'Make time for what matters.',
      content:
          '- [ ] Write the proposal\n- [ ] Prepare the design\n- [ ] Read a chapter\n- [x] Plan the week\n- [x] Review the budget',
      date: '2026-09-21 09:00:00.000',
      category: 'menthe',
    ),
    Note(
      id: 'ideas',
      title: 'Things to explore',
      content: 'A new trail. A small garden. A letter to an old friend.',
      date: '2026-09-20 10:00:00.000',
      category: 'sable',
    ),
    Note(
      id: 'reading',
      title: 'Reading notes',
      content: 'Attention is the beginning of discovery.',
      date: '2026-09-19 10:00:00.000',
      category: 'lavande',
    ),
  ];
  @override
  Future<List<Note>> loadNotes() async => notes;
  @override
  Future<void> upsertNote(Note note) async {}
}

void main() {
  setUpAll(loadGoldenFonts);
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('paper app ${mode.name}', (tester) async {
      SharedPreferences.setMockInitialValues({});
      PackageInfo.setMockInitialValues(
        appName: 'TanoNote',
        packageName: 'test.tano',
        version: '1.0',
        buildNumber: '1',
        buildSignature: '',
      );
      await getIt.reset();
      getIt.registerSingleton<NotesRepository>(_PreviewRepository());
      tester.view.physicalSize = const Size(390, 844);
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
        matchesGoldenFile('goldens/paper_home_${mode.name}.png'),
      );
      await tester.tap(find.text('A quiet morning'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/paper_note_${mode.name}.png'),
      );
      await tester.tap(find.byIcon(Symbols.arrow_back_ios).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('This week'));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/paper_task_${mode.name}.png'),
      );
      await tester.tap(find.byIcon(Symbols.add_circle));
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(goldenKey),
        matchesGoldenFile('goldens/paper_menu_${mode.name}.png'),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
