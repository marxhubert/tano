import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/features/splash/startup_gate.dart';

void main() {
  testWidgets(
    'startup retries without rendering exception contents or resetting data',
    (tester) async {
      var attempts = 0;
      final pending = Completer<void>();
      await tester.pumpWidget(
        StartupGate(
          initialize: () async {
            attempts++;
            if (attempts == 1) {
              throw StateError('private database path and note contents');
            }
            await pending.future;
          },
          child: const MaterialApp(home: Text('Application ready')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('private database'), findsNothing);
      expect(find.text('Application ready'), findsNothing);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      expect(attempts, 2);
      expect(find.byType(FilledButton), findsNothing);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text('Application ready'), findsOneWidget);
    },
  );
}
