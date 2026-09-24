import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/shared/config/document_filter_controller.dart';
import 'package:tano/shared/widgets/document_filter.dart';

void main() {
  testWidgets('a single kind fills the tab and paints its number on-accent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocumentFilterControl(
            value: DocumentFilter.all,
            onChanged: (_) {},
            // Two notes, no task: a single kind.
            countOf: (DocumentFilter filter) =>
                filter == DocumentFilter.tasks ? 0 : 2,
          ),
        ),
      ),
    );

    // The label is the only rich text: its first span is the number.
    final Text label = tester.widget<Text>(
      find.byWidgetPredicate((Widget w) => w is Text && w.textSpan != null),
    );
    final TextSpan number =
        (label.textSpan! as TextSpan).children!.first as TextSpan;
    final ColorScheme scheme = Theme.of(
      tester.element(find.byType(DocumentFilterControl)),
    ).colorScheme;

    // The lone segment is selected, so its number takes the on-accent ink, not
    // the muted one the unselected kind segments use.
    expect(number.style?.color, scheme.onPrimary.withValues(alpha: .72));
  });

  test('the remembered filter survives a reload and notifies once', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    final DocumentFilterController controller = DocumentFilterController.instance;
    int notifications = 0;
    controller.addListener(() => notifications++);

    await controller.set(DocumentFilter.tasks);
    expect(controller.filter, DocumentFilter.tasks);
    expect(notifications, 1);

    // The same value is a no-op.
    await controller.set(DocumentFilter.tasks);
    expect(notifications, 1);

    await controller.load();
    expect(controller.filter, DocumentFilter.tasks);
  });
}
