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
    title: 'Note number $i with a title long enough to test',
    content:
        'Content of note $i. Lorem ipsum dolor sit amet, consectetur '
        'adipiscing elit, sed do eiusmod tempor incididunt ut labore.',
    date:
        '2026-08-${(i % 28 + 1).toString().padLeft(2, '0')} '
        '10:00:00.000',
    important: i.isEven,
    category: <String>[
      'menthe',
      'citron',
      'peche',
      'lavande',
      'rose',
      'azur',
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
      testWidgets('home: layouts, menu and selection without overflow '
          '(${themeMode.name}, ${size.width.toInt()}x${size.height.toInt()})', (
        tester,
      ) async {
        await _pumpApp(tester, size: size, themeMode: themeMode);

        // The requested theme is correctly applied.
        final bool isDark = themeMode == ThemeMode.dark;
        expect(
          Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
          isDark ? Brightness.dark : Brightness.light,
        );

        // The add action is a floating button when not in selection mode.
        expect(find.byIcon(Icons.add), findsOneWidget);

        // The three layouts.
        for (final String label in <String>['List', 'Grid']) {
          await _selectLayout(tester, label);
          expect(tester.takeException(), isNull, reason: 'layout $label');
        }

        // Main menu expanded then closed.
        await tester.tap(find.byIcon(Icons.more_vert).first);
        await tester.pumpAndSettle();
        expect(find.text('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();

        // Selection mode: long-press then delete -> confirm dialog.
        await tester.longPress(find.textContaining('Note number').first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.delete).first);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Cancels the dialog.
        await tester.tap(find.text('CANCEL').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('edit page: categories, dirty back navigation and confirm dialog '
          '(${themeMode.name}, ${size.width.toInt()}x${size.height.toInt()})', (
        tester,
      ) async {
        await _pumpApp(tester, size: size, themeMode: themeMode);

        // Opens an existing note.
        await tester.tap(find.textContaining('Note number').first);
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNWidgets(2));
        expect(tester.takeException(), isNull);

        // Typing (marks the note "dirty") then back -> confirm dialog.
        await tester.enterText(
          find.byType(TextField).last,
          'Freshly typed content',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Leaves without saving.
        await tester.tap(find.text('LEAVE').last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
