import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/entity_layout.dart';
import 'package:tano/shared/widgets/entity_sliver.dart';

void main() {
  const layouts = <({String name, Size size, int grid, int list})>[
    (name: 'phone portrait', size: Size(390, 844), grid: 2, list: 1),
    (name: 'phone landscape', size: Size(844, 390), grid: 3, list: 2),
    (name: 'tablet portrait', size: Size(768, 1024), grid: 3, list: 2),
    (name: 'tablet landscape', size: Size(1024, 768), grid: 5, list: 4),
    (name: 'large window', size: Size(1440, 900), grid: 5, list: 5),
  ];

  for (final layout in layouts) {
    for (final isList in [false, true]) {
      testWidgets('${layout.name}: ${isList ? 'list' : 'grid'} column count', (
        tester,
      ) async {
        tester.view.physicalSize = layout.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final int columns = isList ? layout.list : layout.grid;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: EntitySliver<int>(
                      items: List.generate(columns + 1, (i) => i),
                      isList: isList,
                      cardBuilder: (context, item) => SizedBox(
                        key: ValueKey(item),
                        height: 100,
                        child: Text('$item'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final Rect first = tester.getRect(find.byKey(const ValueKey(0)));
        final Rect lastInRow = tester.getRect(
          find.byKey(ValueKey(columns - 1)),
        );
        final Rect nextRow = tester.getRect(find.byKey(ValueKey(columns)));
        expect(lastInRow.top, first.top);
        expect(lastInRow.right, closeTo(layout.size.width - 16, 0.01));
        expect(nextRow.top, closeTo(first.bottom + 8, 0.01));
        expect(nextRow.left, first.left);
        // An incomplete last row must preserve the width of the full rows.
        expect(nextRow.width, closeTo(first.width, 0.01));
        expect(tester.takeException(), isNull);
      });
    }
  }

  test(
    'tablet and wide-window breakpoints use logical viewport dimensions',
    () {
      expect(entityColumnCount(const Size(599, 900), isList: false), 2);
      expect(entityColumnCount(const Size(600, 900), isList: false), 3);
      expect(entityColumnCount(const Size(900, 599), isList: true), 2);
      expect(entityColumnCount(const Size(900, 600), isList: true), 4);
      expect(entityColumnCount(const Size(1439, 900), isList: true), 4);
      expect(entityColumnCount(const Size(1440, 900), isList: true), 5);
    },
  );
}
