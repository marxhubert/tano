import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/features/folder/folder_page.dart';
import 'package:tano/shared/config/date_format.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/shared/widgets/cover_image.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/app_bar_actions.dart';
import 'package:tano/shared/widgets/note_card_bodies.dart';
import 'package:tano/shared/widgets/page_header.dart';
import 'package:tano/shared/widgets/paper_surface.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';

/// Registers the app-wide authentication service, replacing any previous one.
void _registerAuth(AuthService service) {
  if (getIt.isRegistered<AuthService>()) {
    getIt.unregister<AuthService>();
  }
  getIt.registerSingleton<AuthService>(service);
}

class _Repo implements NotesRepository, FoldersRepository {
  _Repo({required this.notes, required this.folders});

  final List<Note> notes;
  final List<Folder> folders;
  final List<String> trashed = <String>[];

  @override
  Future<List<Note>> loadNotes() async => notes;
  @override
  Future<List<Note>> loadTrashNotes() async => <Note>[];
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
  Future<void> trashNote(String id) async {
    trashed.add(id);
    final int i = notes.indexWhere((Note n) => n.id == id);
    if (i != -1) {
      notes[i] = notes[i].copyWith(isDeleted: true, deletedAt: 'now');
    }
  }

  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> toggleLock(String id, {String? password}) async {}
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
    if (i != -1) {
      folders[i] = folders[i].copyWith(isDeleted: false);
    }
  }

  @override
  Future<void> deleteAllFolders() async {}

  @override
  Future<void> deleteFolderPermanently(String id) async {
    folders.removeWhere((Folder f) => f.id == id);
    notes.removeWhere((Note n) => n.folderId == id);
  }

  @override
  Future<String> nextFolderName() async => 'Folder 1';
}

/// Fakes the system credential prompt (no platform channel in tests).
class _FakeAuth extends AuthService {
  _FakeAuth({this.authorized = true});

  bool authorized;
  int calls = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate({String? reason}) async {
    calls++;
    return authorized;
  }
}

Finder _noteCards() => find.byWidgetPredicate(
  (Widget w) => w is EntityCard && w.kind == EntityKind.note,
);

Finder _folderCards() => find.byWidgetPredicate(
  (Widget w) => w is EntityCard && w.kind == EntityKind.folder,
);

/// An icon inside the FAB only: card selection markers share `check_circle`
/// and `circle` with the FAB's select-all / select-none actions.
Finder _fabIcon(IconData icon) =>
    find.descendant(of: find.byType(AppFab), matching: find.byIcon(icon));

void main() {
  testWidgets('document filters work on Home and inside a folder', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: [
          Note(id: 'n', title: 'Home note', content: 'Text'),
          Note(
            id: 't',
            kind: EntityKind.task,
            title: 'Home task',
            content: '- [ ] Task',
          ),
          Note(id: 'fn', folderId: 'f', title: 'Folder note', content: 'Text'),
          Note(
            id: 'ft',
            kind: EntityKind.task,
            folderId: 'f',
            title: 'Folder task',
            content: '- [ ] Task',
          ),
        ],
        folders: [Folder(id: 'f', name: 'Folder')],
      ),
    );
    await tester.pumpWidget(const Tano());
    await tester.pumpAndSettle();
    for (var page = 0; page < 2; page++) {
      final prefix = page == 0 ? 'Home' : 'Folder';
      expect(find.text('All (2)', findRichText: true), findsOneWidget);
      await tester.tap(find.text('1 Task', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.text('$prefix task'), findsOneWidget);
      expect(find.text('$prefix note'), findsNothing);
      expect(find.text('1 Task', findRichText: true), findsOneWidget);
      await tester.tap(find.text('1 Note', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.text('$prefix note'), findsOneWidget);
      expect(find.text('$prefix task'), findsNothing);
      await tester.tap(find.text('All (2)', findRichText: true));
      await tester.pumpAndSettle();
      expect(find.text('All (2)', findRichText: true), findsOneWidget);
      if (page == 0) {
        await tester.tap(_folderCards());
        await tester.pumpAndSettle();
      }
    }
  });

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
    if (!getIt.isRegistered<AttachmentsStore>()) {
      getIt.registerLazySingleton<AttachmentsStore>(() => AttachmentsStore());
    }
  });

  testWidgets('folders are shown above the notes with their own header', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Free note',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
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
    expect(_folderCards(), findsOneWidget);
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

    await tester.tap(find.byIcon(Symbols.add_2));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.create_new_folder));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Perso');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repo.folders, hasLength(1));
    expect(repo.folders.single.name, 'Perso');
  });

  testWidgets('tapping elsewhere folds the home FAB extended bar back to "+"', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(notes: <Note>[], folders: <Folder>[]),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.add_2));
    await tester.pumpAndSettle();
    expect(find.byIcon(Symbols.create_new_folder), findsOneWidget);
    expect(find.byIcon(Symbols.add_notes), findsOneWidget);

    // Tapping on the page background folds the FAB back.
    await tester.tapAt(const Offset(20.0, 200.0));
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.add_2), findsOneWidget);
    expect(find.byIcon(Symbols.create_new_folder), findsNothing);
    expect(find.byIcon(Symbols.add_notes), findsNothing);
  });

  testWidgets('the home FAB reduce chevron folds the extended bar', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(notes: <Note>[], folders: <Folder>[]),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.add_2));
    await tester.pumpAndSettle();

    // Extended bar: two creation actions plus the reduce chevron.
    expect(find.byIcon(Symbols.create_new_folder), findsOneWidget);
    expect(find.byIcon(Symbols.add_notes), findsOneWidget);
    expect(find.byIcon(Symbols.arrow_forward_ios), findsOneWidget);

    await tester.tap(find.byIcon(Symbols.arrow_forward_ios));
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.add_2), findsOneWidget);
    expect(find.byIcon(Symbols.create_new_folder), findsNothing);
    expect(find.byIcon(Symbols.add_notes), findsNothing);
  });

  testWidgets('without folders the page stays "My notes"', (tester) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Free note',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
        ],
        folders: <Folder>[],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.textContaining('All (', findRichText: true), findsWidgets);
    expect(_folderCards(), findsNothing);
  });

  testWidgets('opening a folder shows its note count', (tester) async {
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    expect(find.text('Perso'), findsWidgets);
    expect(find.text('All (2)', findRichText: true), findsOneWidget);
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // The folder FAB rests reduced: expand it before using the more menu.
    await tester.tap(find.byIcon(Symbols.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.build_circle));
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // The folder FAB rests reduced: expand it before using the more menu.
    await tester.tap(find.byIcon(Symbols.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.build_circle));
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

  testWidgets('tapping outside closes the folder FAB menu and collapses it', (
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // The folder FAB rests reduced: expand it before using the more menu.
    await tester.tap(find.byIcon(Symbols.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    await tester.tapAt(const Offset(20.0, 80.0));
    await tester.pumpAndSettle();

    // Tap outside closes the menu first, then folds the FAB back to its
    // reduced (circular) form.
    expect(find.text('Edit'), findsNothing);
    expect(find.byIcon(Symbols.build_circle), findsNothing);
    expect(find.byIcon(Symbols.more_horiz), findsOneWidget);
  });

  testWidgets('tapping the theme toggle keeps the folder FAB menu open', (
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // Expand the FAB and open its more menu.
    await tester.tap(find.byIcon(Symbols.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    // Toggling the theme from the app bar must not dismiss the FAB menu.
    await tester.tap(find.byIcon(Symbols.dark_mode));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.byIcon(Symbols.build_circle), findsOneWidget);
  });

  testWidgets(
    'opening a note keeps the home FAB extended until the page changes',
    (tester) async {
      getIt.registerSingleton<NotesRepository>(
        _Repo(
          notes: <Note>[
            Note(
              id: 'n1',
              title: 'Alpha',
              content: 'x',
              date: '2026-01-01 00:00:00.000',
            ),
          ],
          folders: <Folder>[],
        ),
      );

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Open the home FAB.
      await tester.tap(find.byIcon(Symbols.add_2));
      await tester.pumpAndSettle();
      expect(find.byIcon(Symbols.create_new_folder), findsOneWidget);

      // Tapping a card navigates: the FAB must not fold back to "+" on the way.
      await tester.tap(find.text('Alpha'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Symbols.create_new_folder), findsOneWidget);
      expect(find.byIcon(Symbols.add_2), findsNothing);

      // Finish the push and let the deferred fold run (Home is covered).
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Symbols.arrow_back_ios).first);
      await tester.pumpAndSettle();

      // Back on Home, the FAB is already reduced.
      expect(find.byIcon(Symbols.add_2), findsOneWidget);
      expect(find.byIcon(Symbols.create_new_folder), findsNothing);
    },
  );

  testWidgets('returning from the editor folds the folder FAB back', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'A',
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // The folder FAB rests reduced: expand it and open the more menu.
    await tester.tap(find.byIcon(Symbols.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);

    // Open a note straight from the folder, then come back.
    await tester.tap(find.text('A'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.arrow_back_ios).first);
    await tester.pumpAndSettle();

    // Back on the folder, the FAB is reduced again and its menu is closed.
    expect(find.byIcon(Symbols.more_horiz), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    final Finder folderScaffold = find.descendant(
      of: find.byType(FolderPage),
      matching: find.byType(Scaffold),
    );
    final Finder paper = find.ancestor(
      of: folderScaffold,
      matching: find.byType(PaperSurface),
    );
    expect(paper, findsOneWidget);
    final Finder backgroundPaint = find
        .descendant(of: paper, matching: find.byType(CustomPaint))
        .first;
    final CustomPainter before = tester
        .widget<CustomPaint>(backgroundPaint)
        .painter!;
    expect(
      tester.widget<Scaffold>(folderScaffold).backgroundColor,
      Colors.transparent,
    );
    expect(barColor(tester.element(paper)), lightBackground);

    await tester.tap(find.byIcon(Symbols.dark_mode));
    await tester.pumpAndSettle();

    final CustomPainter after = tester
        .widget<CustomPaint>(backgroundPaint)
        .painter!;
    expect(
      tester.widget<Scaffold>(folderScaffold).backgroundColor,
      Colors.transparent,
    );
    expect(barColor(tester.element(paper)), darkBackground);
    expect(after.shouldRepaint(before), isTrue);
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
            important: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    final Finder page = find.byType(FolderPage);
    // The metadata line exists because the folder has flags.
    expect(find.byKey(const ValueKey<String>('folder_metadata')), findsNothing);
    // Count on the left, not next to the title.
    expect(
      find.descendant(of: page, matching: find.text('All (1)', findRichText: true)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.byIcon(Symbols.label_important)),
      findsOneWidget,
    );
    // The bookmark is the filled amber variant, at the shared metadata size.
    final Icon bookmark = tester.widget<Icon>(
      find.descendant(of: page, matching: find.byIcon(Symbols.label_important)),
    );
    expect(bookmark.fill, 1.0);
    expect(bookmark.color, tanoAmber);
    expect(bookmark.size, metadataIconSize);
    // Not locked, so no lock flag.
    expect(
      find.descendant(of: page, matching: find.byIcon(Symbols.lock)),
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // No metadata line: the count goes back to the right of the title.
    expect(find.byKey(const ValueKey<String>('folder_metadata')), findsNothing);
    expect(find.text('All (1)', findRichText: true), findsOneWidget);
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // The folder FAB rests reduced: expand it before using the more menu.
    await tester.tap(find.byIcon(Symbols.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.build_circle));
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // The folder FAB rests reduced: expand it before entering selection.
    await tester.tap(find.byIcon(Symbols.more_horiz));
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
    expect(_fabIcon(Symbols.check_circle), findsOneWidget);
    expect(find.byIcon(Symbols.build_circle), findsNothing);
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.search));
    await tester.pumpAndSettle();

    // The FAB became the search input.
    final Finder searchField = find.descendant(
      of: find.byType(AppFab),
      matching: find.byType(TextField),
    );
    expect(searchField, findsOneWidget);

    // The app bar only keeps the Cancel action.
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byIcon(Symbols.dark_mode), findsNothing);
    expect(find.byIcon(Symbols.add_2), findsNothing);

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

    await tester.tap(_folderCards());
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
            important: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.search));
    await tester.pumpAndSettle();

    final Finder page = find.byType(FolderPage);
    // Before typing, the page is unchanged: title and metadata line remain.
    expect(
      find.descendant(of: page, matching: find.text('Perso')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('folder_metadata')), findsNothing);

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
    expect(find.byKey(const ValueKey<String>('folder_metadata')), findsNothing);
  });

  testWidgets('folder card shows the [icon]xN count', (tester) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'A',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
          Note(
            id: 'n2',
            title: 'B',
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

    final Finder card = _folderCards();
    // [icon]xN note count.
    expect(
      find.descendant(of: card, matching: find.byIcon(Symbols.sticky_note_2)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('x2')),
      findsOneWidget,
    );
  });

  testWidgets('selection overlay sits at the top right of the card', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Free',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
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

    await tester.longPress(_folderCards());
    await tester.pumpAndSettle();

    final Finder align = find.ancestor(
      of: find.byIcon(Symbols.check_circle),
      matching: find.byType(Align),
    );
    expect(align, findsWidgets);
    expect(tester.widget<Align>(align.first).alignment, Alignment.topRight);
    // Selected folder shows the same white disc as a selected note.
    expect(
      find.descendant(of: _folderCards(), matching: find.byType(CircleAvatar)),
      findsOneWidget,
    );
  });

  testWidgets('folder note cards match the home layout', (tester) async {
    const String date = '2026-01-01 00:00:00.000';
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'A',
            content: '## Tasks\\n- [ ] one',
            date: date,
            folderId: 'f1',
          ),
        ],
        folders: <Folder>[Folder(id: 'f1', name: 'Perso', date: date)],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    final Finder page = find.byType(FolderPage);
    // Metadata line at the bottom of the card, like home.
    expect(
      find.descendant(of: page, matching: find.byType(NoteCounts)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: page, matching: find.text(formatNoteDate(date))),
      findsOneWidget,
    );
  });

  testWidgets('folder notes keep the bookmarked note before the others', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Plain',
            content: 'x',
            date: '2026-01-02 00:00:00.000',
            folderId: 'f1',
          ),
          Note(
            id: 'n2',
            title: 'Bookmarked',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
            important: true,
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
    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    final Rect bookmarked = tester.getRect(
      find.ancestor(
        of: find.text('Bookmarked'),
        matching: find.byType(EntityCard),
      ),
    );
    final Rect plain = tester.getRect(
      find.ancestor(of: find.text('Plain'), matching: find.byType(EntityCard)),
    );

    // Grid: the bookmarked card comes first, so it sits left of the other one.
    expect(bookmarked.left, lessThan(plain.left));
    expect(bookmarked.top, lessThanOrEqualTo(plain.top));
  });

  testWidgets('the FAB rests collapsed when the folder list scrolls', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          for (int i = 0; i < 40; i++)
            Note(
              id: 'n$i',
              title: 'Note $i',
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // Long list: the FAB is reduced so it does not hide the last notes.
    expect(find.byIcon(Symbols.more_horiz), findsOneWidget);
    expect(find.byIcon(Symbols.build_circle), findsNothing);
  });

  testWidgets('home selection counts notes, folders and items', (tester) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Free',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
          Note(
            id: 'n2',
            title: 'Free2',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
          Note(
            id: 'n3',
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

    // One note selected: the notes group speaks about notes.
    await tester.longPress(find.text('Free'));
    await tester.pumpAndSettle();
    expect(find.text('1 single note selected'), findsOneWidget);

    // Adding the folder: each group speaks about its own type.
    await tester.tap(_folderCards());
    await tester.pumpAndSettle();
    expect(find.text('1 single folder selected'), findsOneWidget);
    expect(find.text('1 single note selected'), findsOneWidget);

    // The move action is disabled when a folder is part of the selection.
    final IconButton moveButton = tester.widget<IconButton>(
      find
          .ancestor(
            of: find.byIcon(Symbols.drive_file_move),
            matching: find.byType(IconButton),
          )
          .first,
    );
    expect(moveButton.onPressed, isNull);

    // FAB order: all, none, move, delete.
    final double all = tester.getCenter(_fabIcon(Symbols.check_circle)).dx;
    final double none = tester.getCenter(_fabIcon(Symbols.circle)).dx;
    final double move = tester
        .getCenter(find.byIcon(Symbols.drive_file_move))
        .dx;
    final double delete = tester.getCenter(find.byIcon(Symbols.delete)).dx;
    expect(all, lessThan(none));
    expect(none, lessThan(move));
    expect(move, lessThan(delete));
  });

  testWidgets('move and delete are disabled when nothing is selected', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Free',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
          Note(
            id: 'n2',
            title: 'Free2',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
        ],
        folders: <Folder>[],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.longPress(find.text('Free'));
    await tester.pumpAndSettle();

    IconButton actionButton(IconData icon) => tester.widget<IconButton>(
      find
          .ancestor(of: find.byIcon(icon), matching: find.byType(IconButton))
          .first,
    );

    // One note selected: both actions are available.
    expect(actionButton(Symbols.drive_file_move).onPressed, isNotNull);
    expect(actionButton(Symbols.delete).onPressed, isNotNull);

    // Clearing the selection keeps selection mode but disables both.
    await tester.tap(_fabIcon(Symbols.circle));
    await tester.pumpAndSettle();
    expect(actionButton(Symbols.drive_file_move).onPressed, isNull);
    expect(actionButton(Symbols.delete).onPressed, isNull);
  });

  testWidgets('folder list rows have a minimum height', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'viewLayout': 'list',
    });
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

    // Empty folder (no metadata) still gets 1.5x its natural row height.
    expect(tester.getSize(_folderCards()).height, greaterThanOrEqualTo(69.0));
  });

  testWidgets('locked folders are not selectable but locked notes are', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Locked note',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            isLocked: true,
          ),
        ],
        folders: <Folder>[
          Folder(
            id: 'f1',
            name: 'Perso',
            date: '2026-01-01 00:00:00.000',
            isLocked: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Long-pressing a locked folder does not enter selection mode.
    await tester.longPress(_folderCards());
    await tester.pumpAndSettle();
    expect(find.textContaining('selected'), findsNothing);

    // A locked note is still selectable (the locked placeholder sits on top
    // of the card content, so the title appears twice).
    await tester.ensureVisible(_noteCards());
    await tester.pumpAndSettle();
    await tester.longPress(_noteCards());
    await tester.pumpAndSettle();
    expect(find.text('1 single note selected'), findsOneWidget);

    // The locked folder shows no selection circle.
    expect(
      find.descendant(
        of: _folderCards(),
        matching: find.byIcon(Symbols.circle),
      ),
      findsNothing,
    );
  });

  testWidgets('opening a result leaves the home search', (tester) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Alpha',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
        ],
        folders: <Folder>[],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.search));
    await tester.pumpAndSettle();
    final Finder field = find.descendant(
      of: find.byType(AppFab),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'Al');
    await tester.pumpAndSettle();
    expect(find.text('Results'), findsWidgets);

    // Open the note from the results, then come back.
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.arrow_back_ios).first);
    await tester.pumpAndSettle();

    // The search is gone: back to the normal title.
    expect(find.textContaining('All (', findRichText: true), findsWidgets);
    expect(find.text('Results'), findsNothing);
  });

  testWidgets('folder selection stays scoped to the search results', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          for (int i = 0; i < 6; i++)
            Note(
              id: 'n$i',
              title: 'Match $i',
              content: 'x',
              date: '2026-01-01 00:00:00.000',
              folderId: 'f1',
            ),
          Note(
            id: 'o1',
            title: 'Other',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
          ),
          Note(
            id: 'l1',
            title: 'Match locked',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
            isLocked: true,
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.search));
    await tester.pumpAndSettle();
    final Finder field = find.descendant(
      of: find.byType(AppFab),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'Match');
    await tester.pumpAndSettle();

    // The locked match is excluded, 6 results remain.
    expect(_noteCards(), findsNWidgets(6));
    expect(find.text('Match locked'), findsNothing);

    await tester.longPress(find.text('Match 0'));
    await tester.pumpAndSettle();
    expect(find.text('1 single note selected'), findsOneWidget);

    await tester.tap(_noteCards().at(1));
    await tester.pumpAndSettle();
    // Total is the number of results, not the whole folder.
    expect(find.text('2/6 notes selected'), findsOneWidget);

    // Cancelling the selection drops the search too.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Results'), findsNothing);
    // Back to the normal folder view: the search action is available again.
    expect(find.byIcon(Symbols.search), findsOneWidget);
    expect(find.text('Perso'), findsWidgets);
  });

  testWidgets('a locked note in an unlocked folder asks for the credential', (
    tester,
  ) async {
    final _FakeAuth auth = _FakeAuth(authorized: false);
    _registerAuth(auth);
    addTearDown(() async {
      if (getIt.isRegistered<AuthService>()) {
        await getIt.unregister<AuthService>();
      }
    });

    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Locked note',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            folderId: 'f1',
            isLocked: true,
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

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    // Refused credential: the prompt runs but the editor stays closed.
    await tester.tap(_noteCards());
    await tester.pumpAndSettle();
    expect(auth.calls, 1);
    expect(find.byType(EditNote), findsNothing);

    // Accepted credential: the note opens.
    auth.authorized = true;
    await tester.tap(_noteCards());
    await tester.pumpAndSettle();
    expect(auth.calls, 2);
    expect(find.byType(EditNote), findsOneWidget);
  });

  testWidgets('folder selection move files a note into another folder', (
    tester,
  ) async {
    final _Repo repo = _Repo(
      notes: <Note>[
        Note(
          id: 'n1',
          title: 'A',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
          folderId: 'f1',
        ),
      ],
      folders: <Folder>[
        Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        Folder(id: 'f2', name: 'Work', date: '2026-01-01 00:00:00.000'),
      ],
    );
    getIt.registerSingleton<NotesRepository>(repo);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(_folderCards().first);
    await tester.pumpAndSettle();

    await tester.longPress(find.text('A'));
    await tester.pumpAndSettle();
    expect(find.text('1 single note selected'), findsOneWidget);
    await tester.tap(find.byIcon(Symbols.drive_file_move));
    await tester.pumpAndSettle();

    // The current folder is not offered; Work is.
    expect(find.text('Home'), findsOneWidget);
    await tester.tap(find.text('Work'));
    await tester.pumpAndSettle();

    expect(repo.notes.firstWhere((Note n) => n.id == 'n1').folderId, 'f2');
  });

  testWidgets('the editor moves the note to a folder', (tester) async {
    final _Repo repo = _Repo(
      notes: <Note>[
        Note(
          id: 'n1',
          title: 'Alpha',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
        ),
      ],
      folders: <Folder>[
        Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
      ],
    );
    getIt.registerSingleton<NotesRepository>(repo);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perso'));
    await tester.pumpAndSettle();

    expect(repo.notes.firstWhere((Note n) => n.id == 'n1').folderId, 'f1');
  });

  testWidgets('the move picker is a FAB sub-menu, not a native sheet', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      final _Repo repo = _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Alpha',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
        ],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      );
      getIt.registerSingleton<NotesRepository>(repo);

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Select the note on the home page, then open the move picker.
      await tester.longPress(find.text('Alpha'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Symbols.drive_file_move));
      await tester.pumpAndSettle();

      // No iOS action sheet: the folder list lives in the FAB sub-menu.
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(
        find.descendant(of: find.byType(AppFab), matching: find.text('Perso')),
        findsOneWidget,
      );
      expect(find.text('Home'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('deleting selected notes in a folder asks for confirmation', (
    tester,
  ) async {
    final _Repo repo = _Repo(
      notes: <Note>[
        Note(
          id: 'n1',
          title: 'A',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
          folderId: 'f1',
        ),
      ],
      folders: <Folder>[
        Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
      ],
    );
    getIt.registerSingleton<NotesRepository>(repo);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(_folderCards());
    await tester.pumpAndSettle();

    await tester.longPress(find.text('A'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.delete));
    await tester.pumpAndSettle();

    // Nothing is deleted before the confirmation.
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(repo.trashed, isEmpty);

    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();
    expect(repo.trashed, contains('n1'));
  });

  testWidgets('cards show the cover except on locked items', (tester) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Covered',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            coverImage: 'cover.jpg',
          ),
          Note(
            id: 'n2',
            title: 'Locked cover',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            coverImage: 'cover.jpg',
            isLocked: true,
          ),
        ],
        folders: <Folder>[
          Folder(
            id: 'f1',
            name: 'Perso',
            date: '2026-01-01 00:00:00.000',
            coverImage: 'folder.jpg',
          ),
          Folder(
            id: 'f2',
            name: 'Locked',
            date: '2026-01-01 00:00:00.000',
            coverImage: 'folder.jpg',
            isLocked: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // A folder never renders a cover any more, and a locked note hides its
    // own: only the unlocked note shows one.
    expect(find.byType(CoverImage), findsOneWidget);
  });

  testWidgets('scrolling home shows the TanoNote app bar title', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: List<Note>.generate(
          20,
          (int i) => Note(
            id: 'n$i',
            title: 'Note $i',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
        ),
        folders: <Folder>[],
      ),
    );

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // The reduced title only appears once the page is scrolled.
    expect(find.byType(TanoAppBarTitle), findsNothing);

    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0.0, -400.0),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TanoAppBarTitle), findsOneWidget);
  });

  testWidgets('every icon action carries an accessibility label', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Alpha',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
          ),
        ],
        folders: <Folder>[
          Folder(id: 'f1', name: 'Perso', date: '2026-01-01 00:00:00.000'),
        ],
      ),
    );

    // Every icon-only action must carry a tooltip, i.e. a semantic label.
    void expectLabelled() {
      final List<IconButton> buttons = tester
          .widgetList<IconButton>(find.byType(IconButton))
          .toList();
      expect(buttons, isNotEmpty);
      for (final IconButton button in buttons) {
        expect(
          button.tooltip,
          isNotNull,
          reason: 'IconButton without a tooltip: ${button.icon}',
        );
      }
    }

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Home app bar and FAB.
    expectLabelled();

    // Editor app bar.
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expectLabelled();
    await tester.tap(find.byIcon(Symbols.arrow_back_ios).first);
    await tester.pumpAndSettle();

    // Folder app bar.
    await tester.tap(_folderCards());
    await tester.pumpAndSettle();
    expectLabelled();
  });

  testWidgets('the interface survives a large system text scale', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Alpha',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
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

    expect(tester.takeException(), isNull);
  });
}
