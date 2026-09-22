import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';
import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/fab_side_controller.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/features/editor/edit_note_page.dart';

class _Repo extends Fake implements NotesRepository, FoldersRepository {
  final folders = <Folder>[Folder(id: 'f0', name: 'Archive')];
  final notes = <Note>[
    Note(
      id: 'n1',
      title: 'Loose',
      content: 'Body',
      date: '2026-09-19 08:30:00.000',
    ),
    Note(
      id: 'n0',
      folderId: 'f0',
      title: 'Filed',
      content: 'Body',
      date: '2026-09-20 08:30:00.000',
    ),
  ];
  @override
  Future<List<Note>> loadNotes() async => notes;
  @override
  Future<List<Folder>> loadFolders() async => folders;
  @override
  Future<void> upsertNote(Note note) async {}
}

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  PackageInfo.setMockInitialValues(
    appName: 'TanoNote',
    packageName: 'test.tano',
    version: '1.0',
    buildNumber: '1',
    buildSignature: '',
  );
  await getIt.reset();
  final _Repo repo = _Repo();
  getIt.registerSingleton<NotesRepository>(repo);
  getIt.registerSingleton<FoldersRepository>(repo);
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));
  await tester.pumpAndSettle();
}

bool _fabOnLeft(WidgetTester tester) =>
    tester.widget<AppFab>(find.byType(AppFab)).onLeft;

void main() {
  testWidgets('the editor uses the shared FAB side and keeps its state', (
    tester,
  ) async {
    await _pumpApp(tester);
    await FabSideController.instance.setOnLeft(true);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Loose'));
    await tester.pumpAndSettle();

    expect(find.byType(EditNote), findsOneWidget);
    expect(_fabOnLeft(tester), isTrue);
    final page = find.descendant(
      of: find.byType(EditNote),
      matching: find.byType(PageScaffold),
    );
    FlushFabLocation location() =>
        tester.widget<PageScaffold>(page).floatingActionButtonLocation!
            as FlushFabLocation;
    expect(location().onLeft, isTrue);
    final state = tester.state<AppFabState>(find.byType(AppFab));

    await FabSideController.instance.setOnLeft(false);
    await tester.pumpAndSettle();
    expect(_fabOnLeft(tester), isFalse);
    expect(location().onLeft, isFalse);
    expect(tester.state<AppFabState>(find.byType(AppFab)), same(state));
    expect(find.text('Loose'), findsOneWidget);
  });

  for (final inFolder in <bool>[false, true]) {
    testWidgets(
      'a quick route return does not fold the ${inFolder ? 'folder' : 'home'} FAB later',
      (tester) async {
        await _pumpApp(tester);
        if (inFolder) {
          await tester.tap(find.text('Archive'));
          await tester.pumpAndSettle();
          if (find.byIcon(Symbols.more_horiz).evaluate().isNotEmpty) {
            await tester.tap(find.byIcon(Symbols.more_horiz));
            await tester.pumpAndSettle();
          }
        } else {
          await tester.tap(find.byIcon(Symbols.add_2));
          await tester.pumpAndSettle();
        }
        final action = inFolder ? Symbols.add_circle : Symbols.add_notes;
        expect(find.byIcon(action), findsOneWidget);
        final navigator = Navigator.of(tester.element(find.byType(AppFab)));
        navigator.push<void>(
          PageRouteBuilder<void>(
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            pageBuilder: (_, _, _) => const Scaffold(body: Text('Temporary')),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        expect(find.byIcon(action), findsOneWidget);
      },
    );
  }

  testWidgets('a folder view switch reaches Home', (WidgetTester tester) async {
    await _pumpApp(tester);

    bool homeIsList() {
      final List<EntitySliver<Note>> slivers = tester
          .widgetList<EntitySliver<Note>>(find.byType(EntitySliver<Note>))
          .toList();
      return slivers.isNotEmpty &&
          slivers.every((EntitySliver<Note> s) => s.isList);
    }

    expect(homeIsList(), isFalse, reason: 'home starts as a grid');

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.pending).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('List', findRichText: true).last);
    await tester.pumpAndSettle();

    expect(homeIsList(), isTrue, reason: 'the folder switched to list');

    await tester.tap(find.byIcon(Symbols.arrow_back_ios_new).first);
    await tester.pumpAndSettle();

    expect(homeIsList(), isTrue, reason: 'Home must pick the folder choice up');
  });

  testWidgets('the FAB side is global', (WidgetTester tester) async {
    await _pumpApp(tester);

    expect(_fabOnLeft(tester), isFalse, reason: 'right by default');

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(
      _fabOnLeft(tester),
      isFalse,
      reason: 'a folder starts on the same side',
    );

    await tester.tap(find.byIcon(Symbols.pending).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(_fabOnLeft(tester), isTrue, reason: 'the folder moved at once');

    // The switch dismissed the menu, so walk straight back to Home.
    await tester.tap(find.byIcon(Symbols.arrow_back_ios_new).first);
    await tester.pumpAndSettle();
    expect(_fabOnLeft(tester), isTrue, reason: 'Home keeps the chosen side');
  });
}
