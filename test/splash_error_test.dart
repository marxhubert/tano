import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/features/splash/splash_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';

/// Repository that fails the first time before returning notes.
class _FlakyRepository implements NotesRepository {
  int loadCalls = 0;

  @override
  Future<List<Note>> loadNotes() async {
    loadCalls++;
    if (loadCalls == 1) {
      throw StateError('database unreadable');
    }
    return <Note>[
      Note(
        id: 'loaded',
        title: 'Loaded note',
        content: 'x',
        date: '2026-01-01 00:00:00.000',
      ),
    ];
  }

  @override
  Future<List<Note>> loadTrashNotes() async => <Note>[];

  @override
  Future<List<Note>> searchNotes(String query) async => <Note>[];

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
}

void main() {
  late _FlakyRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.instance.init();
    await ThemeController.instance.init();
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
  });

  testWidgets('shows a dedicated error screen when loading fails', (
    tester,
  ) async {
    repository = _FlakyRepository();
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 1);
    expect(find.text('Unable to load your notes'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.text('Quit'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('retry loads the notes and reaches home', (tester) async {
    repository = _FlakyRepository();
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.loadCalls, 2);
    expect(find.byType(Home), findsOneWidget);
    expect(find.text('Loaded note'), findsWidgets);
  });

  testWidgets('quit asks the platform to close the app', (tester) async {
    repository = _FlakyRepository();
    getIt.registerSingleton<NotesRepository>(repository);

    final List<String> methods = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        methods.add(call.method);
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Quit'));
    await tester.pump();

    expect(methods, contains('SystemNavigator.pop'));
  });
}
