import 'package:tano/shared/widgets/fab/app_fab.dart';
import 'package:tano/core/services/auth_service.dart';
import 'package:tano/core/models/task.dart';
import 'package:tano/features/editor/task_list_editor.dart';
import 'package:tano/shared/widgets/entity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/main.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/config/theme_controller.dart';

/// In-memory [NotesRepository] so the test never touches the disk.
class _InMemoryNotesRepository implements NotesRepository {
  _InMemoryNotesRepository([List<Note>? notes]) : notes = notes ?? <Note>[];

  final List<Note> notes;
  bool failWrites = false;

  @override
  Future<List<Note>> loadNotes() async =>
      notes.where((n) => !n.isDeleted).toList();

  @override
  Future<List<Note>> loadTrashNotes() async =>
      notes.where((n) => n.isDeleted).toList();

  @override
  Future<void> upsertNote(Note note) async {
    if (failWrites) throw StateError('private SQL error containing note data');
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
      notes[index] = notes[index].copyWith(isDeleted: false, deletedAt: null);
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
        .where(
          (n) =>
              !n.isDeleted &&
              (n.title.toLowerCase().contains(query.toLowerCase()) ||
                  n.content.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
  }

  @override
  Future<void> deleteAllNotes() async {
    notes.clear();
  }
}

class _DeniedAuth extends AuthService {
  int attempts = 0;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> authenticate({String? reason}) async {
    attempts++;
    return false;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocaleController.instance.init();
    await ThemeController.instance.init();
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.marxhubert.tanonote',
      version: '0.8.4',
      buildNumber: '1',
      buildSignature: '',
    );
    if (getIt.isRegistered<NotesRepository>()) {
      await getIt.unregister<NotesRepository>();
    }
  });

  testWidgets(
    'home creates and reopens a free task list through the third FAB action',
    (tester) async {
      final repository = _InMemoryNotesRepository();
      getIt.registerSingleton<NotesRepository>(repository);
      await tester.pumpWidget(const Tano());
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppText.tr('add')).last);
      await tester.pumpAndSettle();
      final taskButton = find.byIcon(Symbols.format_list_bulleted_add);
      expect(taskButton, findsOneWidget);
      expect(
        tester.getCenter(taskButton).dx,
        greaterThan(tester.getCenter(find.byIcon(Symbols.add_notes)).dx),
      );
      await tester.tap(taskButton);
      await tester.pumpAndSettle();
      expect(find.byType(TaskListEditor), findsOneWidget);
      final fields = find.descendant(
        of: find.byType(TaskListEditor),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.first, 'Milk\nBread');
      await tester.pumpAndSettle();
      expect(find.text('2 ${AppText.tr('tasks')}'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Symbols.undo));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('completed-task-divider')),
        findsNothing,
      );
      await tester.tap(find.byIcon(Symbols.redo));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('completed-task-divider')),
        findsOneWidget,
      );
      await tester.tap(find.byIcon(Symbols.save));
      await tester.pumpAndSettle();
      expect(repository.notes.single.isTask, isTrue);
      expect(repository.notes.single.content, '- [x] Milk\n- [ ] Bread');
      await tester.pageBack();
      await tester.pumpAndSettle();
      final card = tester.widget<EntityCard>(find.byType(EntityCard));
      expect(card.kind, EntityKind.task);
      await tester.tap(find.text('Milk').first);
      await tester.pumpAndSettle();
      expect(find.byType(TaskListEditor), findsOneWidget);
      expect(
        find.byKey(const ValueKey('completed-task-divider')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'task description menu, undo and persistence leave item counts unchanged',
    (tester) async {
      final repository = _InMemoryNotesRepository([
        Task(id: 'list', title: 'Errands', content: '- [ ] Milk'),
      ]);
      getIt.registerSingleton<NotesRepository>(repository);
      await tester.pumpWidget(const Tano());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Errands'));
      await tester.pumpAndSettle();
      if (find.byIcon(Symbols.add_circle).evaluate().isEmpty) {
        await tester.tap(find.byIcon(Symbols.more_horiz));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byIcon(Symbols.add_circle));
      await tester.pumpAndSettle();
      expect(find.text(AppText.tr('option_checklist')), findsNothing);
      expect(find.text(AppText.tr('option_attachment')), findsNothing);
      await tester.tap(find.text(AppText.tr('add_description')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('task-description')),
        'Before the weekend',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 ${AppText.tr('tasks')}'), findsOneWidget);
      await tester.tap(find.byIcon(Symbols.undo));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('task-description')), findsNothing);
      await tester.tap(find.byIcon(Symbols.redo));
      await tester.pumpAndSettle();
      expect(find.text('Before the weekend'), findsOneWidget);
      await tester.tap(find.byIcon(Symbols.save));
      await tester.pumpAndSettle();
      expect(repository.notes.single.description, 'Before the weekend');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Errands'));
      await tester.pumpAndSettle();
      expect(find.text('Before the weekend'), findsOneWidget);
    },
  );

  testWidgets(
    'link a locked note inserts at the row cursor and opening it requires authentication',
    (tester) async {
      final repository = _InMemoryNotesRepository([
        Task(id: 'list', title: 'Errands', content: '- [ ] Milk'),
        Note(
          id: 'private',
          title: 'Private note',
          content: 'Secret body',
          isLocked: true,
        ),
      ]);
      final auth = _DeniedAuth();
      if (getIt.isRegistered<AuthService>()) {
        await getIt.unregister<AuthService>();
      }
      getIt.registerSingleton<AuthService>(auth);
      addTearDown(() => getIt.unregister<AuthService>());
      getIt.registerSingleton<NotesRepository>(repository);
      await tester.pumpWidget(const Tano());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Errands'));
      await tester.pumpAndSettle();
      final rowFinder = find
          .descendant(
            of: find.byType(TaskListEditor),
            matching: find.byType(TextField),
          )
          .first;
      await tester.tap(rowFinder);
      await tester.pumpAndSettle();
      tester.widget<TextField>(rowFinder).controller!.selection =
          const TextSelection.collapsed(offset: 2);
      if (find.byIcon(Symbols.add_circle).evaluate().isEmpty) {
        await tester.tap(find.byIcon(Symbols.more_horiz));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byIcon(Symbols.add_circle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppText.tr('option_link')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Private note').last);
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(TaskListEditor),
        matching: find.byType(TextField),
      );
      expect(fields, findsOneWidget);
      final linked = tester.widget<TextField>(fields.last);
      expect(linked.controller!.text, 'Mi[[private:Private note]]lk');
      linked.controller!.selection = const TextSelection.collapsed(offset: 5);
      linked.onTap!();
      await tester.pumpAndSettle();
      expect(auth.attempts, 1);
      expect(find.text('Secret body'), findsNothing);
      expect(find.byType(TaskListEditor), findsOneWidget);
    },
  );

  testWidgets(
    'description links use the cursor and input stops at 500 characters',
    (tester) async {
      final repository = _InMemoryNotesRepository([
        Task(
          id: 'list',
          title: 'Errands',
          description: 'Before after',
          content:
              '- [ ] [[reference:Reference]]\n- [ ] [[reference:Reference]]',
        ),
        Note(id: 'reference', title: 'Reference', content: 'Body'),
      ]);
      getIt.registerSingleton<NotesRepository>(repository);
      await tester.pumpWidget(const Tano());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Errands'));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('task-description'));
      await tester.tap(field);
      await tester.pumpAndSettle();
      final controller = tester.widget<TextField>(field).controller!;
      controller.selection = const TextSelection.collapsed(offset: 7);
      if (find.byIcon(Symbols.add_circle).evaluate().isEmpty) {
        await tester.tap(find.byIcon(Symbols.more_horiz));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byIcon(Symbols.add_circle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppText.tr('option_link')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reference').last);
      await tester.pumpAndSettle();
      expect(controller.text, 'Before [[reference:Reference]]after');
      expect(find.text('x3'), findsOneWidget);
      await tester.enterText(field, 'x' * 501);
      await tester.pumpAndSettle();
      expect(controller.text.length, 500);
    },
  );

  testWidgets('expanded Task FAB centers the active row above the keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _InMemoryNotesRepository([
      Task(
        id: 'long',
        title: 'Long list',
        content: List.generate(16, (i) => '- [ ] Item $i').join('\n'),
      ),
      ...List.generate(
        20,
        (i) => Note(id: 'ref$i', title: 'Reference $i', content: 'Body'),
      ),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);
    await tester.pumpWidget(const Tano());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Long list'));
    await tester.pumpAndSettle();
    final field = find
        .descendant(
          of: find.byType(TaskListEditor),
          matching: find.byType(TextField),
        )
        .last;
    final widget = tester.widget<TextField>(field);
    widget.focusNode!.requestFocus();
    widget.controller!.selection = TextSelection.collapsed(
      offset: widget.controller!.text.length,
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.more_horiz));
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    final editable = tester
        .state<EditableTextState>(
          find.descendant(of: field, matching: find.byType(EditableText)),
        )
        .renderEditable;
    final caret = editable.localToGlobal(
      editable.getLocalRectForCaret(editable.selection!.extent).center,
    );
    final fabTop = tester.getTopLeft(find.byType(AppFab)).dy;
    expect(caret.dy, closeTo((kToolbarHeight + fabTop) / 2, 28));
    expect(widget.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.byIcon(Symbols.add_circle));
    await tester.pump();
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    final menuCaret = editable.localToGlobal(
      editable.getLocalRectForCaret(editable.selection!.extent).center,
    );
    final menuTop = tester.getTopLeft(find.byType(AppFab)).dy;
    expect(menuCaret.dy, closeTo((kToolbarHeight + menuTop) / 2, 28));
    await tester.tap(find.text(AppText.tr('option_link')));
    await tester.pumpAndSettle();
    final menuBounds = tester.getRect(find.byType(AppFab));
    expect(menuBounds.top, greaterThanOrEqualTo(kToolbarHeight));
    expect(menuBounds.bottom, lessThanOrEqualTo(844 - 260));
    expect(widget.focusNode!.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    tester.widget<AppFab>(find.byType(AppFab)).onFindSelected!();
    await tester.pump();
    final search = find.descendant(
      of: find.byType(AppFab),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'Item 1');
    await tester.pump(const Duration(milliseconds: 400));
    tester.widget<AppFab>(find.byType(AppFab)).onFindPrev!();
    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    final found = editable.localToGlobal(
      editable.getRectForComposingRange(editable.selection!)!.center,
    );
    final searchTop = tester.getTopLeft(find.byType(AppFab)).dy;
    expect(found.dy, closeTo((kToolbarHeight + searchTop) / 2, 28));
    expect(tester.widget<TextField>(search).focusNode!.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('new task row centers with the keyboard and collapsed FAB', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _InMemoryNotesRepository([
      Task(
        id: 'long',
        title: 'Long list',
        content: List.generate(16, (i) => '- [ ] Item $i').join('\n'),
      ),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);
    await tester.pumpWidget(const Tano());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Long list'));
    await tester.pumpAndSettle();
    final last = find
        .descendant(
          of: find.byType(TaskListEditor),
          matching: find.byType(TextField),
        )
        .last;
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.enterText(last, 'Item 15\n');
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(tester.widget<TextField>(last).controller!.text, '');
    expect(tester.widget<TextField>(last).focusNode!.hasFocus, isTrue);
    final editable = tester
        .state<EditableTextState>(
          find.descendant(of: last, matching: find.byType(EditableText)),
        )
        .renderEditable;
    final caret = editable.localToGlobal(
      editable.getLocalRectForCaret(editable.selection!.extent).center,
    );
    final fabTop = tester.getTopLeft(find.byType(AppFab)).dy;
    expect(caret.dy, closeTo((kToolbarHeight + fabTop) / 2, 28));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('failed save keeps the draft open and retry succeeds', (
    tester,
  ) async {
    final repository = _InMemoryNotesRepository([
      Note(id: 'retry', title: 'Original', content: 'Body'),
    ]);
    getIt.registerSingleton<NotesRepository>(repository);
    await tester.pumpWidget(const Tano());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Original'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Unsaved draft');
    await tester.pumpAndSettle();
    repository.failWrites = true;
    await tester.tap(find.byIcon(Symbols.save));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.textContaining('private SQL'), findsNothing);
    expect(repository.notes.single.title, 'Original');
    await tester.tap(find.text('OK').last);
    await tester.pumpAndSettle();
    expect(find.text('Unsaved draft'), findsOneWidget);
    repository.failWrites = false;
    await tester.tap(find.byIcon(Symbols.save));
    await tester.pumpAndSettle();
    expect(repository.notes.single.title, 'Unsaved draft');
  });

  testWidgets('home reflects edits saved through the back button', (
    tester,
  ) async {
    final repository = _InMemoryNotesRepository(<Note>[
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

    expect(find.byType(Home), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);

    // Open the note editor.
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(2));

    // Modify the title.
    await tester.enterText(find.byType(TextField).first, 'Hello updated');
    await tester.pumpAndSettle();

    // Back -> "Save before leaving" dialog -> Save.
    await tester.tap(find.byIcon(Symbols.arrow_back_ios_new).first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('SAVE').last);
    await tester.pumpAndSettle();

    // Home must reflect the persisted edit without reopening Settings.
    expect(find.byType(Home), findsOneWidget);
    expect(find.text('Hello updated'), findsOneWidget);
    expect(find.text('Hello'), findsNothing);
    expect(repository.notes.first.title, 'Hello updated');
  });

  testWidgets('app bar save persists in place without leaving the editor', (
    tester,
  ) async {
    final repository = _InMemoryNotesRepository();
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    // Create a note from the home FAB.
    await tester.tap(find.byIcon(Symbols.add_2));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.add_notes));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Fresh note');
    await tester.pumpAndSettle();

    expect(find.byIcon(Symbols.save), findsOneWidget);

    await tester.tap(find.byIcon(Symbols.save));
    await tester.pumpAndSettle();

    // The save happens in place: the note is persisted but the editor stays.
    expect(find.byType(Home), findsNothing);
    expect(repository.notes, hasLength(1));
    expect(repository.notes.single.title, 'Fresh note');

    // Going back then reveals the note on home without any extra prompt.
    await tester.tap(find.byIcon(Symbols.arrow_back_ios_new).first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Home), findsOneWidget);
    expect(find.text('Fresh note'), findsOneWidget);
  });

  testWidgets('saving an untitled note settles the dirty state', (
    tester,
  ) async {
    final repository = _InMemoryNotesRepository();
    getIt.registerSingleton<NotesRepository>(repository);

    await tester.pumpWidget(const Tano());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.add_2));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Symbols.add_notes));
    await tester.pumpAndSettle();

    // Type only in the body: the title is derived from it when saving.
    await tester.enterText(find.byType(TextField).last, 'Body only');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Symbols.save));
    await tester.pumpAndSettle();

    expect(repository.notes, hasLength(1));

    // The save action is now disabled: there is nothing left to save.
    final IconButton saveButton = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Symbols.save),
        matching: find.byType(IconButton),
      ),
    );
    expect(saveButton.onPressed, isNull);

    // Leaving must not prompt, and home must show the saved note.
    await tester.tap(find.byIcon(Symbols.arrow_back_ios_new).first);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Home), findsOneWidget);
    expect(find.text('Body only'), findsWidgets);
  });
}
