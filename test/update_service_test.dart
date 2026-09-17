import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tano/core/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.marxhubert.tanonote',
      version: '0.8.4-beta',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  group('version comparison', () {
    test('compares field by field, not as text', () {
      expect(UpdateService.isNewerVersion('1.10.0', '1.9.9'), isTrue);
      expect(UpdateService.isNewerVersion('0.9.0', '0.10.0'), isFalse);
      expect(UpdateService.isNewerVersion('0.8.4', '0.8.4'), isFalse);
      expect(UpdateService.isNewerVersion('0.8.5', '0.8.4'), isTrue);
      expect(UpdateService.isNewerVersion('1.0', '0.9.9'), isTrue);
      expect(UpdateService.isNewerVersion('0.8.4.1', '0.8.4'), isTrue);
    });

    test('a pre-release ranks below the release it prepares', () {
      expect(UpdateService.isNewerVersion('0.8.4', '0.8.4-beta'), isTrue);
      expect(UpdateService.isNewerVersion('0.8.4-beta', '0.8.4'), isFalse);
      expect(UpdateService.isNewerVersion('0.9.0-beta', '0.8.4'), isTrue);
    });

    test('anything unreadable is never newer', () {
      expect(UpdateService.isNewerVersion('', '0.8.4'), isFalse);
      expect(UpdateService.isNewerVersion('latest', '0.8.4'), isFalse);
      expect(UpdateService.isNewerVersion('0.9.0', 'nonsense'), isFalse);
    });
  });

  group('the App Store check', () {
    test('offers the newer version the store publishes', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      Uri? asked;
      final UpdateService service = UpdateService(
        fetch: (Uri url) async {
          asked = url;
          return <String, dynamic>{
            'resultCount': 1,
            'results': <Object?>[
              <String, Object?>{
                'version': '0.9.0',
                'trackViewUrl': 'https://apps.apple.com/app/id123',
              },
            ],
          };
        },
      );

      final AppUpdate update = await service.check(force: true);

      expect(update.status, UpdateStatus.available);
      expect(update.version, '0.9.0');
      expect(update.storeUrl.toString(), 'https://apps.apple.com/app/id123');
      // The lookup carries the name of the app and nothing else.
      expect(asked!.host, 'itunes.apple.com');
      expect(asked!.queryParameters, <String, String>{
        'bundleId': 'com.marxhubert.tanonote',
      });
    });

    test('says up to date when the store is not ahead', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final UpdateService service = UpdateService(
        fetch: (Uri url) async => <String, dynamic>{
          'resultCount': 1,
          'results': <Object?>[
            <String, Object?>{'version': '0.8.4-beta'},
          ],
        },
      );

      final AppUpdate update = await service.check(force: true);
      expect(update.status, UpdateStatus.upToDate);
      expect(update.isAvailable, isFalse);
    });

    test('stays unknown while the app is not published', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final UpdateService service = UpdateService(
        fetch: (Uri url) async => <String, dynamic>{
          'resultCount': 0,
          'results': <Object?>[],
        },
      );

      expect((await service.check(force: true)).status, UpdateStatus.unknown);
    });

    test('stays unknown when the network is down', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final UpdateService service = UpdateService(
        fetch: (Uri url) async => throw StateError('offline'),
      );

      final AppUpdate update = await service.check(force: true);
      expect(update.status, UpdateStatus.unknown);
      expect(update.isAvailable, isFalse);
    });

    test('an unknown platform is never asked', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      final UpdateService service = UpdateService(
        fetch: (Uri url) async => throw StateError('must not be called'),
      );

      expect((await service.check(force: true)).status, UpdateStatus.unknown);
    });
  });
}
