import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';

/// In-memory [NotesRepository] so the test never touches the disk.
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
      notes[index] = notes[index].copyWith(isDeleted: false, deletedAt: null);
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
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
  });

  testWidgets('home reflects edits saved through the back button', (
    tester,
  ) async {
    final repository = _InMemoryNotesRepository(<Note>[
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

    expect(find.byType(Home), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);

    // Open the note editor.
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));

    // Modify the title.
    await tester.enterText(find.byType(TextField).first, 'Hello updated');
    await tester.pumpAndSettle();

    // Back -> "Save before leaving" dialog -> Save.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('SAVE').last);
    await tester.pumpAndSettle();

    // Home must reflect the persisted edit without reopening Settings.
    expect(find.byType(Home), findsOneWidget);
    expect(find.text('Hello updated'), findsOneWidget);
    expect(find.text('Hello'), findsNothing);
    expect(repository.notes.first.title, 'Hello updated');
  });
}
