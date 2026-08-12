import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/main.dart';
import 'package:tano/core/models/note.dart';

/// In-memory [NotesRepository] so the widget test never touches the disk.
class _InMemoryNotesRepository implements NotesRepository {
  _InMemoryNotesRepository([List<Note>? notes]) : notes = notes ?? <Note>[];

  final List<Note> notes;

  @override
  Future<List<Note>> loadNotes() async => List<Note>.of(notes);

  @override
  Future<void> saveNotes(List<Note> notes) async {
    this.notes
      ..clear()
      ..addAll(notes);
  }
}

List<Note> _demoNotes() => List<Note>.generate(
  12,
  (int i) => Note(
    id: 'note-$i',
    title: 'Note numéro $i avec un titre assez long pour tester',
    content:
        'Contenu de la note $i. Lorem ipsum dolor sit amet, consectetur '
        'adipiscing elit, sed do eiusmod tempor incididunt ut labore.',
    date:
        '2026-08-${(i % 28 + 1).toString().padLeft(2, '0')} '
        '10:00:00.000',
    important: i.isEven,
    category: <String>[
      'note',
      'work',
      'personal',
      'travel',
      'life',
      'project',
    ][i % 6],
  ),
);

Future<void> _pumpApp(
  WidgetTester tester, {
  Size size = const Size(320, 480),
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final _InMemoryNotesRepository repository = _InMemoryNotesRepository(
    _demoNotes(),
  );
  await tester.pumpWidget(Tano(repository: repository, themeMode: themeMode));
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Future<void> _selectLayout(WidgetTester tester, String label) async {
  await tester.tap(find.byIcon(Icons.more_vert).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.shikamarx.tano',
      version: '0.8.4',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  for (final ThemeMode themeMode in <ThemeMode>[
    ThemeMode.light,
    ThemeMode.dark,
  ]) {
    for (final Size size in <Size>[
      const Size(320, 480),
      const Size(240, 320),
    ]) {
      testWidgets('accueil : layouts, menu et sélection sans débordement '
          '(${themeMode.name}, ${size.width.toInt()}x${size.height.toInt()})', (
        tester,
      ) async {
        await _pumpApp(tester, size: size, themeMode: themeMode);

        // Le thème demandé est bien appliqué (barre du bas sombre en mode
        // sombre, claire en mode clair).
        final bool isDark = themeMode == ThemeMode.dark;
        expect(
          Theme.of(tester.element(find.byType(BottomAppBar))).brightness,
          isDark ? Brightness.dark : Brightness.light,
        );
        final BottomAppBar bar = tester.widget(find.byType(BottomAppBar));
        expect(
          bar.color,
          isDark ? Colors.blueGrey.shade900 : Colors.blueGrey.shade50,
        );

        // Les trois layouts.
        for (final String label in <String>['List', 'Grid', 'Compact']) {
          await _selectLayout(tester, label);
          expect(tester.takeException(), isNull, reason: 'layout $label');
        }

        // Menu principal déplié puis refermé.
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        expect(find.text('Display'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();

        // Mode sélection : long-press puis suppression -> dialogue confirm.
        await tester.longPress(find.textContaining('Note numéro').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.clear).first);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Annule le dialogue.
        await tester.tap(find.text('CANCEL').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('page edit : catégories, retour sale et dialogue confirm '
          '(${themeMode.name}, ${size.width.toInt()}x${size.height.toInt()})', (
        tester,
      ) async {
        await _pumpApp(tester, size: size, themeMode: themeMode);

        // Ouvre une note existante.
        await tester.tap(find.textContaining('Note numéro').first);
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNWidgets(2));
        expect(tester.takeException(), isNull);

        // Menu de catégorie.
        await tester.tap(find.byIcon(Icons.arrow_drop_down));
        await tester.pumpAndSettle();
        expect(find.text('Note'), findsWidgets);
        await tester.tap(find.text('Work').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Saisie (rend la note "sale") puis retour -> dialogue confirm.
        await tester.enterText(
          find.byType(TextField).last,
          'Du contenu fraîchement tapé',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back).first);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Quitte sans sauvegarder.
        await tester.tap(find.text('LEAVE').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
