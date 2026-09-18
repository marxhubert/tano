import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tano/shared/widgets/privacy_guard.dart';

void main() {
  void transition(WidgetsBinding binding, AppLifecycleState target) {
    const order = [
      AppLifecycleState.resumed,
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ];
    var index = order.indexOf(
      binding.lifecycleState ?? AppLifecycleState.resumed,
    );
    if (index < 0) {
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      index = 0;
    }
    final end = order.indexOf(target);
    while (index != end) {
      index += end > index ? 1 : -1;
      binding.handleAppLifecycleStateChanged(order[index]);
    }
  }

  Future<void> lifecycle(WidgetTester tester, AppLifecycleState state) async {
    transition(tester.binding, state);
    await tester.pump();
  }

  tearDown(
    () => transition(
      TestWidgetsFlutterBinding.instance,
      AppLifecycleState.resumed,
    ),
  );

  Widget app(Future<bool> Function() authenticate, {bool protected = true}) =>
      MaterialApp(
        builder: (context, child) =>
            PrivacyGuard(authenticate: authenticate, child: child!),
        home: ProtectedContent(
          protected: protected,
          child: const Scaffold(body: TextField(key: ValueKey('draft'))),
        ),
      );

  testWidgets(
    'a protected draft survives background and denied authentication',
    (tester) async {
      var allowed = false;
      var calls = 0;
      await tester.pumpWidget(
        app(() async {
          calls++;
          return allowed;
        }),
      );
      await tester.enterText(
        find.byKey(const ValueKey('draft')),
        'unsaved private draft',
      );
      await lifecycle(tester, AppLifecycleState.inactive);
      expect(find.byKey(const ValueKey('draft')), findsNothing);
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      expect(find.byKey(const ValueKey('draft')), findsNothing);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byKey(const ValueKey('draft')), findsNothing);
      allowed = true;
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
      expect(find.text('unsaved private draft'), findsOneWidget);
    },
  );

  testWidgets(
    'inactive alone masks content without invalidating a credential prompt',
    (tester) async {
      await tester.pumpWidget(
        app(() async => throw StateError('unexpected prompt')),
      );
      await lifecycle(tester, AppLifecycleState.inactive);
      expect(find.byKey(const ValueKey('draft')), findsNothing);
      await lifecycle(tester, AppLifecycleState.resumed);
      expect(find.byKey(const ValueKey('draft')), findsOneWidget);
    },
  );

  testWidgets('unprotected screens resume without a credential', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(() async => throw StateError('unexpected prompt'), protected: false),
    );
    await lifecycle(tester, AppLifecycleState.paused);
    await lifecycle(tester, AppLifecycleState.resumed);
    expect(find.byKey(const ValueKey('draft')), findsOneWidget);
  });

  testWidgets(
    'a result received while backgrounded cannot unlock the next resume',
    (tester) async {
      final result = Completer<bool>();
      await tester.pumpWidget(app(() => result.future));
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await lifecycle(tester, AppLifecycleState.paused);
      result.complete(true);
      await tester.pump();
      await lifecycle(tester, AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('draft')), findsNothing);
    },
  );
  testWidgets('system back cannot dismiss a protected route while covered', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (context, child) =>
            PrivacyGuard(authenticate: () async => true, child: child!),
        home: const Scaffold(body: Text('Home')),
      ),
    );
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const ProtectedContent(
          protected: true,
          child: Scaffold(body: Text('Protected route')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await lifecycle(tester, AppLifecycleState.paused);
    await lifecycle(tester, AppLifecycleState.resumed);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Protected route'), findsOneWidget);
  });

  testWidgets(
    'a system credential activity may background then return with fresh success',
    (tester) async {
      final result = Completer<bool>();
      await tester.pumpWidget(app(() => result.future));
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      result.complete(true);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('draft')), findsOneWidget);
    },
  );
}
