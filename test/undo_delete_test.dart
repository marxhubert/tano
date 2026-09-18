import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/deleted_batch.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/undo_delete.dart';

/// Records what is put back. The rest of the interface is never reached, and
/// noSuchMethod covers it so the fake stays three lines long.
class _RecordingRepo implements NotesRepository, FoldersRepository {
  final List<String> notes = <String>[];
  final List<String> folders = <String>[];

  @override
  Future<void> restoreNote(String id) async => notes.add(id);

  @override
  Future<void> restoreFolder(String id) async => folders.add(id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Note _note(String id) =>
    Note(id: id, title: id, content: 'x', date: '2026-01-01 00:00:00.000');

void main() {
  test('a batch puts back exactly what it holds: notes, then folders', () async {
    final _RecordingRepo repo = _RecordingRepo();
    await DeletedBatch(
      notes: <Note>[_note('n1'), _note('n2')],
      indexes: <int>[0, 1],
      folders: <Folder>[Folder(id: 'f1', name: 'Perso')],
    ).restoreInStorage(repo);

    expect(repo.notes, <String>['n1', 'n2']);
    expect(repo.folders, <String>['f1']);
  });

  testWidgets('the notice restores storage and runs the caller\'s own repair', (
    WidgetTester tester,
  ) async {
    final _RecordingRepo repo = _RecordingRepo();
    bool repaired = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => showUndoDelete(
                context,
                repository: repo,
                batch: DeletedBatch(
                  notes: <Note>[_note('n1')],
                  indexes: <int>[0],
                ),
                onRestored: () async => repaired = true,
              ),
              child: const Text('delete'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
    expect(find.text(AppText.tr('undo')), findsOneWidget);

    await tester.tap(find.text(AppText.tr('undo')));
    await tester.pumpAndSettle();

    expect(repo.notes, <String>['n1']);
    expect(repaired, isTrue);
  });
}
