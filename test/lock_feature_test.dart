import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_fixtures.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/features/editor/edit_note_view_model.dart';
import 'package:tano/features/notes/home_view_model.dart';
import 'package:tano/features/notes/widgets/note_list_view.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/widgets/app_fab.dart';
import 'package:tano/shared/widgets/note_card.dart';

/// Fakes the system credential prompt: no platform channel in tests.
class _FakeAuthService extends AuthService {
  _FakeAuthService({this.available = true, this.authorized = true});

  final bool available;
  final bool authorized;
  int authenticateCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({String? reason}) async {
    authenticateCalls++;
    // Mirrors the real fail-closed behaviour.
    return available && authorized;
  }
}

/// In-memory [NotesRepository] so the tests never touch the disk.
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

  @override
  Future<void> deleteAllNotes() async {
    notes.clear();
  }

  @override
  Future<void> seedFixtures() async {
    notes.clear();
    notes.addAll(buildNotesFixtures());
  }
}

Note _note({
  String id = '1',
  String title = 'Hello',
  String content = 'World',
  bool isLocked = false,
}) {
  return Note(
    id: id,
    title: title,
    content: content,
    date: '2026-08-12 10:00:00.000',
    important: false,
    category: 'note',
    isLocked: isLocked,
  );
}

EditNoteViewModel _viewModelFor(_InMemoryNotesRepository repository) {
  return EditNoteViewModel(
    repository: repository,
    add: false,
    initialNote: repository.notes.first,
  );
}

/// Whether an open editor holds [title] in its title field.
bool _editorTitleExists(WidgetTester tester, String title) {
  return tester
      .widgetList<TextField>(find.byType(TextField))
      .any((TextField field) => field.controller?.text == title);
}

/// Taps the note link at the beginning of the note content.
Future<void> _tapContentLink(WidgetTester tester) async {
  final Offset topLeft = tester.getTopLeft(find.byType(TextField).last);
  await tester.tapAt(topLeft + const Offset(4, 9));
  await tester.pumpAndSettle();
}

void main() {
  late AuthService originalAuth;

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
    originalAuth = AuthService.instance;
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
  });

  tearDown(() {
    AuthService.instance = originalAuth;
  });

  group('AuthService', () {
    test('fails closed when no system credential is available', () async {
      // In the test environment the local_auth plugin is not registered, so
      // the capability probe fails: the service must report unavailable and
      // refuse to authenticate instead of silently unlocking a note.
      final AuthService service = AuthService();

      expect(await service.isAvailable(), isFalse);
      expect(await service.authenticate(reason: 'test'), isFalse);
    });
  });

  group('EditNoteViewModel.toggleLock', () {
    test('locking a note is immediate and never prompts', () async {
      final fake = _FakeAuthService();
      AuthService.instance = fake;
      final repository = _InMemoryNotesRepository(<Note>[_note()]);
      final vm = _viewModelFor(repository);

      expect(vm.isLocked, isFalse);
      expect(await vm.toggleLock(), LockToggleResult.locked);
      expect(vm.isLocked, isTrue);
      expect(fake.authenticateCalls, 0);
    });

    test('unlocking a locked note requires authentication', () async {
      final fake = _FakeAuthService();
      AuthService.instance = fake;
      final repository = _InMemoryNotesRepository(<Note>[_note(isLocked: true)]);
      final vm = _viewModelFor(repository);

      expect(vm.isLocked, isTrue);
      expect(await vm.toggleLock(), LockToggleResult.unlocked);
      expect(vm.isLocked, isFalse);
      expect(fake.authenticateCalls, 1);
    });

    test('a cancelled authentication keeps the note locked', () async {
      final fake = _FakeAuthService(authorized: false);
      AuthService.instance = fake;
      final repository = _InMemoryNotesRepository(<Note>[_note(isLocked: true)]);
      final vm = _viewModelFor(repository);

      expect(await vm.toggleLock(), LockToggleResult.cancelled);
      expect(vm.isLocked, isTrue);
      expect(fake.authenticateCalls, 1);
    });

    test('locking is refused when the device has no system credential', () async {
      AuthService.instance = _FakeAuthService(available: false);
      final repository = _InMemoryNotesRepository(<Note>[_note()]);
      final vm = _viewModelFor(repository);

      expect(await vm.toggleLock(), LockToggleResult.unavailable);
      expect(vm.isLocked, isFalse);
    });

    test('a lock change marks the editor dirty', () async {
      AuthService.instance = _FakeAuthService();
      final repository = _InMemoryNotesRepository(<Note>[_note()]);
      final vm = _viewModelFor(repository);

      expect(vm.isDirty(title: 'Hello', content: 'World'), isFalse);
      await vm.toggleLock();
      expect(vm.isDirty(title: 'Hello', content: 'World'), isTrue);
    });

    test('locking then auto-saving persists isLocked', () async {
      AuthService.instance = _FakeAuthService();
      final repository = _InMemoryNotesRepository(<Note>[_note()]);
      final vm = _viewModelFor(repository);

      // Mirrors what the editor does when the menu item is selected.
      expect(await vm.toggleLock(), LockToggleResult.locked);
      await vm.autoSaveThemeOrBookmark(title: 'Hello', content: 'World');

      expect(repository.notes.first.isLocked, isTrue);
    });

    test('unlocking then auto-saving persists the unlocked state', () async {
      AuthService.instance = _FakeAuthService();
      final repository = _InMemoryNotesRepository(<Note>[_note(isLocked: true)]);
      final vm = _viewModelFor(repository);

      expect(await vm.toggleLock(), LockToggleResult.unlocked);
      await vm.autoSaveThemeOrBookmark(title: 'Hello', content: 'World');

      expect(repository.notes.first.isLocked, isFalse);
    });
  });

  group('HomeViewModel.hasLockedInSelection', () {
    test('is false when no selection contains a locked note', () {
      final repository = _InMemoryNotesRepository(<Note>[
        _note(),
        _note(id: '2', title: 'Other', isLocked: true),
      ]);
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: repository.notes,
      );

      expect(vm.hasLockedInSelection, isFalse);
      vm.enterSelectionMode('1');
      expect(vm.hasLockedInSelection, isFalse);
    });

    test('is true as soon as a locked note is selected', () {
      final repository = _InMemoryNotesRepository(<Note>[
        _note(),
        _note(id: '2', title: 'Other', isLocked: true),
      ]);
      final vm = HomeViewModel(
        repository: repository,
        initialNotes: repository.notes,
      );

      vm.enterSelectionMode('2');
      expect(vm.hasLockedInSelection, isTrue);

      vm.toggleSelection('2');
      vm.toggleSelection('1');
      expect(vm.hasLockedInSelection, isFalse);
    });
  });

  group('lock UI', () {
    testWidgets('the more menu shows Unlock with lock_open when locked', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AppFab(isEditorMode: true, isLocked: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Unlock'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open), findsOneWidget);
      expect(find.text('Lock'), findsNothing);
    });

    testWidgets('the more menu shows Lock with lock_outline when unlocked', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: AppFab(isEditorMode: true, isLocked: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Lock'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('Unlock'), findsNothing);
    });

    testWidgets('home shows a lock badge on a locked note', (tester) async {
      getIt.registerSingleton<NotesRepository>(
        _InMemoryNotesRepository(<Note>[_note(isLocked: true)]),
      );

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(NoteCard),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
    });

    testWidgets('home shows no lock badge on an unlocked note', (tester) async {
      getIt.registerSingleton<NotesRepository>(
        _InMemoryNotesRepository(<Note>[_note()]),
      );

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(NoteCard),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
    });

    testWidgets('a locked note is not opened when authentication fails', (
      tester,
    ) async {
      AuthService.instance = _FakeAuthService(authorized: false);
      getIt.registerSingleton<NotesRepository>(
        _InMemoryNotesRepository(<Note>[_note(isLocked: true)]),
      );

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NoteCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(EditNote), findsNothing);
    });

    testWidgets('a locked note opens once authentication succeeds', (
      tester,
    ) async {
      AuthService.instance = _FakeAuthService();
      getIt.registerSingleton<NotesRepository>(
        _InMemoryNotesRepository(<Note>[_note(isLocked: true)]),
      );

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NoteCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(EditNote), findsOneWidget);
      // The metadata row shows the lock next to the date, with its own
      // separator before the date.
      expect(
        find.descendant(
          of: find.byType(EditNote),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byType(EditNote), matching: find.text('|')),
        findsNWidgets(2),
      );
    });

    testWidgets('the metadata has no lock and a single separator when unlocked', (
      tester,
    ) async {
      getIt.registerSingleton<NotesRepository>(
        _InMemoryNotesRepository(<Note>[_note()]),
      );

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();
      expect(find.byType(EditNote), findsOneWidget);

      expect(
        find.descendant(
          of: find.byType(EditNote),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byType(EditNote), matching: find.text('|')),
        findsOneWidget,
      );
    });

    testWidgets('locking is refused when the device has no screen lock', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      AuthService.instance = _FakeAuthService(available: false);
      final repository = _InMemoryNotesRepository(<Note>[_note()]);
      getIt.registerSingleton<NotesRepository>(repository);

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Hello'));
      await tester.pumpAndSettle();
      expect(find.byType(EditNote), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lock'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Cannot lock this note'), findsOneWidget);
      expect(
        find.text(
          'Set up a screen lock (passcode or biometrics) to lock notes',
        ),
        findsOneWidget,
      );
      expect(repository.notes.single.isLocked, isFalse);
    });

    testWidgets('a locked note cannot be swipe-deleted from the home list', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repository = _InMemoryNotesRepository(<Note>[_note(isLocked: true)]);
      getIt.registerSingleton<NotesRepository>(repository);
      bool confirmCalled = false;

      final vm = HomeViewModel(
        repository: repository,
        initialNotes: repository.notes,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                NoteListView(
                  viewModel: vm,
                  onOpenNote: (Note note) {},
                  onShowUndoSnackBar: () {},
                  confirmDelete: () async {
                    confirmCalled = true;
                    return true;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Locked notes cannot be deleted'), findsOneWidget);
      expect(confirmCalled, isFalse);
      expect(vm.notes, hasLength(1));
    });

    testWidgets('a locked note cannot be deleted through the selection bar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repository = _InMemoryNotesRepository(<Note>[_note(isLocked: true)]);
      getIt.registerSingleton<NotesRepository>(repository);

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(NoteCard).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Locked notes cannot be deleted'), findsOneWidget);
      expect(repository.notes.single.isDeleted, isFalse);
    });
  });

  group('lock navigation', () {
    testWidgets('a locked grid card centers up to three title lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteCard(
              note: _note(
                title: 'A very long title that needs several lines to display',
                isLocked: true,
              ),
              builder: (context, textColor) => const SizedBox(height: 80.0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Text title = tester.widget<Text>(
        find.textContaining('A very long title'),
      );
      expect(title.maxLines, 3);
      expect(title.textAlign, TextAlign.center);
      expect(title.overflow, TextOverflow.ellipsis);
    });

    testWidgets('a locked list card keeps two left-aligned title lines', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteCard(
              note: _note(
                title: 'A very long title that needs several lines to display',
                isLocked: true,
              ),
              isListLayout: true,
              builder: (context, textColor) => const SizedBox(height: 80.0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Text title = tester.widget<Text>(
        find.textContaining('A very long title'),
      );
      expect(title.maxLines, 2);
      expect(title.textAlign, TextAlign.start);
      expect(title.overflow, TextOverflow.ellipsis);

      // Lock on the left, title then date stacked to its right.
      final Offset iconCenter = tester.getCenter(
        find.byIcon(Icons.lock_outline),
      );
      final Offset titleCenter = tester.getCenter(
        find.textContaining('A very long title'),
      );
      final Offset dateCenter = tester.getCenter(find.text('12 Aug 2026'));
      expect(iconCenter.dx, lessThan(titleCenter.dx));
      expect(dateCenter.dy, greaterThan(titleCenter.dy));
    });

    testWidgets('a link between two locked notes does not prompt again', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fake = _FakeAuthService();
      AuthService.instance = fake;
      getIt.registerSingleton<NotesRepository>(
        _InMemoryNotesRepository(<Note>[
          _note(id: 'a', title: 'Note A', content: 'A body', isLocked: true),
          _note(id: 'b', title: 'Note B', content: '[[a:Note A]]', isLocked: true),
        ]),
      );

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Opening the locked note B authenticates once.
      await tester.tap(find.text('Note B').last);
      await tester.pumpAndSettle();
      expect(fake.authenticateCalls, 1);
      expect(_editorTitleExists(tester, 'Note B'), isTrue);

      // Following the link to the other locked note must not prompt again.
      await _tapContentLink(tester);

      expect(fake.authenticateCalls, 1);
      expect(_editorTitleExists(tester, 'Note A'), isTrue);
    });

    testWidgets('a link from an unlocked note still asks for the code', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fake = _FakeAuthService(authorized: false);
      AuthService.instance = fake;
      getIt.registerSingleton<NotesRepository>(
        _InMemoryNotesRepository(<Note>[
          _note(id: 'a', title: 'Note A', content: 'A body', isLocked: true),
          _note(id: 'c', title: 'Note C', content: '[[a:Note A]]'),
        ]),
      );

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Opening the unlocked note C does not authenticate.
      await tester.tap(find.text('Note C'));
      await tester.pumpAndSettle();
      expect(fake.authenticateCalls, 0);
      expect(_editorTitleExists(tester, 'Note C'), isTrue);

      // The link to the locked note A prompts; refusing keeps us on C.
      await _tapContentLink(tester);

      expect(fake.authenticateCalls, 1);
      expect(_editorTitleExists(tester, 'Note A'), isFalse);
      expect(_editorTitleExists(tester, 'Note C'), isTrue);
    });

    testWidgets('a link from an unlocked note opens after authentication', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final fake = _FakeAuthService();
      AuthService.instance = fake;
      getIt.registerSingleton<NotesRepository>(
        _InMemoryNotesRepository(<Note>[
          _note(id: 'a', title: 'Note A', content: 'A body', isLocked: true),
          _note(id: 'c', title: 'Note C', content: '[[a:Note A]]'),
        ]),
      );

      await tester.pumpWidget(const Tano());
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Note C'));
      await tester.pumpAndSettle();
      expect(fake.authenticateCalls, 0);

      await _tapContentLink(tester);

      expect(fake.authenticateCalls, 1);
      expect(_editorTitleExists(tester, 'Note A'), isTrue);
    });
  });
}
