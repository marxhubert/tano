import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/archive/archive_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/theme.dart';

/// In-memory repository that hands the archive its documents and records the
/// restores and permanent deletes.
class _Repo implements NotesRepository, ArchiveRepository {
  _Repo({required this.archived});

  final List<Note> archived;
  final List<String> unarchived = <String>[];
  final List<String> deleted = <String>[];

  @override
  Future<List<Note>> loadNotes() async => const <Note>[];
  @override
  Future<List<Note>> loadTrashNotes() async => const <Note>[];
  @override
  Future<List<Note>> loadArchivedNotes() async =>
      archived.where((Note note) => note.isArchived).toList();
  @override
  Future<void> upsertNote(Note note) async {}
  @override
  Future<void> trashNote(String id) async {}
  @override
  Future<void> restoreNote(String id) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {
    deleted.add(id);
    archived.removeWhere((Note note) => note.id == id);
  }

  @override
  Future<List<Note>> searchNotes(String query) async => const <Note>[];
  @override
  Future<void> deleteAllNotes() async {}
  @override
  Future<void> archiveNote(String id) async {}
  @override
  Future<void> archiveNotes(List<String> ids) async {}
  @override
  Future<void> restoreArchivedNote(String id) =>
      restoreArchivedNotes(<String>[id]);
  @override
  Future<void> restoreArchivedNotes(List<String> ids) async {
    unarchived.addAll(ids);
    archived.removeWhere((Note note) => ids.contains(note.id));
  }
}

Note _archivedNote(String id, String title) => Note(
  id: id,
  title: title,
  content: 'x',
  date: '2026-01-01 00:00:00.000',
  isArchived: true,
  archivedAt: '2026-02-01 00:00:00.000',
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    await getIt.reset();
    await LocaleController.instance.init();
  });

  Future<void> pumpArchive(WidgetTester tester, _Repo repo) async {
    getIt.registerSingleton<NotesRepository>(repo);
    await tester.pumpWidget(
      MaterialApp(
        theme: tanoTheme(Brightness.light),
        home: const ArchivePage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('archive lists its documents with the archive date and actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpArchive(tester, _Repo(archived: <Note>[_archivedNote('a', 'A')]));

    expect(find.text('Archive'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    // The archive date carries the archive glyph.
    expect(find.byIcon(Symbols.archive), findsWidgets);
    // Each card keeps the trash's two actions.
    expect(find.byIcon(Symbols.undo), findsOneWidget);
    expect(find.byIcon(Symbols.delete_forever), findsOneWidget);
    // One searchable document does not earn the search action.
    expect(find.byIcon(Symbols.document_search), findsNothing);
    expect(find.byIcon(Symbols.select), findsOneWidget);
  });

  testWidgets('the search action appears from the second searchable document', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpArchive(
      tester,
      _Repo(archived: <Note>[_archivedNote('a', 'A'), _archivedNote('b', 'B')]),
    );

    expect(find.byIcon(Symbols.document_search), findsOneWidget);
  });

  testWidgets('select swaps search and select for unarchive and delete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final _Repo repo = _Repo(
      archived: <Note>[_archivedNote('a', 'A'), _archivedNote('b', 'B')],
    );
    await pumpArchive(tester, repo);

    await tester.tap(find.byIcon(Symbols.select));
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.unarchive), findsOneWidget);
    expect(find.byIcon(Symbols.delete), findsOneWidget);
    expect(find.byIcon(Symbols.document_search), findsNothing);
    expect(find.byIcon(Symbols.select), findsNothing);

    // Select one card, then unarchive the selection.
    await tester.tap(find.byType(EntityCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.unarchive));
    await tester.pumpAndSettle();

    expect(repo.unarchived, contains('a'));
  });
}
