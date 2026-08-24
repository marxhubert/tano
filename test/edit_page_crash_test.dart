import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/main.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/editor/edit_note_page.dart';

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

  @override
  Future<void> trashNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) notes[index] = notes[index].copyWith(isDeleted: true);
  }

  @override
  Future<void> restoreNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) notes[index] = notes[index].copyWith(isDeleted: false);
  }

  @override
  Future<void> togglePin(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) notes[index] = notes[index].copyWith(isPinned: !notes[index].isPinned);
  }

  @override
  Future<void> toggleLock(String id, {String? password}) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) notes[index] = notes[index].copyWith(isLocked: !notes[index].isLocked);
  }

  @override
  Future<void> deleteNotePermanently(String id) async {
    notes.removeWhere((n) => n.id == id);
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
    if (getIt.isRegistered<NotesRepository>()) {
      getIt.unregister<NotesRepository>();
    }
  });

  testWidgets('the edit page does not crash when opening the category menu', (
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
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Opens an existing note -> edit page.
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));

    // Types text into the content (focus inside a TextField).
    await tester.enterText(find.byType(TextField).last, 'Some new content');
    await tester.pumpAndSettle();
  });

  testWidgets('toggling the bookmark in the editor updates the icon reactively', (
    tester,
  ) async {
    final _InMemoryNotesRepository repository = _InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
        important: false,
        category: 'neutral',
      ),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    final Finder editorBookmark = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.bookmark_border),
    );
    expect(editorBookmark, findsOneWidget);

    await tester.tap(editorBookmark);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.bookmark),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.bookmark_border),
      ),
      findsNothing,
    );
  });
}
