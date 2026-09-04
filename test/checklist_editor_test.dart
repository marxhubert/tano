import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/service_locator.dart';

/// In-memory [NotesRepository] so the widget test never touches the disk.
class _InMemoryNotesRepository implements NotesRepository {
  _InMemoryNotesRepository([List<Note>? notes]) : notes = notes ?? <Note>[];

  final List<Note> notes;

  @override
  Future<List<Note>> loadNotes() async =>
      notes.where((n) => !n.isDeleted).toList();

  @override
  Future<List<Note>> loadTrashNotes() async =>
      notes.where((n) => n.isDeleted).toList();

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
  Future<void> togglePin(String id) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(isPinned: !notes[index].isPinned);
    }
  }

  @override
  Future<void> toggleLock(String id, {String? password}) async {
    final index = notes.indexWhere((n) => n.id == id);
    if (index != -1) {
      notes[index] = notes[index].copyWith(isLocked: !notes[index].isLocked);
    }
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
}

String _contentText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).last).controller!.text;

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.shikamarx.tano',
      version: '0.8.4',
      buildNumber: '1',
      buildSignature: '',
    );
    if (getIt.isRegistered<NotesRepository>()) {
      getIt.unregister<NotesRepository>();
    }
  });

  testWidgets('checklist counter shows; app bar title appears only when scrolled',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final String base = List<String>.filled(
      40,
      'Paragraphe assez long pour faire defiler la note.',
    ).join('\n');
    final String content = '$base\n## \n- [ ] Item';
    getIt.registerSingleton<NotesRepository>(_InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: content,
        date: '2026-08-12 10:00:00.000',
      ),
    ]));

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    // The checklist counter appears (done_all icon + "x1"), no links.
    expect(find.byIcon(Icons.done_all), findsOneWidget);
    expect(find.text('x1'), findsOneWidget);
    expect(find.byIcon(Icons.sticky_note_2), findsNothing);

    // Make the note dirty: undo/redo/save appear, but the app bar title is
    // still hidden because the note has not been scrolled yet.
    await tester.showKeyboard(find.byType(TextField).last);
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: '$content\najoute',
        selection: const TextSelection.collapsed(offset: 0),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Hello')),
      findsNothing,
    );

    // Scroll down far enough: the title now appears, on the left.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    final Finder appBarTitle = find.descendant(
      of: find.byType(AppBar),
      matching: find.text('Hello'),
    );
    expect(appBarTitle, findsOneWidget);
    final Rect appBarRect = tester.getRect(find.byType(AppBar));
    final Rect titleRect = tester.getRect(appBarTitle);
    expect(titleRect.center.dx, lessThan(appBarRect.center.dx));
  });

  testWidgets('inserts a checklist at the end of the note when unfocused',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    getIt.registerSingleton<NotesRepository>(_InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
      ),
    ]));

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    // Open the editor FAB "add" menu and pick Checklist (no focus yet).
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();

    expect(_contentText(tester), 'World\n## \n- [ ] ');

    // Saving removes the still-empty checklist (and its title line).
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(_contentText(tester), 'World');
  });

  testWidgets('an empty checklist is removed when leaving the editor',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    getIt.registerSingleton<NotesRepository>(_InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
      ),
    ]));

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();

    expect(_contentText(tester), 'World\n## \n- [ ] ');

    // Leaving cleans the empty checklist first, so the note is not dirty
    // anymore and no confirmation dialog appears.
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new).first);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('All notes'), findsOneWidget);
  });

  testWidgets('tapping the checkbox toggles without activating focus',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    getIt.registerSingleton<NotesRepository>(_InMemoryNotesRepository());

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Create a new note: the content field is auto-focused.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));

    // Insert a checklist through the editor FAB (collapsed in add mode).
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();

    expect(_contentText(tester), '## \n- [ ] ');

    // Fill the item so it survives the focus-loss cleanup.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '## \n- [ ] Item',
        selection: TextSelection.collapsed(offset: 14),
      ),
    );
    await tester.pump();

    // Close the keyboard first: the field must not regain focus on toggle.
    tester
        .widget<TextField>(find.byType(TextField).last)
        .focusNode!
        .unfocus();
    await tester.pump();

    // Tap the checkbox icon (second line, past the 16px item indent).
    final Offset topLeft = tester.getTopLeft(find.byType(TextField).last);
    await tester.tapAt(topLeft + const Offset(20, 43));
    await tester.pumpAndSettle();

    final TextField field =
        tester.widget<TextField>(find.byType(TextField).last);
    expect(field.controller!.text, '## \n- [x] Item');
    expect(field.focusNode!.hasFocus, isFalse,
        reason: 'toggling a checkbox should not activate focus');
  });

  testWidgets('tapping the drag handle places the caret in the title',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    getIt.registerSingleton<NotesRepository>(_InMemoryNotesRepository());

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Create a new note and insert a checklist.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checklist'));
    await tester.pumpAndSettle();

    expect(_contentText(tester), '## \n- [ ] ');

    // Tap the drag handle (first line, flush left): no popup, the caret
    // moves to the end of the title text, typed inline next to the icon.
    final Offset topLeft = tester.getTopLeft(find.byType(TextField).last);
    await tester.tapAt(topLeft + const Offset(4, 9));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    final TextField field =
        tester.widget<TextField>(find.byType(TextField).last);
    expect(field.controller!.selection.baseOffset, 3);

    // The title is typed inline, right next to the icon.
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '## Mon titre\n- [ ] ',
        selection: TextSelection.collapsed(offset: 12),
      ),
    );
    await tester.pump();

    expect(_contentText(tester), '## Mon titre\n- [ ] ');
  });

  testWidgets('shows the attachments zone and counters for attached files',
      (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    getIt.registerSingleton<NotesRepository>(_InMemoryNotesRepository(<Note>[
      Note(
        id: '1',
        title: 'Hello',
        content: 'World',
        date: '2026-08-12 10:00:00.000',
        attachments: <String>['doc.pdf', 'fichier.txt'],
      ),
    ]));

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    // The attachments zone title and rows.
    expect(find.text('Attachments'), findsOneWidget);
    expect(find.text('doc.pdf'), findsOneWidget);
    expect(find.text('fichier.txt'), findsOneWidget);
    expect(find.byIcon(Icons.insert_drive_file), findsNWidgets(2));

    // The info-line counter shows the attachment count (last position).
    expect(find.text('x2'), findsOneWidget);
  });
}
