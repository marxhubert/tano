import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/main.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/features/splash/splash_page.dart';

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

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.instance.init();
    await ThemeController.instance.init();
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.shikamarx.tano',
      version: '0.8.4',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  testWidgets('the splash shows the logo then navigates to the home screen', (
    tester,
  ) async {
    final _InMemoryNotesRepository repository = _InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
        important: false,
        category: 'note',
      ),
    ]);

    await tester.pumpWidget(Tano(repository: repository));

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(Home), findsOneWidget);
  });

  testWidgets(
    "the main menu opens without error and highlights the active item",
    (tester) async {
      final _InMemoryNotesRepository repository =
          _InMemoryNotesRepository(<Note>[
            Note(
              id: '1',
              title: 'Hello',
              content: 'World',
              date: '2026-08-12 10:00:00.000',
              important: false,
              category: 'note',
            ),
          ]);

      await tester.pumpWidget(Tano(repository: repository));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(Home), findsOneWidget);
      
      // Opens the main menu (⋮): it must not crash even if the
      // sorting/language/about items have no icon.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Sorting'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // The display icons are correctly rendered to the right of the items.
      expect(find.byIcon(Icons.view_stream), findsOneWidget);

      // The active item (default date sorting) is colored with the theme
      // color, replacing the old chevron.
      final Color primary = Theme.of(
        tester.element(find.text('Date')),
      ).colorScheme.primary;
      expect(tester.widget<Text>(find.text('Date')).style?.color, primary);

      // The sorting items have no icon: only the icon of the Display group
      // (view_list/view_stream/view_module) is present.
      expect(find.byIcon(Icons.date_range), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
    },
  );
}
