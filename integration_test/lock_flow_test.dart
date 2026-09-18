import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';

/// In-memory storage: the lock is a UI contract, not a disk one.
class _Repo implements NotesRepository, FoldersRepository {
  _Repo({required this.notes});

  final List<Note> notes;

  @override
  Future<List<Note>> loadNotes() async =>
      notes.where((Note n) => !n.isDeleted).toList();
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
  Future<void> trashNote(String id) async {}
  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> toggleLock(String id, {String? password}) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {}
  @override
  Future<void> deleteAllNotes() async {}
  @override
  Future<void> seedFixtures() async {}

  @override
  Future<List<Folder>> loadFolders() async => <Folder>[];
  @override
  Future<void> upsertFolder(Folder folder) async {}
  @override
  Future<void> trashFolder(String id) async {}
  @override
  Future<List<Folder>> loadTrashFolders() async => <Folder>[];
  @override
  Future<void> restoreFolder(String id) async {}
  @override
  Future<void> deleteAllFolders() async {}
  @override
  Future<void> deleteFolderPermanently(String id) async {}
  @override
  Future<String> nextFolderName() async => 'Folder 1';
}

/// Answers instead of the device: a real biometric prompt cannot be driven by a
/// test, and the point here is what the app does with the answer.
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

Future<void> _pumpApp(
  WidgetTester tester, {
  required _Repo repository,
  required _FakeAuth auth,
}) async {
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
  if (getIt.isRegistered<AuthService>()) {
    await getIt.unregister<AuthService>();
  }
  getIt.registerSingleton<NotesRepository>(repository);
  getIt.registerSingleton<AuthService>(auth);

  await tester.pumpWidget(const Tano());
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

Note _lockedNote() => Note(
  id: 'n1',
  title: 'Secret',
  content: 'x',
  date: '2026-01-01 00:00:00.000',
  isLocked: true,
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a locked note opens once the credential is accepted', (
    WidgetTester tester,
  ) async {
    final _Repo repository = _Repo(notes: <Note>[_lockedNote()]);
    final _FakeAuth auth = _FakeAuth();
    await _pumpApp(tester, repository: repository, auth: auth);

    await tester.tap(find.text('Secret'));
    await tester.pumpAndSettle();

    expect(auth.calls, greaterThan(0));
    expect(find.byType(EditNote), findsOneWidget);
  });

  testWidgets('a locked note stays closed when the credential is refused', (
    WidgetTester tester,
  ) async {
    final _Repo repository = _Repo(notes: <Note>[_lockedNote()]);
    final _FakeAuth auth = _FakeAuth(authorized: false);
    await _pumpApp(tester, repository: repository, auth: auth);

    await tester.tap(find.text('Secret'));
    await tester.pumpAndSettle();

    expect(auth.calls, greaterThan(0));
    expect(find.byType(EditNote), findsNothing);
  });
}
