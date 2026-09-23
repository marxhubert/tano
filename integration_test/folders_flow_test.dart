import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/widgets/entity_card.dart';

class _Repo implements NotesRepository, FoldersRepository {
  final List<Note> notes = <Note>[
    Note(id: 'n1', title: 'Free note', content: 'x', date: '2026-01-01 00:00:00.000'),
  ];
  final List<Folder> folders = <Folder>[];

  @override
  Future<List<Note>> loadNotes() async => notes.where((Note n) => !n.isDeleted).toList();
  @override
  Future<List<Note>> loadTrashNotes() async => notes.where((Note n) => n.isDeleted).toList();
  @override
  Future<List<Note>> searchNotes(String query) async => notes;
  @override
  Future<void> upsertNote(Note note) async {
    final int i = notes.indexWhere((Note n) => n.id == note.id);
    if (i == -1) {
      notes.add(note);
    } else {
      notes[i] = note;
    }
  }

  @override
  Future<void> trashNote(String id) async {}
  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {}
  @override
  Future<void> deleteAllNotes() async {}

  @override
  Future<List<Folder>> loadFolders() async => folders;
  @override
  Future<void> upsertFolder(Folder folder) async {
    final int i = folders.indexWhere((Folder f) => f.id == folder.id);
    if (i == -1) {
      folders.add(folder);
    } else {
      folders[i] = folder;
    }
  }

  @override
  Future<void> trashFolder(String id) async {
    final int i = folders.indexWhere((Folder f) => f.id == id);
    if (i != -1) {
      folders[i] = folders[i].copyWith(isDeleted: true, deletedAt: 'now');
    }
  }
  @override
  Future<List<Folder>> loadTrashFolders() async =>
      folders.where((Folder f) => f.isDeleted).toList();
  @override
  Future<void> restoreFolder(String id) async {
    final int i = folders.indexWhere((Folder f) => f.id == id);
    if (i != -1) folders[i] = folders[i].copyWith(isDeleted: false);
  }
  @override
  Future<void> deleteAllFolders() async {}

  @override
  Future<void> deleteFolderPermanently(String id) async {
    folders.removeWhere((Folder f) => f.id == id);
    notes.removeWhere((Note n) => n.folderId == id);
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('creates a folder and shows it on the home screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocaleController.instance.init();
    await ThemeController.instance.init();
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.marxhubert.tanonote',
      version: '0.8.4',
      buildNumber: '1',
      buildSignature: '',
    );
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
    final _Repo repository = _Repo();
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('My notes'), findsWidgets);

    // Create a folder from the home FAB extended bar.
    await tester.tap(find.byIcon(Symbols.add_2));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.create_new_folder));
    await tester.pumpAndSettle();
    // iOS uses a CupertinoTextField, Android a TextField: EditableText covers
    // both.
    await tester.enterText(find.byType(EditableText), 'Perso');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // The folder must be persisted exactly once...
    expect(repository.folders, hasLength(1));
    // ...and shown on the home screen.
    expect(find.text('My folders'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget w) => w is EntityCard && w.kind == EntityKind.folder,
      ),
      findsWidgets,
    );
    expect(find.text('Perso'), findsWidgets);
  });
  testWidgets('moves a note into a folder, then opens the folder', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocaleController.instance.init();
    await ThemeController.instance.init();
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.marxhubert.tanonote',
      version: '0.9.0',
      buildNumber: '1',
      buildSignature: '',
    );
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
    final _Repo repository = _Repo();
    repository.folders.add(
      Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
    );
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // File the note through the selection FAB: the real gesture, not a call.
    await tester.longPress(find.text('Free note'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.drive_file_move));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perso'));
    await tester.pumpAndSettle();

    expect(repository.notes.single.folderId, 'f1');

    // The folder now holds it, and opening it shows the note.
    await tester.tap(find.text('Perso').first);
    await tester.pumpAndSettle();
    expect(find.text('Free note'), findsWidgets);
  });
}
