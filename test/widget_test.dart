import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  testWidgets('le splash affiche le logo puis navigue vers l\'accueil', (
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
    "le menu principal s'ouvre sans erreur et met en évidence l'item actif",
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

      // Ouvre le menu principal (⋮) : il ne doit pas planter même si
      // les items de tri/langue/à-propos n'ont pas d'icône.
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Display'), findsOneWidget);
      expect(find.text('Sorting'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Les icônes d'affichage sont bien rendues à droite des items.
      expect(find.byIcon(Icons.view_stream), findsOneWidget);

      // L'item actif (tri par date par défaut) est coloré avec la couleur
      // du thème, à la place de l'ancien chevron.
      final Color primary = Theme.of(
        tester.element(find.text('Date')),
      ).colorScheme.primary;
      expect(tester.widget<Text>(find.text('Date')).style?.color, primary);

      // Les items de tri n'ont pas d'icône : seule l'icône du groupe
      // Affichage (view_list/view_stream/view_module) est présente.
      expect(find.byIcon(Icons.date_range), findsNothing);
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
    },
  );
}
