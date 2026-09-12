import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/features/folder/folder_page.dart';
import 'package:tano/shared/widgets/app_fab.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/widgets/folder_card.dart';

class _Repo implements NotesRepository, FoldersRepository {
  _Repo({required this.notes, required this.folders});

  final List<Note> notes;
  final List<Folder> folders;

  @override
  Future<List<Note>> loadNotes() async => notes;
  @override
  Future<List<Note>> loadTrashNotes() async => <Note>[];
  @override
  Future<List<Note>> searchNotes(String query) async => notes;
  @override
  Future<void> upsertNote(Note note) async {}
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
  setUp(() async {
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
  });

  testWidgets('folders are shown above the notes with their own header', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(id: 'n1', title: 'Free note', content: 'x', date: '2026-01-01 00:00:00.000'),
          Note(
            id: 'n2',
            title: 'Filed note',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('My folders'), findsWidgets);
    expect(find.byType(FolderCard), findsOneWidget);
    expect(find.text('Perso'), findsOneWidget);
    // The filed note is not in the notes group.
    expect(find.text('Free note'), findsOneWidget);
    expect(find.text('Filed note'), findsNothing);
  });

  testWidgets('creating a folder from the FAB adds exactly one folder', (
    tester,
  ) async {
    final _Repo repo = _Repo(notes: <Note>[], folders: <Folder>[]);
    getIt.registerSingleton<NotesRepository>(repo);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.create_new_folder));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Perso');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.folders, hasLength(1));
    expect(repo.folders.single.name, 'Perso');
  });

  testWidgets('tapping elsewhere folds the home add menu back to "+"', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(notes: <Note>[], folders: <Folder>[]),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.create_new_folder), findsOneWidget);
    expect(find.byIcon(Icons.note_add), findsOneWidget);

    // Tapping on the page background folds the FAB back.
    await tester.tapAt(const Offset(20.0, 200.0));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.create_new_folder), findsNothing);
    expect(find.byIcon(Icons.note_add), findsNothing);
  });

  testWidgets('without folders the page stays "My notes"', (tester) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(id: 'n1', title: 'Free note', content: 'x', date: '2026-01-01 00:00:00.000'),
        ],
        folders: <Folder>[],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('My notes'), findsWidgets);
    expect(find.byType(FolderCard), findsNothing);
  });

  testWidgets('opening a folder shows its note count', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Filed one',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
          Note(
            id: 'n2',
            title: 'Filed two',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    expect(find.text('Perso'), findsWidgets);
    expect(find.text('2 Notes'), findsOneWidget);
  });

  testWidgets('folder more menu offers Edit right after Bookmark', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    // Bookmark ("Important") sits above Edit, Lock below it.
    final double bookmarkY = tester.getCenter(find.text('Important')).dy;
    final double editY = tester.getCenter(find.text('Edit')).dy;
    final double lockY = tester.getCenter(find.text('Lock')).dy;
    expect(editY, greaterThan(bookmarkY));
    expect(editY, lessThan(lockY));
  });

  testWidgets('editing the folder title renames it on tap outside', (
    tester,
  ) async {
    final _Repo repo = _Repo(
      notes: <Note>[],
      folders: <Folder>[
        Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
      ],
    );
    getIt.registerSingleton<NotesRepository>(repo);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // The title became an editable field pre-filled with the folder name and
    // the FAB shrank to its circular resting form.
    expect(find.byType(TextField), findsOneWidget);
    final Size fabSize = tester.getSize(
      find.descendant(
        of: find.byType(AppFab),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(fabSize.width, 64.0);

    await tester.enterText(find.byType(TextField), 'Travail');
    await tester.pumpAndSettle();

    // Tapping outside leaves edit mode and saves silently.
    await tester.tapAt(const Offset(20.0, 500.0));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(repo.folders.single.name, 'Travail');
  });

  testWidgets('tapping outside folds the folder FAB menu back', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    await tester.tapAt(const Offset(20.0, 80.0));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
  });

  testWidgets('folder background follows the theme', (tester) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    final Finder folderScaffold = find.descendant(
      of: find.byType(FolderPage),
      matching: find.byType(Scaffold),
    );
    final Scaffold before = tester.widget<Scaffold>(folderScaffold);
    await tester.tap(find.byIcon(Icons.dark_mode));
    await tester.pumpAndSettle();
    final Scaffold after = tester.widget<Scaffold>(folderScaffold);
    expect(after.backgroundColor, isNot(before.backgroundColor));
  });

  testWidgets('folder metadata line shows the count and the flags', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Filed',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[
          Folder(
            id: 'f1',
            name: 'Perso',
            date: '2026-01-01 00:00:00.000',
            isPinned: true,
            important: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    final Finder page = find.byType(FolderPage);
    // The metadata line exists because the folder has flags.
    expect(
      find.byKey(const ValueKey<String>('folder_metadata')),
      findsOneWidget,
    );
    // Count on the left, not next to the title.
    expect(
      find.descendant(of: page, matching: find.text('1 Note')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byIcon(Icons.bookmark)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byIcon(Icons.push_pin)),
      findsOneWidget,
    );
    // Not locked, so no lock flag.
    expect(
      find.descendant(of: page, matching: find.byIcon(Icons.lock_outline)),
      findsNothing,
    );
  });

  testWidgets('without folder flags the count sits next to the title', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Filed',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    // No metadata line: the count goes back to the right of the title.
    expect(find.byKey(const ValueKey<String>('folder_metadata')), findsNothing);
    expect(find.text('1 Note'), findsOneWidget);
  });

  testWidgets('folder title is capped at 54 chars and three lines', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Grid card on the home page.
    expect(tester.widget<Text>(find.text('Perso')).maxLines, 3);

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    // Editable title.
    final TextField field = tester.widget<TextField>(find.byType(TextField));
    expect(field.maxLength, 54);
    expect(field.maxLines, 3);
  });

  testWidgets('selection mode swaps the FAB icons without moving its box', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Filed',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    final Finder fabBox = find.descendant(
      of: find.byType(AppFab),
      matching: find.byType(AnimatedContainer),
    );
    final Size before = tester.getSize(fabBox);

    // Long press a note to enter selection mode.
    await tester.longPress(find.text('Filed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));

    // Mid animation the FAB box has not moved.
    expect(tester.getSize(fabBox), before);

    await tester.pumpAndSettle();

    // Selection icons replaced the editor ones, same box.
    expect(find.byIcon(Icons.select_all), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(tester.getSize(fabBox), before);
  });

  testWidgets('folder search mode mirrors the home one', (tester) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Filed',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    // The FAB became the search input.
    final Finder searchField = find.descendant(
      of: find.byType(AppFab),
      matching: find.byType(TextField),
    );
    expect(searchField, findsOneWidget);

    // The app bar only keeps the Cancel action.
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byIcon(Icons.dark_mode), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);

    // Typing switches the page title to "Results".
    await tester.enterText(searchField, 'Fil');
    await tester.pumpAndSettle();
    expect(find.text('Results'), findsWidgets);
  });

  testWidgets('selection keeps the folder title and puts the count right', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Filed',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Filed'));
    await tester.pumpAndSettle();

    final Finder page = find.byType(FolderPage);
    // The folder name stays the title; the count sits on its right.
    expect(
      find.descendant(of: page, matching: find.text('Perso')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.text('1 single note selected')),
      findsOneWidget,
    );
  });

  testWidgets('search switches to results only after the first letter', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Filed',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[
          Folder(
            id: 'f1',
            name: 'Perso',
            date: '2026-01-01 00:00:00.000',
            isPinned: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FolderCard));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    final Finder page = find.byType(FolderPage);
    // Before typing, the page is unchanged: title and metadata line remain.
    expect(
      find.descendant(of: page, matching: find.text('Perso')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('folder_metadata')),
      findsOneWidget,
    );

    final Finder searchField = find.descendant(
      of: find.byType(AppFab),
      matching: find.byType(TextField),
    );
    await tester.enterText(searchField, 'Fil');
    await tester.pumpAndSettle();

    // From the first letter: results title and no more metadata line.
    expect(
      find.descendant(of: page, matching: find.text('Results')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('folder_metadata')),
      findsNothing,
    );
  });
}
