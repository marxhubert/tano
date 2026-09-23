import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/main.dart';
import 'package:tano/core/models/content_entity.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/shared/widgets/manageable_cover.dart';
import 'package:tano/shared/widgets/theme.dart';

/// In-memory [NotesRepository] so the widget test never touches the disk.
class _InMemoryNotesRepository implements NotesRepository {
  _InMemoryNotesRepository([List<Note>? notes]) : notes = notes ?? <Note>[];

  final List<Note> notes;

  @override
  Future<List<Note>> loadNotes() async => notes.where((n) => !n.isDeleted).toList();

  @override
  Future<List<Note>> loadTrashNotes() async => notes.where((n) => n.isDeleted).toList();

  @override
  Future<void> upsertNote(Note note) async {
    final index = notes.indexWhere((n) => n.id == note.id);
    if (index == -1) {
      notes.add(note);
    } else {
      notes[index] = note;
    }
  }

  @override
  Future<void> trashNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(
        isDeleted: true,
        deletedAt: DateTime.now().toString(),
      );
    }
  }

  @override
  Future<void> restoreNote(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(
        isDeleted: false,
        deletedAt: null,
      );
    }
  }


  @override
  Future<void> toggleLock(String id, {String? password}) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) notes[index] = notes[index].copyWith(isLocked: !notes[index].isLocked);
  }

  @override
  Future<void> deleteNotePermanently(String id) async {
    notes.removeWhere((n) => n.id == id);
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    return notes
        .where((n) =>
            !n.isDeleted &&
            (n.title.toLowerCase().contains(query.toLowerCase()) ||
                n.content.toLowerCase().contains(query.toLowerCase())))
        .toList();
  }

  @override
  Future<void> deleteAllNotes() async {
    notes.clear();
  }

}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.marxhubert.tanonote',
      version: '0.8.4',
      buildNumber: '1',
      buildSignature: '',
    );
    if (getIt.isRegistered<NotesRepository>()) {
      getIt.unregister<NotesRepository>();
    }
    if (!getIt.isRegistered<AttachmentsStore>()) {
      getIt.registerLazySingleton<AttachmentsStore>(() => AttachmentsStore());
    }
  });

  testWidgets('the edit page does not crash when opening the category menu', (
    tester,
  ) async {
    final _InMemoryNotesRepository repository = _InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
        important: false,
        category: 'note',
      ),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Opens an existing note -> edit page.
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));

    // Types text into the content (focus inside a TextField).
    await tester.enterText(find.byType(TextField).last, 'Some new content');
    await tester.pumpAndSettle();
  });

  testWidgets('toggling the bookmark in the editor updates the icon reactively', (
    tester,
  ) async {
    final _InMemoryNotesRepository repository = _InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
        important: false,
        category: 'neutral',
      ),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    // Bookmark now lives in the FAB's "more" menu, not the app bar.
    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();

    // Outlined while the note is not bookmarked: only the menu's own mark.
    expect(tester.widget<Icon>(find.byIcon(Symbols.bookmark)).fill, 0.0);

    await tester.tap(find.byIcon(Symbols.bookmark));
    await tester.pumpAndSettle();

    // Filled once bookmarked. The editor's metadata line now carries its own
    // outlined mark too, so exactly one of the two is filled.
    final List<Icon> marks = tester
        .widgetList<Icon>(find.byIcon(Symbols.bookmark))
        .toList();
    expect(marks.where((Icon icon) => icon.fill == 1.0), hasLength(1));
    expect(marks.where((Icon icon) => icon.fill == 0.0), hasLength(1));
  });

  testWidgets('the editor metadata line outlines the bookmark on a note', (
    tester,
  ) async {
    final _InMemoryNotesRepository repository = _InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
        important: true,
      ),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    // The metadata line's own mark: outlined, in the metadata's ink, and a
    // touch larger than the counts beside it.
    final Finder mark = find.byIcon(Symbols.bookmark);
    final Icon icon = tester.widget<Icon>(mark);
    expect(icon.fill, 0.0);
    expect(icon.size, 16.0);
    expect(icon.color, mutedTextColor(tester.element(mark)));
  });

  testWidgets('the editor metadata line outlines the bookmark on a task', (
    tester,
  ) async {
    final _InMemoryNotesRepository repository = _InMemoryNotesRepository(<Note>[
      Note(
        kind: EntityKind.task,
        id: '1',
        title: 'Chores',
        content: 'Tidy',
        date: '2026-08-12 10:00:00.000',
        important: true,
      ),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chores'));
    await tester.pumpAndSettle();

    final Finder mark = find.byIcon(Symbols.bookmark);
    final Icon icon = tester.widget<Icon>(mark);
    expect(icon.fill, 0.0);
    expect(icon.size, 16.0);
    expect(icon.color, mutedTextColor(tester.element(mark)));
  });

  testWidgets('the FAB marks the bookmark in brown and delete in red', (
    tester,
  ) async {
    final _InMemoryNotesRepository repository = _InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
        important: true,
      ),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.build_circle));
    await tester.pumpAndSettle();

    // The filled bookmark in the more menu goes solid white on the light
    // theme, with no outline.
    final Icon bookmark = tester.widget<Icon>(
      find.byWidgetPredicate(
        (Widget w) => w is Icon && w.icon == Symbols.bookmark && w.fill == 1.0,
      ),
    );
    expect(bookmark.color, Colors.white);
    expect(bookmark.shadows, isNull);
    // Delete wears the app's red, softened for the teal bars.
    expect(
      tester.widget<Icon>(find.byIcon(Symbols.delete)).color,
      TanoStates.error.dark,
    );
  });

  testWidgets('the editor cover bleeds on a phone and is inset on landscape', (
    tester,
  ) async {
    final _InMemoryNotesRepository repository = _InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
        coverImage: 'cover.png',
      ),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);

    // A phone in portrait: the cover bleeds to both edges, square.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    ManageableCover cover() =>
        tester.widget<ManageableCover>(find.byType(ManageableCover));
    expect(cover().padding.left, 0.0);
    expect(cover().padding.right, 0.0);
    expect(cover().borderRadius, BorderRadius.zero);

    // A landscape window aligns it with the content and rounds it.
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expect(cover().padding.left, appPaddingMedium);
    expect(cover().padding.right, appPaddingMedium);
    expect(cover().borderRadius, BorderRadius.circular(appBorderRadius));
  });
}
