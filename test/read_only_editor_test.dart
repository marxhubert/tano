import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/action.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/features/editor/edit_note_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/shared/widgets/theme.dart';

class _Repo implements NotesRepository {
  @override
  Future<List<Note>> loadNotes() async => const <Note>[];
  @override
  Future<List<Note>> loadTrashNotes() async => const <Note>[];
  @override
  Future<void> upsertNote(Note note) async {}
  @override
  Future<void> trashNote(String id) async {}
  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {}
  @override
  Future<List<Note>> searchNotes(String query) async => const <Note>[];
  @override
  Future<void> deleteAllNotes() async {}
}

/// No device credential: locking stays refused.
class _Auth extends AuthService {
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<bool> authenticate({String? reason}) async => false;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await getIt.reset();
    await LocaleController.instance.init();
    getIt.registerSingleton<NotesRepository>(_Repo());
    getIt.registerSingleton<AuthService>(_Auth());
  });

  Future<void> pumpReadOnly(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: tanoTheme(Brightness.light),
        home: EditNote(
          add: false,
          readOnly: true,
          noteAction: NoteAction(
            kind: NoteActionKind.cancel,
            note: Note(
              id: '1',
              title: 'Read only',
              content: 'body',
              date: '2026-01-01 00:00:00.000',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a read-only document has no FAB and no theme toggle', (
    tester,
  ) async {
    await pumpReadOnly(tester);

    expect(find.byType(AppFab), findsNothing);
    expect(find.byIcon(Symbols.dark_mode), findsNothing);
    // The Find-in action replaces the editing actions.
    expect(find.byIcon(Symbols.search), findsOneWidget);
    // The title field is shown but read-only.
    final TextField title = tester.widget<TextField>(
      find.byType(TextField).first,
    );
    expect(title.readOnly, isTrue);
  });

  testWidgets('the Find-in action opens the find bar', (tester) async {
    await pumpReadOnly(tester);

    await tester.tap(find.byIcon(Symbols.search));
    // Find mode blinks the matches, so the tree never settles.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The FAB returns as the find bar only.
    expect(find.byType(AppFab), findsOneWidget);
    expect(find.byIcon(Symbols.search), findsWidgets);
  });
}
