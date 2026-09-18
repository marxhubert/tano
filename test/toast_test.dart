import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/toast.dart';

/// The little a move notice needs: a folder list, and nothing else.
class _FolderRepository implements NotesRepository, FoldersRepository {
  @override
  Future<List<Folder>> loadFolders() async => <Folder>[
    Folder(id: 'f1', name: 'Work', date: '2026-01-01 00:00:00.000'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<void> pumpHost(
    WidgetTester tester, {
    required TargetPlatform platform,
    required Future<void> Function(BuildContext context) action,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => Center(
              child: ElevatedButton(
                onPressed: () => action(context),
                child: const Text('show'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Android shows the message in a SnackBar', (
    WidgetTester tester,
  ) async {
    await pumpHost(
      tester,
      platform: TargetPlatform.android,
      action: (BuildContext context) => showTanoToast(context, 'Hello'),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('iOS shows a toast and it leaves on its own', (
    WidgetTester tester,
  ) async {
    await pumpHost(
      tester,
      platform: TargetPlatform.iOS,
      action: (BuildContext context) => showTanoToast(context, 'Hello'),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(find.text('Hello'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('the lock notice names what changed', (
    WidgetTester tester,
  ) async {
    await pumpHost(
      tester,
      platform: TargetPlatform.android,
      action: (BuildContext context) =>
          showLockToast(context, locked: true, folder: false),
    );

    await tester.tap(find.text('show'));
    await tester.pump();

    expect(find.text(AppText.tr('note_locked')), findsOneWidget);
  });

  testWidgets('the move notice names the folder', (WidgetTester tester) async {
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
    getIt.registerSingleton<NotesRepository>(_FolderRepository());
    addTearDown(() async {
      if (getIt.isRegistered<NotesRepository>()) {
        await getIt.unregister<NotesRepository>();
      }
    });

    await pumpHost(
      tester,
      platform: TargetPlatform.android,
      action: (BuildContext context) =>
          showMovedToast(context, count: 2, folderId: 'f1'),
    );

    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    final String expected =
        '2 notes ${AppText.tr('moved_to', <String, String>{'folder': 'Work'})}';
    expect(find.text(expected), findsOneWidget);
  });
}