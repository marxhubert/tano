import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/search_history_controller.dart';
import 'package:tano/shared/config/service_locator.dart';

/// In-memory [NotesRepository] so the home can be reached without a database.
class _InMemoryNotesRepository implements NotesRepository {
  final List<Note> notes = <Note>[
    Note(
      id: '1',
      title: 'Vacances',
      content: 'La plage',
      date: '2026-08-01 10:00:00.000',
    ),
    Note(
      id: '2',
      title: 'Courses',
      content: 'Du pain',
      date: '2026-08-02 10:00:00.000',
    ),
  ];

  @override
  Future<List<Note>> loadNotes() async => notes;
  @override
  Future<List<Note>> loadTrashNotes() async => <Note>[];
  @override
  Future<void> upsertNote(Note note) async {}
  @override
  Future<void> trashNote(String id) async {}
  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> toggleLock(String id, {String? password}) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {}
  @override
  Future<List<Note>> searchNotes(String query) async => notes
      .where((Note note) => note.title.toLowerCase().contains(query.toLowerCase()))
      .toList();
  @override
  Future<void> deleteAllNotes() async => notes.clear();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
    getIt.registerSingleton<NotesRepository>(_InMemoryNotesRepository());
  });

  test('a repeated query moves back to the front', () async {
    await SearchHistoryController.instance.clear();
    await SearchHistoryController.instance.add('alpha');
    await SearchHistoryController.instance.add('beta');
    await SearchHistoryController.instance.add('alpha');
    expect(SearchHistoryController.instance.entries, <String>['alpha', 'beta']);
  });

  test('an empty or blank query is not remembered', () async {
    await SearchHistoryController.instance.clear();
    await SearchHistoryController.instance.add('   ');
    expect(SearchHistoryController.instance.entries, isEmpty);
  });

  test('the list is capped and survives a reload', () async {
    await SearchHistoryController.instance.clear();
    for (int i = 0; i < 12; i++) {
      await SearchHistoryController.instance.add('query $i');
    }
    expect(
      SearchHistoryController.instance.entries,
      hasLength(SearchHistoryController.maxEntries),
    );
    expect(SearchHistoryController.instance.entries.first, 'query 11');

    await SearchHistoryController.instance.init();
    expect(SearchHistoryController.instance.entries.first, 'query 11');
  });

  test('clear forgets everything', () async {
    await SearchHistoryController.instance.add('something');
    await SearchHistoryController.instance.clear();
    expect(SearchHistoryController.instance.entries, isEmpty);
  });

  testWidgets('the empty search field offers the recent queries', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      await SearchHistoryController.instance.clear();
      await SearchHistoryController.instance.add('vacances');
    });

    await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.document_search).first);
    await tester.pumpAndSettle();

    expect(find.text(AppText.tr('search_history')), findsOneWidget);
    expect(find.text('vacances'), findsOneWidget);

    // Picking one runs it, and the shortcut steps aside for the results.
    await tester.tap(find.text('vacances'));
    await tester.pumpAndSettle();
    expect(find.text(AppText.tr('search_history')), findsNothing);
  });

  testWidgets('the Clear action empties the list', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await SearchHistoryController.instance.clear();
      await SearchHistoryController.instance.add('vacances');
    });

    await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.document_search).first);
    await tester.pumpAndSettle();
    expect(find.text(AppText.tr('search_history')), findsOneWidget);

    // The title line carries the action: clearing leaves the plain list.
    await tester.tap(find.text(AppText.tr('clear')));
    await tester.pumpAndSettle();
    expect(SearchHistoryController.instance.entries, isEmpty);
    expect(find.text(AppText.tr('search_history')), findsNothing);
  });
}