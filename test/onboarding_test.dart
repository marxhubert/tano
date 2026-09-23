import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/features/onboarding/onboarding_page.dart';
import 'package:tano/features/settings/about_page.dart';
import 'package:tano/features/splash/splash_page.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/onboarding_controller.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';

/// In-memory [NotesRepository], so the introduction tests never touch the disk.
class _InMemoryNotesRepository implements NotesRepository {
  _InMemoryNotesRepository([List<Note>? notes]) : notes = notes ?? <Note>[];

  final List<Note> notes;

  @override
  Future<List<Note>> loadNotes() async => notes.where((Note n) => !n.isDeleted).toList();

  @override
  Future<List<Note>> loadTrashNotes() async => notes.where((Note n) => n.isDeleted).toList();

  @override
  Future<void> upsertNote(Note note) async {
    final int index = notes.indexWhere((Note n) => n.id == note.id);
    if (index == -1) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
  }

  @override
  Future<void> trashNote(String id) async {
    final int index = notes.indexWhere((Note n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now().toString(),
      );
    }
  }

  @override
  Future<void> restoreNote(String id) async {
    final int index = notes.indexWhere((Note n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(isDeleted: false, deletedAt: null);
    }
  }

  @override
  Future<void> deleteNotePermanently(String id) async {
    notes.removeWhere((Note n) => n.id == id);
  }

  @override
  Future<List<Note>> searchNotes(String query) async => notes
      .where((Note n) =>
          !n.isDeleted &&
          (n.title.toLowerCase().contains(query.toLowerCase()) ||
              n.content.toLowerCase().contains(query.toLowerCase())))
      .toList();

  @override
  Future<void> deleteAllNotes() async => notes.clear();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.marxhubert.tanonote',
      version: '0.9.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await LocaleController.instance.init();
    await ThemeController.instance.init();
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
    getIt.registerSingleton<NotesRepository>(_InMemoryNotesRepository());
  });

  testWidgets('the first launch opens the introduction on its first page', (
    WidgetTester tester,
  ) async {
    OnboardingController.instance.debugSetSeen(false);

    await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text(AppText.tr('onboarding_title_1')), findsOneWidget);
    expect(find.text(AppText.tr('onboarding_title_2')), findsNothing);
  });

  testWidgets('the introduction walks through its three pages', (
    WidgetTester tester,
  ) async {
    OnboardingController.instance.debugSetSeen(false);

    await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppText.tr('onboarding_next').toUpperCase()));
    await tester.pumpAndSettle();
    expect(find.text(AppText.tr('onboarding_title_2')), findsOneWidget);

    await tester.tap(find.text(AppText.tr('onboarding_next').toUpperCase()));
    await tester.pumpAndSettle();
    expect(find.text(AppText.tr('onboarding_title_3')), findsOneWidget);
    // The last page carries the closing label instead of "next".
    expect(find.text(AppText.tr('onboarding_start').toUpperCase()), findsOneWidget);
  });

  testWidgets('skipping remembers the choice and opens the app', (
    WidgetTester tester,
  ) async {
    OnboardingController.instance.debugSetSeen(false);

    await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppText.tr('onboarding_skip')));
    await tester.pumpAndSettle();

    expect(OnboardingController.instance.seen, isTrue);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(Home), findsOneWidget);
  });

  testWidgets('an app that already saw the introduction opens on the splash', (
    WidgetTester tester,
  ) async {
    OnboardingController.instance.debugSetSeen(true);

    await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(Home), findsOneWidget);
  });

  testWidgets('the About page replays the introduction', (
    WidgetTester tester,
  ) async {
    // The replay entry is the last section of the page: give the slivers the
    // room they need to be built.
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    OnboardingController.instance.debugSetSeen(true);

    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppText.tr('onboarding_replay')));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsOneWidget);

    await tester.tap(find.text(AppText.tr('onboarding_skip')));
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.text(AppText.tr('onboarding_replay')), findsOneWidget);
  });

  testWidgets('the last page creates the first note on an empty home', (
    WidgetTester tester,
  ) async {
    OnboardingController.instance.debugSetSeen(false);

    await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));
    await tester.pumpAndSettle();

    await tester.tap(find.text(AppText.tr('onboarding_next').toUpperCase()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppText.tr('onboarding_next').toUpperCase()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppText.tr('onboarding_start').toUpperCase()));
    await tester.pumpAndSettle();

    expect(find.byType(EditNote), findsOneWidget);
  });
}