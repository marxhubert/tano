import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/widgets/storage_recovery.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await LocaleController.instance.init();
  });

  Widget harness(Future<bool> Function(BuildContext context) run) => MaterialApp(
    home: Builder(
      builder: (BuildContext context) => TextButton(
        onPressed: () => run(context),
        child: const Text('go'),
      ),
    ),
  );

  testWidgets('a completed write reports success and shows nothing', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      harness((BuildContext context) async {
        result = await runStorageOperation(context, () async {});
        return true;
      }),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.text(AppText.tr('storage_recovery_message')), findsNothing);
  });

  testWidgets('a failed write reports the data-preserving message', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      harness((BuildContext context) async {
        result = await runStorageOperation(context, () async {
          throw StateError('disk full');
        });
        return true;
      }),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text(AppText.tr('storage_recovery_message')), findsOneWidget);
    await tester.tap(find.text(AppText.tr('ok').toUpperCase()));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
