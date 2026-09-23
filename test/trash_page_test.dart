import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/features/trash/trash_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/theme.dart';

/// In-memory repository that hands the trash its deleted folders and notes.
class _Repo implements NotesRepository, FoldersRepository {
  _Repo({required this.notes, required this.folders});

  final List<Note> notes;
  final List<Folder> folders;

  /// Ids passed to [deleteNotePermanently], so a test can prove a locked item
  /// was never destroyed.
  final List<String> permanentlyDeleted = <String>[];

  @override
  Future<List<Note>> loadNotes() async =>
      notes.where((Note note) => !note.isDeleted).toList();
  @override
  Future<List<Note>> loadTrashNotes() async =>
      notes.where((Note note) => note.isDeleted).toList();
  @override
  Future<List<Folder>> loadFolders() async =>
      folders.where((Folder folder) => !folder.isDeleted).toList();
  @override
  Future<List<Folder>> loadTrashFolders() async =>
      folders.where((Folder folder) => folder.isDeleted).toList();

  @override
  Future<void> upsertNote(Note note) async {}
  @override
  Future<void> upsertFolder(Folder folder) async {}
  @override
  Future<void> trashNote(String id) async {}
  @override
  Future<void> trashFolder(String id) async {}
  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> restoreFolder(String id) async {}
  @override
  Future<void> toggleLock(String id, {String? password}) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {
    permanentlyDeleted.add(id);
  }
  @override
  Future<void> deleteFolderPermanently(String id) async {}
  @override
  Future<List<Note>> searchNotes(String query) async => const <Note>[];
  @override
  Future<void> deleteAllNotes() async {}
  @override
  Future<void> deleteAllFolders() async {}
}

/// Authentication that is available but always refused, so the test never
/// depends on the host platform's biometrics.
class _DeniedAuth extends AuthService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate({String? reason}) async => false;
}

Folder _folder(int i) => Folder(
  id: 'f$i',
  name: 'Folder $i',
  date: '2026-01-01 00:00:00.000',
  isDeleted: true,
);

Note _note() => Note(
  id: 'n1',
  title: 'Gone',
  content: 'x',
  date: '2026-01-01 00:00:00.000',
  isDeleted: true,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await getIt.reset();
    await LocaleController.instance.init();
  });

  testWidgets('trash reads three folders to a row and titles the docs group', (
    tester,
  ) async {
    // Tall enough that the docs group below the folder grid is built.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[_note()],
        folders: <Folder>[for (int i = 0; i < 4; i++) _folder(i)],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(theme: tanoTheme(Brightness.light), home: const TrashPage()),
    );
    await tester.pumpAndSettle();

    // The deleted documents group, titled "Docs".
    expect(find.text('Docs'), findsOneWidget);

    final Finder folderCards = find.byWidgetPredicate(
      (Widget w) => w is EntityCard && w.kind == EntityKind.folder,
    );
    expect(folderCards, findsNWidgets(4));

    final List<Rect> rects = <Rect>[
      for (int i = 0; i < 4; i++) tester.getRect(folderCards.at(i)),
    ];
    // Three share the first row, left to right...
    expect(rects[0].top, rects[1].top);
    expect(rects[1].top, rects[2].top);
    expect(rects[0].left, lessThan(rects[1].left));
    expect(rects[1].left, lessThan(rects[2].left));
    // ...and the fourth drops to the next one.
    expect(rects[3].top, greaterThan(rects[0].top));
    expect(rects[3].left, rects[0].left);
  });

  testWidgets('locked trash items keep their lock and their two actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    getIt.registerSingleton<NotesRepository>(
      _Repo(
        notes: <Note>[
          Note(
            id: 'n1',
            title: 'Locked doc',
            content: 'x',
            date: '2026-01-01 00:00:00.000',
            isDeleted: true,
            isLocked: true,
          ),
        ],
        folders: <Folder>[
          Folder(
            id: 'f1',
            name: 'Locked folder',
            date: '2026-01-01 00:00:00.000',
            isDeleted: true,
            isLocked: true,
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(theme: tanoTheme(Brightness.light), home: const TrashPage()),
    );
    await tester.pumpAndSettle();

    // Both cards stay locked...
    expect(find.byIcon(Symbols.lock), findsNWidgets(2));
    // ...and both keep the restore and delete actions.
    expect(find.byIcon(Symbols.undo), findsNWidgets(2));
    expect(find.byIcon(Symbols.delete_forever), findsNWidgets(2));
  });

  testWidgets('a locked note is only destroyed after authentication', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final _Repo repo = _Repo(
      notes: <Note>[
        Note(
          id: 'n1',
          title: 'Locked doc',
          content: 'x',
          date: '2026-01-01 00:00:00.000',
          isDeleted: true,
          isLocked: true,
        ),
      ],
      folders: <Folder>[],
    );
    getIt.registerSingleton<NotesRepository>(repo);
    getIt.registerSingleton<AuthService>(_DeniedAuth());

    await tester.pumpWidget(
      MaterialApp(theme: tanoTheme(Brightness.light), home: const TrashPage()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.delete_forever));
    await tester.pumpAndSettle();

    expect(repo.permanentlyDeleted, isEmpty);
    expect(find.text(AppText.tr('delete_locked_error')), findsOneWidget);
  });
}
