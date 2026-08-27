import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/service_locator.dart';

class _InMemoryNotesRepository implements NotesRepository {
  _InMemoryNotesRepository([List<Note>? notes]) : notes = notes ?? <Note>[];
  final List<Note> notes;

  @override
  Future<List<Note>> loadNotes() async =>
      notes.where((n) => !n.isDeleted).toList();
  @override
  Future<List<Note>> loadTrashNotes() async =>
      notes.where((n) => n.isDeleted).toList();
  @override
  Future<void> upsertNote(Note note) async {
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
  }

  @override
  Future<void> trashNote(String id) async {}
  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> togglePin(String id) async {}
  @override
  Future<void> toggleLock(String id, {String? password}) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {}
  @override
  Future<List<Note>> searchNotes(String query) async => <Note>[];
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

  testWidgets('creating a note focuses the content field', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
    getIt.registerSingleton<NotesRepository>(
      _InMemoryNotesRepository(List<Note>.generate(
        3,
        (int i) => Note(id: 'note-$i', title: 'Note $i', content: 'c'),
      )),
    );

    await tester.pumpWidget(Tano(themeMode: ThemeMode.light));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Open the add-note editor.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));

    final TextField titleField =
        tester.widget<TextField>(find.byType(TextField).first);
    final TextField contentField =
        tester.widget<TextField>(find.byType(TextField).last);

    // Both fields expose a FocusNode (the title one was previously unmanaged).
    expect(titleField.focusNode, isNotNull);
    expect(contentField.focusNode, isNotNull);

    // The content field is auto-focused when creating a new note.
    expect(contentField.focusNode!.hasFocus, isTrue,
        reason: 'the content field should be focused when creating a note');
  });
}
