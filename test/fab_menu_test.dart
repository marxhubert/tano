import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';

/// What the "link a note" and "move to" menus read: a list of notes and a list
/// of folders, nothing else.
class _Repo implements NotesRepository, FoldersRepository {
  _Repo({this.notes = const <Note>[], this.folders = const <Folder>[]});

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
  Future<void> toggleLock(String id, {String? password}) async {}
  @override
  Future<void> deleteNotePermanently(String id) async {}
  @override
  Future<void> deleteAllNotes() async {}
  @override
  Future<List<Folder>> loadFolders() async => folders;
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
}

Note _note(String id) => Note(
  id: id,
  title: 'Note $id',
  content: 'x',
  date: '2026-01-01 00:00:00.000',
);

Folder _folder(String id, String name) => Folder(id: id, name: name);

Future<void> _pumpFab(
  WidgetTester tester,
  _Repo repo, {
  String? currentNoteId,
  String? currentFolderId,
}) async {
  if (getIt.isRegistered<NotesRepository>()) {
    getIt.unregister<NotesRepository>();
  }
  getIt.registerSingleton<NotesRepository>(repo);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        floatingActionButton: AppFab(
          isEditorMode: true,
          currentNoteId: currentNoteId,
          currentFolderId: currentFolderId,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Opens a sub-menu by tapping its entry, then reports whether it opened: a
/// refused entry leaves the menu where it was.
Future<bool> _tapsAndOpens(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  return find.text(AppText.tr('back')).evaluate().isNotEmpty;
}

void main() {
  testWidgets('the link action is refused while the note is the only one', (
    WidgetTester tester,
  ) async {
    await _pumpFab(
      tester,
      _Repo(notes: <Note>[_note('n1')]),
      currentNoteId: 'n1',
    );
    await tester.tap(find.byIcon(Symbols.add_circle));
    await tester.pumpAndSettle();

    expect(await _tapsAndOpens(tester, AppText.tr('option_link')), isFalse);
  });

  testWidgets('the link action opens as soon as a second note exists', (
    WidgetTester tester,
  ) async {
    await _pumpFab(
      tester,
      _Repo(notes: <Note>[_note('n1'), _note('n2')]),
      currentNoteId: 'n1',
    );
    await tester.tap(find.byIcon(Symbols.add_circle));
    await tester.pumpAndSettle();

    expect(await _tapsAndOpens(tester, AppText.tr('option_link')), isTrue);
    expect(find.text('Note n2'), findsOneWidget);
  });

  testWidgets('the move action is refused when the app holds no folder', (
    WidgetTester tester,
  ) async {
    await _pumpFab(
      tester,
      _Repo(notes: <Note>[_note('n1')]),
      currentNoteId: 'n1',
    );
    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();

    expect(await _tapsAndOpens(tester, AppText.tr('option_move')), isFalse);
  });

  testWidgets('the move action opens as soon as a folder exists', (
    WidgetTester tester,
  ) async {
    await _pumpFab(
      tester,
      _Repo(
        notes: <Note>[_note('n1')],
        folders: <Folder>[_folder('f1', 'Alpha')],
      ),
      currentNoteId: 'n1',
    );
    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();

    expect(await _tapsAndOpens(tester, AppText.tr('option_move')), isTrue);
    expect(find.text(AppText.tr('no_folder')), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('the folder the note already sits in is never offered', (
    WidgetTester tester,
  ) async {
    await _pumpFab(
      tester,
      _Repo(
        notes: <Note>[_note('n1')],
        folders: <Folder>[_folder('f1', 'Alpha'), _folder('f2', 'Beta')],
      ),
      currentNoteId: 'n1',
      currentFolderId: 'f1',
    );
    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();

    expect(await _tapsAndOpens(tester, AppText.tr('option_move')), isTrue);
    expect(find.text('Alpha'), findsNothing);
    expect(find.text('Beta'), findsOneWidget);
  });
}
