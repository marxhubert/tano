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
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:tano/shared/widgets/entity_layout.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/main.dart';

class _Repo extends Fake implements NotesRepository, FoldersRepository {
  final folders = <Folder>[Folder(id: 'f0', name: 'Archive')];
  final notes = <Note>[
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

/// Opens a folder page on a window of [view] with [padding] as its safe area.
Future<void> _pumpFolder(
  WidgetTester tester,
  Size view, {
  FakeViewPadding padding = FakeViewPadding.zero,
}) async {
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
  tester.view.physicalSize = view;
  tester.view.devicePixelRatio = 1;
  tester.view.padding = padding;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const Tano(themeMode: ThemeMode.light));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Archive').first);
  await tester.pumpAndSettle();
}

/// The gap between the app bar's last action and the bar's right edge.
double _actionGap(WidgetTester tester) =>
    tester.getRect(find.byType(AppBar)).right -
    tester.getRect(find.byIcon(Symbols.pending)).right;

void main() {
  test('only a landscape phone goes flush', () {
    // A landscape phone reaches both edges; every other window keeps a margin,
    // so its chrome lines up with the cards.
    expect(flushSidePadding(const Size(844, 390)), isTrue);
    expect(flushSidePadding(const Size(390, 844)), isFalse);
    expect(flushSidePadding(const Size(768, 1024)), isFalse);
    expect(flushSidePadding(const Size(1024, 768)), isFalse);
    expect(flushSidePadding(const Size(1366, 1024)), isFalse);
  });

  test('a tablet is not a phone', () {
    expect(tabletViewport(const Size(844, 390)), isFalse);
    expect(tabletViewport(const Size(768, 1024)), isTrue);
    expect(tabletViewport(const Size(1024, 768)), isTrue);
    expect(phonePortraitMaxWidth, 600.0);
  });

  testWidgets('the app bar items ride the cards edges', (
    WidgetTester tester,
  ) async {
    for (final (Size view, double expected) in <(Size, double)>[
      (const Size(844, 390), 59),
      (const Size(1024, 768), 71),
      (const Size(1366, 1024), 155),
    ]) {
      await _pumpFolder(
        tester,
        view,
        padding: const FakeViewPadding(left: 59, right: 59, bottom: 21),
      );
      // The bar itself fills the window, like a site's navbar...
      expect(
        tester.getRect(find.byType(AppBar)).left,
        0,
        reason: 'bar on $view',
      );
      expect(
        tester.getRect(find.byType(AppBar)).right,
        view.width,
        reason: 'bar on $view',
      );
      // ...while the back glyph and the first card share the same left edge. The
      // safe area, our placement and the bar's own padding used to stack here
      // and pushed the back button 75px inside.
      expect(
        tester.getRect(find.byIcon(Symbols.arrow_back_ios_new)).left,
        expected,
        reason: 'back on $view',
      );
      expect(
        tester.getRect(find.byType(EntityCard).first).left,
        expected,
        reason: 'cards on $view',
      );
    }
  });

  testWidgets('the app bar keeps more margin on a tablet than on a phone', (
    WidgetTester tester,
  ) async {
    await _pumpFolder(tester, const Size(844, 390));
    final double phoneGap = _actionGap(tester);
    await _pumpFolder(tester, const Size(1024, 768));
    final double tabletGap = _actionGap(tester);
    // The phone is flush: only the action's own tap target shows. The tablet
    // adds the app bar's side padding on top of it.
    expect(phoneGap, lessThan(tabletGap));
    expect(tabletGap - phoneGap, greaterThanOrEqualTo(appPaddingSmall));
  });
}
