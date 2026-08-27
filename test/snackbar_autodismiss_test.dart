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
  Future<void> trashNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now().toString(),
      );
    }
  }

  @override
  Future<void> restoreNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(
        isDeleted: false,
        deletedAt: null,
      );
    }
  }

  @override
  Future<void> togglePin(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(isPinned: !notes[index].isPinned);
    }
  }

  @override
  Future<void> toggleLock(String id, {String? password}) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(isLocked: !notes[index].isLocked);
    }
  }

  @override
  Future<void> deleteNotePermanently(String id) async {
    notes.removeWhere((n) => n.id == id);
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    return notes
        .where((n) =>
            !n.isDeleted &&
            (n.title.toLowerCase().contains(query.toLowerCase()) ||
                n.content.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }
}

List<Note> _demoNotes() => List<Note>.generate(
  5,
  (int i) => Note(
    id: 'note-$i',
    title: 'Note number $i',
    content: 'Content of note $i',
    date: '2026-08-01 10:00:00.000',
  ),
);

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

  testWidgets('undo snackbar auto-dismisses after its duration', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
    getIt.registerSingleton<NotesRepository>(
      _InMemoryNotesRepository(_demoNotes()),
    );

    await tester.pumpWidget(Tano(themeMode: ThemeMode.light));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Switch to list layout so swipe-to-delete is available.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('List').last);
    await tester.pumpAndSettle();

    // Swipe the first note to delete it.
    await tester.drag(
      find.textContaining('Note number').first,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    // The delete confirmation dialog is shown.
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('DELETE').last);
    await tester.pumpAndSettle();

    // The undo snackbar is shown.
    expect(find.byType(SnackBar), findsOneWidget);

    // A SnackBar with an action used to persist forever (persist defaults to
    // action != null). It must auto-dismiss after its duration instead.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing,
        reason: 'SnackBar should auto-dismiss after its duration');
  });

  testWidgets('undo snackbar is dismissed when leaving Home', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
    getIt.registerSingleton<NotesRepository>(
      _InMemoryNotesRepository(_demoNotes()),
    );

    await tester.pumpWidget(Tano(themeMode: ThemeMode.light));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Switch to list layout so swipe-to-delete is available.
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('List').last);
    await tester.pumpAndSettle();

    // Swipe the first note to delete it.
    await tester.drag(
      find.textContaining('Note number').first,
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('DELETE').last);
    await tester.pumpAndSettle();

    // The undo snackbar is shown.
    expect(find.byType(SnackBar), findsOneWidget);

    // Open another note: navigating away from Home must dismiss the snackbar
    // immediately, before its timeout.
    await tester.tap(find.text('Note number 1'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing,
        reason: 'SnackBar should be dismissed when leaving Home');
  });
}
