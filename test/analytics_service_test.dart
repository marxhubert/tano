import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/core/services/analytics_service.dart';
import 'package:tano/shared/config/secure_preferences.dart';

class TestAnalyticsService extends AnalyticsService {
  bool gatherDataCalled = false;

  @override
  Future<Map<String, dynamic>> gatherData() async {
    gatherDataCalled = true;
    return {
      'brand': 'TestBrand',
      'model': 'TestModel',
      'os': 'TestOS',
      'os_version': '1.0',
      'country': 'US',
      'language': 'en',
      'screen_size': '1080x1920',
      'pixel_ratio': '3.0',
      'app_version': '1.0.0',
      'app_build': '1',
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

void main() {
  group('AnalyticsService', () {
    const String prefKey = 'firstLaunchAnalyticsSent';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('collectFirstLaunchInfo calls gatherData and sets the flag on first run', () async {
      final service = TestAnalyticsService();
      final prefs = await SecurePreferences.getInstance();
      
      expect(prefs.getBool(prefKey), isNull);
      expect(service.gatherDataCalled, isFalse);

      await service.collectFirstLaunchInfo();

      // A fresh read reflects what the service persisted.
      final reread = await SecurePreferences.getInstance();
      expect(reread.getBool(prefKey), isTrue);
      expect(service.gatherDataCalled, isTrue);
    });

    test('collectFirstLaunchInfo does not call gatherData if already sent', () async {
      final service = TestAnalyticsService();
      final prefs = await SecurePreferences.getInstance();
      await prefs.setBool(prefKey, true);

      await service.collectFirstLaunchInfo();

      expect(prefs.getBool(prefKey), isTrue);
      expect(service.gatherDataCalled, isFalse);
    });
  });
}
