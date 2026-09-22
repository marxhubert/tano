import 'dart:async';

import 'package:flutter/gestures.dart';
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
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

class _Repo extends Fake implements NotesRepository, FoldersRepository {
  _Repo({this.pendingNotes, this.pendingFolders});

  Completer<List<Note>>? pendingNotes;
  Completer<List<Folder>>? pendingFolders;

  static List<Note> get notes => List.generate(
    30,
    (i) => Note(
      id: 'n$i',
      title: 'Reference $i',
      date: '2026-09-${(30 - i).toString().padLeft(2, '0')}',
    ),
  );

  static List<Folder> get folders => List.generate(
    30,
    (i) => Folder(
      id: 'f$i',
      name: 'Folder $i',
      date: '2026-09-${(30 - i).toString().padLeft(2, '0')}',
    ),
  );

  @override
  Future<List<Note>> loadNotes() => pendingNotes?.future ?? Future.value(notes);

  @override
  Future<List<Folder>> loadFolders() =>
      pendingFolders?.future ?? Future.value(folders);
}

enum _Mode { editor, search, selection }

class _Host extends StatefulWidget {
  const _Host({super.key, this.onLeft = false, this.isFolderMode = false});

  final bool onLeft;
  final bool isFolderMode;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  final fabKey = GlobalKey<AppFabState>();
  final bodyFocus = FocusNode();
  final bodyController = TextEditingController(text: 'A draft');
  final searchFocus = FocusNode();
  final searchController = TextEditingController();
  _Mode mode = _Mode.editor;
  String? linkedNote;
  String? movedFolder;

  void changeMode(_Mode value) => setState(() => mode = value);

  @override
  void dispose() {
    bodyFocus.dispose();
    bodyController.dispose();
    searchFocus.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editor')),
    body: TextField(
      key: const ValueKey('draft'),
      controller: bodyController,
      focusNode: bodyFocus,
    ),
    floatingActionButtonLocation: FlushFabLocation(onLeft: widget.onLeft),
    floatingActionButton: AppFab(
      key: fabKey,
      isEditorMode: true,
      isFolderMode: widget.isFolderMode,
      collapsedByDefault: true,
      isSearchMode: mode == _Mode.search,
      isSelectionMode: mode == _Mode.selection,
      onLeft: widget.onLeft,
      currentNoteId: 'current',
      currentFolderId: widget.isFolderMode ? 'f0' : null,
      controller: searchController,
      focusNode: searchFocus,
      onNoteLinkSelected: (note) => linkedNote = note.id,
      onMoveTo: (id) => movedFolder = id,
    ),
  );
}

Future<_HostState> _pumpHost(
  WidgetTester tester, {
  _Repo? repo,
  Size size = const Size(390, 844),
  bool onLeft = false,
  bool isFolderMode = false,
  double bottomSafeArea = 0,
}) async {
  await getIt.reset();
  getIt.registerSingleton<NotesRepository>(repo ?? _Repo());
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewPadding = FakeViewPadding(bottom: bottomSafeArea);
  tester.view.padding = FakeViewPadding(bottom: bottomSafeArea);
  addTearDown(tester.view.reset);
  final key = GlobalKey<_HostState>();
  await tester.pumpWidget(
    MaterialApp(
      theme: tanoTheme(Brightness.light),
      home: _Host(key: key, onLeft: onLeft, isFolderMode: isFolderMode),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentState!;
}

Future<void> _expand(WidgetTester tester) async {
  await tester.tap(find.byIcon(Symbols.more_horiz));
  await tester.pumpAndSettle();
}

/// The outer AppFab render object precedes its nudge Transform. Measure the
/// painted decoration, so a wrong-side translation cannot pass the assertion.
Rect _surfaceRect(WidgetTester tester) {
  final container = find.descendant(
    of: find.byType(AppFab),
    matching: find.byType(AnimatedContainer),
  );
  return tester.getRect(
    find.descendant(of: container, matching: find.byType(DecoratedBox)).first,
  );
}

Finder _verticalMenuScroll() => find.descendant(
  of: find.byType(AppFab),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is Scrollable && widget.axisDirection == AxisDirection.down,
  ),
);

void main() {
  testWidgets('a late repository response cannot reopen a collapsed FAB', (
    tester,
  ) async {
    final pending = Completer<List<Note>>();
    final host = await _pumpHost(tester, repo: _Repo(pendingNotes: pending));
    await _expand(tester);
    await tester.tap(find.byIcon(Symbols.add_circle));
    await tester.pump();
    host.fabKey.currentState!.collapse();
    await tester.pumpAndSettle();

    pending.complete(_Repo.notes);
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.more_horiz), findsOneWidget);
    expect(find.text(AppText.tr('option_image')), findsNothing);
    expect(_surfaceRect(tester).size, const Size(64, 64));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the latest menu intent wins when repository responses reorder', (
    tester,
  ) async {
    final notes = Completer<List<Note>>();
    final folders = Completer<List<Folder>>();
    await _pumpHost(
      tester,
      repo: _Repo(pendingNotes: notes, pendingFolders: folders),
    );
    await _expand(tester);
    await tester.tap(find.byIcon(Symbols.add_circle));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();

    folders.complete(_Repo.folders);
    await tester.pumpAndSettle();
    notes.complete(_Repo.notes);
    await tester.pumpAndSettle();

    expect(find.text(AppText.tr('option_move')), findsOneWidget);
    expect(find.text(AppText.tr('option_image')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('folder selection loads move destinations and excludes itself', (
    tester,
  ) async {
    final host = await _pumpHost(tester, isFolderMode: true);
    host.changeMode(_Mode.selection);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.drive_file_move));
    await tester.pumpAndSettle();

    expect(find.text('Folder 0'), findsNothing);
    expect(find.text('Folder 1'), findsOneWidget);
    await tester.tap(find.text('Folder 1'));
    await tester.pumpAndSettle();
    expect(host.movedFolder, 'f1');
    expect(tester.takeException(), isNull);
  });

  for (final move in [false, true]) {
    testWidgets(
      '${move ? 'folder' : 'note'} loading can retry after a failure',
      (tester) async {
        final failedNotes = Completer<List<Note>>();
        final failedFolders = Completer<List<Folder>>();
        final repo = _Repo(
          pendingNotes: move ? null : failedNotes,
          pendingFolders: move ? failedFolders : null,
        );
        final host = await _pumpHost(tester, repo: repo);
        await _expand(tester);
        await tester.tap(
          find.byIcon(move ? Symbols.build_circle : Symbols.add_circle),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(AppText.tr(move ? 'option_move' : 'option_link')),
        );
        await tester.pump();
        if (move) {
          failedFolders.completeError(StateError('Temporary storage failure'));
        } else {
          failedNotes.completeError(StateError('Temporary storage failure'));
        }
        await tester.pumpAndSettle();
        expect(find.text(AppText.tr('retry')), findsOneWidget);
        expect(tester.takeException(), isNull);

        final recoveredNotes = Completer<List<Note>>();
        final recoveredFolders = Completer<List<Folder>>();
        repo.pendingNotes = move ? null : recoveredNotes;
        repo.pendingFolders = move ? recoveredFolders : null;
        await tester.tap(find.text(AppText.tr('retry')));
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        if (move) {
          recoveredFolders.complete(_Repo.folders);
        } else {
          recoveredNotes.complete(_Repo.notes);
        }
        await tester.pumpAndSettle();
        expect(find.text(AppText.tr('retry')), findsNothing);
        await tester.tap(find.text(move ? 'Folder 0' : 'Reference 0'));
        await tester.pumpAndSettle();
        expect(move ? host.movedFolder : host.linkedNote, move ? 'f0' : 'n0');
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('rapid mode changes reuse the search field safely', (
    tester,
  ) async {
    final host = await _pumpHost(tester);
    host.changeMode(_Mode.search);
    await tester.pumpAndSettle();
    final search = find.descendant(
      of: find.byType(AppFab),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'needle');
    for (var i = 0; i < 3; i++) {
      host.changeMode(_Mode.selection);
      await tester.pump(const Duration(milliseconds: 16));
      host.changeMode(_Mode.search);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(search, findsOneWidget);
    expect(tester.widget<TextField>(search).focusNode, same(host.searchFocus));
    expect(
      tester.widget<TextField>(search).controller,
      same(host.searchController),
    );
    expect(host.searchController.text, 'needle');
    await tester.enterText(search, 'revised');
    expect(host.searchController.text, 'revised');
    expect(host.searchFocus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard metrics retain the active menu scroll position', (
    tester,
  ) async {
    final host = await _pumpHost(tester);
    await tester.showKeyboard(find.byKey(const ValueKey('draft')));
    await _expand(tester);
    await tester.tap(find.byIcon(Symbols.add_circle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppText.tr('option_link')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reference 12'),
      100,
      scrollable: _verticalMenuScroll(),
    );
    await tester.pumpAndSettle();
    final before = tester
        .state<ScrollableState>(_verticalMenuScroll())
        .position
        .pixels;
    expect(before, greaterThan(0));

    for (final inset in [260.0, 160.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pumpAndSettle();
      final after = tester
          .state<ScrollableState>(_verticalMenuScroll())
          .position
          .pixels;
      expect(after, closeTo(before, .1));
      expect(host.bodyFocus.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('mouse menu interactions preserve the editor focus and caret', (
    tester,
  ) async {
    final host = await _pumpHost(tester);
    await tester.showKeyboard(find.byKey(const ValueKey('draft')));
    host.bodyController.selection = const TextSelection.collapsed(offset: 2);
    tester.view.viewInsets = const FakeViewPadding(bottom: 240);
    await tester.pumpAndSettle();

    for (final target in [
      find.byIcon(Symbols.more_horiz),
      find.byIcon(Symbols.add_circle),
      find.text(AppText.tr('option_link')),
      find.text('Reference 0'),
    ]) {
      await tester.tap(target, kind: PointerDeviceKind.mouse);
      await tester.pumpAndSettle();
      expect(host.bodyFocus.hasFocus, isTrue);
      expect(host.bodyController.selection.baseOffset, 2);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(tester.takeException(), isNull);
    }
    expect(host.linkedNote, 'n0');
  });

  for (final mode in [_Mode.search, _Mode.selection]) {
    testWidgets('entering ${mode.name} closes the old vertical menu', (
      tester,
    ) async {
      final host = await _pumpHost(tester);
      await _expand(tester);
      await tester.tap(find.byIcon(Symbols.palette));
      await tester.pumpAndSettle();
      expect(find.text(AppText.tr('menu_theme')), findsOneWidget);

      host.changeMode(mode);
      await tester.pumpAndSettle();

      expect(find.text(AppText.tr('menu_theme')), findsNothing);
      expect(_surfaceRect(tester).height, closeTo(64, .001));
      if (mode == _Mode.search) {
        expect(
          find.descendant(
            of: find.byType(AppFab),
            matching: find.byType(TextField),
          ),
          findsOneWidget,
        );
      } else {
        expect(find.byIcon(Symbols.drive_file_move), findsOneWidget);
      }

      host.changeMode(_Mode.editor);
      await tester.pumpAndSettle();
      expect(find.text(AppText.tr('menu_theme')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keyboard changes preserve an explicitly opened menu and focus', (
    tester,
  ) async {
    final host = await _pumpHost(tester);
    await tester.showKeyboard(find.byKey(const ValueKey('draft')));
    await _expand(tester);
    await tester.tap(find.byIcon(Symbols.palette));
    await tester.pumpAndSettle();

    for (final inset in [260.0, 0.0]) {
      tester.view.viewInsets = FakeViewPadding(bottom: inset);
      await tester.pumpAndSettle();
      expect(find.text(AppText.tr('menu_theme')), findsOneWidget);
      expect(host.bodyFocus.hasFocus, isTrue);
      expect(host.bodyController.selection.isValid, isTrue);
      expect(_surfaceRect(tester).bottom, lessThanOrEqualTo(844 - inset));
      expect(tester.takeException(), isNull);
    }
  });

  for (final move in [false, true]) {
    testWidgets(
      'a short landscape ${move ? 'move' : 'link'} menu stays usable',
      (tester) async {
        final host = await _pumpHost(
          tester,
          size: const Size(844, 390),
          bottomSafeArea: 21,
        );
        await tester.showKeyboard(find.byKey(const ValueKey('draft')));
        await _expand(tester);
        await tester.tap(
          find.byIcon(move ? Symbols.build_circle : Symbols.add_circle),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text(AppText.tr(move ? 'option_move' : 'option_link')),
        );
        await tester.pumpAndSettle();

        // Less height remains than the submenu's ordinary header. Its content
        // must still be scrollable and actionable, without dismissing the draft.
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        tester.view.padding = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final bounds = _surfaceRect(tester);
        expect(bounds.top, greaterThanOrEqualTo(kToolbarHeight));
        expect(bounds.bottom, lessThanOrEqualTo(390 - 220));
        expect(host.bodyFocus.hasFocus, isTrue);
        expect(tester.testTextInput.isVisible, isTrue);

        final target = find.text(move ? 'Folder 29' : 'Reference 29');
        expect(_verticalMenuScroll(), findsOneWidget);
        await tester.scrollUntilVisible(
          target,
          40,
          scrollable: _verticalMenuScroll(),
          maxScrolls: 75,
        );
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(move ? host.movedFolder : host.linkedNote, move ? 'f29' : 'n29');
        expect(host.bodyFocus.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final landscape in [false, true]) {
    for (final onLeft in [false, true]) {
      testWidgets(
        '${landscape ? 'landscape' : 'portrait'} ${onLeft ? 'left' : 'right'} FAB grows from its anchor',
        (tester) async {
          await _pumpHost(
            tester,
            size: landscape ? const Size(844, 390) : const Size(390, 844),
            onLeft: onLeft,
          );
          final collapsed = _surfaceRect(tester);
          expect(collapsed.size, const Size(64, 64));
          await _expand(tester);
          final expanded = _surfaceRect(tester);
          expect(
            onLeft ? expanded.left : expanded.right,
            closeTo(onLeft ? collapsed.left : collapsed.right, .1),
          );
          expect(expanded.bottom, closeTo(collapsed.bottom, .1));

          await tester.tap(find.byIcon(Symbols.palette));
          await tester.pumpAndSettle();
          final panel = _surfaceRect(tester);
          final nudge = landscape ? 0.0 : 12.0;
          expect(
            onLeft ? panel.left : panel.right,
            closeTo(
              onLeft ? collapsed.left - nudge : collapsed.right + nudge,
              .1,
            ),
          );
          expect(
            panel.bottom,
            closeTo(collapsed.bottom + (landscape ? 0 : 8), .1),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
