import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/cover_image.dart';
import 'package:tano/shared/widgets/manageable_cover.dart';

Widget _host(Future<void> Function() onRemove) {
  return MaterialApp(
    home: Scaffold(
      body: ManageableCover(
        name: 'missing.png',
        height: 160.0,
        onRemove: onRemove,
      ),
    ),
  );
}

void main() {
  testWidgets('long press reveals the remove button, confirming removes',
      (tester) async {
    bool removed = false;
    await tester.pumpWidget(_host(() async => removed = true));
    await tester.pumpAndSettle();

    // Hidden until the user long-presses the cover.
    expect(find.byIcon(Icons.cancel), findsNothing);

    await tester.longPress(find.byType(CoverImage));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.cancel), findsOneWidget);

    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(removed, isFalse);

    await tester.tap(find.text(AppText.tr('delete').toUpperCase()));
    await tester.pumpAndSettle();
    expect(removed, isTrue);
  });
}
