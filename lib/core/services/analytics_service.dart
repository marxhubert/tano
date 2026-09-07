import 'dart:io';
import 'dart:ui';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  AnalyticsService();
  static final AnalyticsService instance = AnalyticsService();

  static const String _prefKey = 'firstLaunchAnalyticsSent';

  /// Collects non-private device and app information on the very first launch.
  Future<void> collectFirstLaunchInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Check if we already collected this info
    if (prefs.getBool(_prefKey) ?? false) {
      return;
    }

    try {
      final Map<String, dynamic> data = await gatherData();
      
      // LOG for development/debug
      debugPrint('Analytics: Collecting first launch info: $data');

      // TODO: In the future, send this data to a secure backend or a service like Sentry/Firebase
      // For now, we just mark it as collected.
      
      await prefs.setBool(_prefKey, true);
    } catch (e) {
      debugPrint('Analytics: Failed to collect info: $e');
    }
  }

  @visibleForTesting
  Future<Map<String, dynamic>> gatherData() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    
    String brand = 'Unknown';
    String model = 'Unknown';
    String os = 'Unknown';
    String osVersion = 'Unknown';

    if (kIsWeb) {
      os = 'Web';
      final webInfo = await deviceInfo.webBrowserInfo;
      brand = webInfo.browserName.name;
      model = webInfo.userAgent ?? 'Unknown';
    } else if (Platform.isAndroid) {
      os = 'Android';
      final androidInfo = await deviceInfo.androidInfo;
      brand = androidInfo.brand;
      model = androidInfo.model;
      osVersion = androidInfo.version.release;
    } else if (Platform.isIOS) {
      os = 'iOS';
      final iosInfo = await deviceInfo.iosInfo;
      brand = 'Apple';
      model = iosInfo.utsname.machine;
      osVersion = iosInfo.systemVersion;
    } else if (Platform.isMacOS) {
      os = 'macOS';
      final macInfo = await deviceInfo.macOsInfo;
      brand = 'Apple';
      model = macInfo.model;
      osVersion = macInfo.osRelease;
    }

    // Locale/Country
    final Locale locale = PlatformDispatcher.instance.locale;
    final String country = locale.countryCode ?? 'Unknown';
    final String language = locale.languageCode;

    // Screen Size & Density
    double width = 0;
    double height = 0;
    double pixelRatio = 1.0;

    if (PlatformDispatcher.instance.views.isNotEmpty) {
      final FlutterView window = PlatformDispatcher.instance.views.first;
      pixelRatio = window.devicePixelRatio;
      width = window.physicalSize.width / pixelRatio;
      height = window.physicalSize.height / pixelRatio;
    }

    return {
      'brand': brand,
      'model': model,
      'os': os,
      'os_version': osVersion,
      'country': country,
      'language': language,
      'screen_size': '${width.toStringAsFixed(0)}x${height.toStringAsFixed(0)}',
      'pixel_ratio': pixelRatio.toStringAsFixed(2),
      'app_version': packageInfo.version,
      'app_build': packageInfo.buildNumber,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
