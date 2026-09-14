import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/confirm.dart';

Widget _host(void Function(BuildContext context) onPressed) {
  return MaterialApp(
    home: Builder(
      builder: (BuildContext context) => ElevatedButton(
        onPressed: () => onPressed(context),
        child: const Text('open'),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester, void Function(BuildContext) onPressed) async {
  await tester.pumpWidget(_host(onPressed));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('showAdaptivePrompt returns the typed text', (tester) async {
    String? result;
    await _open(tester, (BuildContext context) async {
      result = await showAdaptivePrompt(
        context: context,
        title: 'Name',
        hint: 'Folder',
        maxLength: 54,
      );
    });

    await tester.enterText(find.byType(EditableText), 'Perso');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(result, 'Perso');
  });

  testWidgets('showAdaptivePrompt returns null when cancelled', (tester) async {
    String? result = 'untouched';
    await _open(tester, (BuildContext context) async {
      result = await showAdaptivePrompt(
        context: context,
        title: 'Name',
        hint: 'Folder',
      );
    });

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isNull);
  });

  testWidgets('showAdaptivePrompt is a Cupertino dialog on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await _open(tester, (BuildContext context) async {
        await showAdaptivePrompt(
          context: context,
          title: 'Name',
          hint: 'Folder',
        );
      });

      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
