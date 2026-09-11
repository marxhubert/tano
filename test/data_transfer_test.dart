import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/settings/data_transfer.dart';
import 'package:tano/features/settings/data_transfer_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';

class _EmptyRepository implements NotesRepository {
  @override
  Future<List<Note>> loadNotes() async => <Note>[];

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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.instance.init();
    await ThemeController.instance.init();
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
  });

  testWidgets('the export dialog opens with the encryption option', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(_EmptyRepository());

    await tester.pumpWidget(const MaterialApp(home: DataTransferPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export data'));
    await tester.pumpAndSettle();

    expect(find.text('Encrypt the export'), findsOneWidget);
    // The password field is shown while the encryption switch is on.
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
  });

  testWidgets('the export dialog is a Cupertino alert on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      getIt.registerSingleton<NotesRepository>(_EmptyRepository());

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            DefaultCupertinoLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: const DataTransferPage(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export data'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(CupertinoSwitch), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the import password dialog is a Cupertino alert on iOS', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
            DefaultCupertinoLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => Center(
                child: ElevatedButton(
                  onPressed: () => showImportPasswordDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('a short export password is rejected without saving', (
    tester,
  ) async {
    getIt.registerSingleton<NotesRepository>(_EmptyRepository());

    await tester.pumpWidget(const MaterialApp(home: DataTransferPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export data'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'short');
    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    expect(
      find.text('The password must be at least 8 characters.'),
      findsOneWidget,
    );
    // The dialog stays open: nothing was written.
    expect(find.text('Encrypt the export'), findsOneWidget);
  });
}
