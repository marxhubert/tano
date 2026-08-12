import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/domain/notes_repository.dart';
import 'package:tano/main.dart';
import 'package:tano/models/note.dart';
import 'package:tano/pages/home.dart';
import 'package:tano/pages/splash.dart';

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

  testWidgets('le splash affiche le logo puis navigue vers l\'accueil', (tester) async {
    final _InMemoryNotesRepository repository = _InMemoryNotesRepository(<Note>[
      Note(id: '1', title: 'Hello', content: 'World', date: '2026-08-12 10:00:00.000', important: false, category: 'note'),
    ]);

    await tester.pumpWidget(Tano(repository: repository));

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(Home), findsOneWidget);
  });
}
