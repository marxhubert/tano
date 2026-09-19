import 'package:material_symbols_icons/symbols.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/features/editor/task_list_editor.dart';
import 'package:tano/shared/widgets/link_text_controller.dart';

void main() {
  testWidgets(
    'one blank draft only; active rows reorder and completed section collapses',
    (tester) async {
      final controller = LinkTextEditingController(linkColor: Colors.orange);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TaskListEditor(
                controller: controller,
                onChanged: () {},
                onTapText: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppText.tr('add_task_item')).last);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), '\n');
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      controller.setTextForRestore(
        '- [ ] Alpha\n- [x] Done\n- [ ] Beta\n- [ ] Gamma',
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Symbols.drag_indicator), findsNWidgets(3));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Symbols.drag_indicator).first),
      );
      await tester.pump();
      await gesture.moveTo(
        tester.getBottomRight(find.byIcon(Symbols.drag_indicator).last) +
            const Offset(0, 50),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        controller.text,
        '- [ ] Beta\n- [x] Done\n- [ ] Gamma\n- [ ] Alpha',
      );
      await tester.tap(find.byKey(const ValueKey('completed-task-header')));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsNothing);
      expect(controller.text.contains('- [x] Done'), isTrue);
      await tester.tap(find.byKey(const ValueKey('completed-task-header')));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'links insert into an empty checkbox and find does not steal focus',
    (tester) async {
      final controller = LinkTextEditingController(linkColor: Colors.orange);
      final key = GlobalKey<TaskListEditorState>();
      final searchFocus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(searchFocus.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(focusNode: searchFocus),
                TaskListEditor(
                  key: key,
                  controller: controller,
                  onChanged: () {},
                  onTapText: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      key.currentState!.insertText('[[target:Linked note]] ');
      await tester.pumpAndSettle();
      expect(controller.text, '- [ ] [[target:Linked note]] ');
      final field = find.byType(TextField).last;
      await tester.enterText(field, 'Milk Bread');
      final row = tester.widget<TextField>(field).controller!;
      row.selection = const TextSelection.collapsed(offset: 5);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'Milk \nBread',
          selection: TextSelection.collapsed(offset: 6),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byType(TextField).last)
            .controller!
            .selection
            .baseOffset,
        0,
      );
      searchFocus.requestFocus();
      await tester.pumpAndSettle();
      final start = controller.text.indexOf('Bread');
      controller.selection = TextSelection(
        baseOffset: start,
        extentOffset: start + 5,
      );
      controller.setSearchHighlight('Bread', 0);
      controller.searchBlinkValue = 0.5;
      await tester.pumpAndSettle();
      expect(searchFocus.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'new task focuses first row; Enter, checking and unchecking preserve items',
    (tester) async {
      final controller = LinkTextEditingController(linkColor: Colors.orange);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TaskListEditor(
                controller: controller,
                autofocus: true,
                onChanged: () {},
                onTapText: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byType(TextField).first)
            .focusNode!
            .hasFocus,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('completed-task-divider')),
        findsNothing,
      );
      await tester.enterText(find.byType(TextField).first, 'Milk\nBread');
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNWidgets(2));
      expect(controller.text, '- [ ] Milk\n- [ ] Bread');
      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();
      expect(controller.text, '- [x] Milk\n- [ ] Bread');
      expect(
        find.byKey(const ValueKey('completed-task-divider')),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Milk')).dy,
        greaterThan(tester.getTopLeft(find.byType(Divider)).dy),
      );
      expect(
        tester.getTopLeft(find.text('Bread')).dy,
        lessThan(tester.getTopLeft(find.byType(Divider)).dy),
      );
      await tester.tap(find.byType(Checkbox).last);
      await tester.pumpAndSettle();
      expect(find.byType(Divider), findsNothing);
      expect(controller.text, '- [ ] Milk\n- [ ] Bread');
      // Undo/redo and other document operations replace the shared controller.
      controller.setTextForRestore('- [x] Restored');
      await tester.pumpAndSettle();
      expect(find.text('Restored'), findsOneWidget);
      expect(find.text('Milk'), findsNothing);
      expect(find.byType(Divider), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
