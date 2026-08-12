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

  testWidgets('la page edit ne plante pas quand on ouvre le menu catégorie', (
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
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Ouvre une note existante -> page edit.
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));

    // Saisit du texte dans le contenu (focus dans un TextField).
    await tester.enterText(find.byType(TextField).last, 'Du nouveau contenu');
    await tester.pumpAndSettle();

    // Ouvre le menu de catégorie : c'est le chemin qui plantait.
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();

    expect(find.text('Note'), findsWidgets);
    await tester.tap(find.text('Work').last);
    await tester.pumpAndSettle();
  });
}
