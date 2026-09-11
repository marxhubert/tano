import 'package:flutter_test/flutter_test.dart';
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
  Future<void> upsertFolder(Folder folder) async {}
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
}
