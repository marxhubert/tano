import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Analytics Integration Test', () {
    testWidgets('Verify that analytics flag is set after first launch', (WidgetTester tester) async {
      // 1. Ensure clean state
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 2. Start the app
      app.main();
      await tester.pumpAndSettle();

      // 3. Wait for the analytics logic (it happens in main before runApp or just after)
      // Since it's awaited in main, it should be done by the time pumpAndSettle finishes.
      
      // 4. Verify SharedPreferences flag
      expect(prefs.getBool('firstLaunchAnalyticsSent'), isTrue);
    });
  });
}
