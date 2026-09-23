import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/resize_curtain.dart';

void main() {
  testWidgets('a resize drops the curtain, which lifts once it settles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ResizeCurtain(child: Scaffold(body: Text('Content'))),
      ),
    );
    await tester.pumpAndSettle();

    final Finder curtain = find.byKey(
      const ValueKey<String>('resize-curtain'),
    );
    // The first layout is not a resize: nothing to hide.
    expect(curtain, findsNothing);

    // Rotating hides the stretched frame behind a flat paper curtain...
    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    expect(curtain, findsOneWidget);

    // ...and the content comes back once the size has held still.
    await tester.pumpAndSettle();
    expect(curtain, findsNothing);
    expect(find.text('Content'), findsOneWidget);
  });
}
