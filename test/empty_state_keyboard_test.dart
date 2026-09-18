import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/empty_state.dart';
import 'package:tano/shared/widgets/page_layout.dart';

/// The empty screens show their illustration as a watermark: it must hold its
/// place when the keyboard opens, where a list has to make room for it.
void main() {
  Widget page({required bool freezeBody}) {
    return MaterialApp(
      home: PageScaffold(
        title: 'My notes',
        isHome: true,
        freezeBody: freezeBody,
        slivers: <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: Builder(
              builder: (BuildContext context) =>
                  emptyState(context, 'Nothing yet'),
            ),
          ),
        ],
      ),
    );
  }

  testWidgets('the illustration holds its place when the keyboard opens', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.reset);

    await tester.pumpWidget(page(freezeBody: true));
    final Offset resting = tester.getCenter(find.text('Nothing yet'));

    tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);
    await tester.pump();

    expect(tester.getCenter(find.text('Nothing yet')), resting);
  });

  testWidgets('a list still makes room for the keyboard', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.reset);

    await tester.pumpWidget(page(freezeBody: false));
    final double resting = tester.getCenter(find.text('Nothing yet')).dy;

    tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);
    await tester.pump();

    expect(tester.getCenter(find.text('Nothing yet')).dy, lessThan(resting));
  });
}
