import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tano/main.dart';
import 'package:tano/pages/home.dart';
import 'package:tano/pages/splash.dart';

class _FakePathProvider extends PathProviderPlatform {
  final Directory directory;

  _FakePathProvider(this.directory);

  @override
  Future<String?> getApplicationDocumentsPath() async => directory.path;

  @override
  Future<String?> getApplicationSupportPath() async => directory.path;
}

void main() {
  late Directory tempDir;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'tano',
      packageName: 'com.shikamarx.tano',
      version: '0.8.4',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tano_test');
    PathProviderPlatform.instance = _FakePathProvider(tempDir);
  });

  tearDownAll(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('le splash affiche le logo puis navigue vers l\'accueil', (tester) async {
    await tester.pumpWidget(const Tano());

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(Home), findsOneWidget);
  });
}
