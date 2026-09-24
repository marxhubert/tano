import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/page_layout.dart';
import 'package:tano/shared/widgets/theme.dart';

void main() {
  testWidgets('a landscape drag from the empty margin scrolls the body', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1366, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: tanoTheme(Brightness.light),
        home: PageScaffold(
          title: 'Test',
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) =>
                    SizedBox(height: 80, child: Text('Row \$index')),
                childCount: 40,
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final ScrollableState scrollable = tester.state(
      find.byType(Scrollable).first,
    );
    expect(scrollable.position.pixels, 0);

    // The 1080-wide column is centred in a 1366-wide window, so x = 20 is on
    // the empty left margin, outside the scroll view.
    await tester.dragFrom(const Offset(20, 400), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(scrollable.position.pixels, greaterThan(0));
  });
}
