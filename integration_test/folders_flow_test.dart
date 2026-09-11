import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:tano/shared/widgets/folder_card.dart';

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
  Future<void> togglePin(String id) async {}
  @override
  Future<void> toggleLock(String id, {String? password}) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {}
  @override
  Future<void> deleteAllNotes() async {}
  @override
  Future<void> seedFixtures() async {}

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
  Future<void> trashFolder(String id) async {}
  @override
  Future<void> toggleFolderPin(String id) async {}
  @override
  Future<String> nextFolderName() async => 'Folder 1';
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

    // Create a folder from the home "+" menu.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add folder'));
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
    expect(find.byType(FolderCard), findsWidgets);
    expect(find.text('Perso'), findsWidgets);
  });
}
