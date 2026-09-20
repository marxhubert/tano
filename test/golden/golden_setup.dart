import 'package:tano/shared/widgets/theme.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// The box that gets captured: wrapping the card in its own [RepaintBoundary]
/// keeps the PNG tight and identical whatever the test surface is.
const Key goldenKey = ValueKey<String>('golden');

/// Loads the real fonts, so the goldens show the design and not the test
/// fallback: without [Roboto] the text is a block, and without the Material
/// Symbols font every icon is a box.
///
/// Serif text uses the app's bundled fonts. Roboto comes from the Flutter
/// cache and Symbols from the package resolved by `flutter pub get`.
Future<void> loadGoldenFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final FontLoader loader = FontLoader(family);
    for (final String path in paths) {
      final Uint8List data = File(path).readAsBytesSync();
      loader.addFont(Future<ByteData>.value(ByteData.view(data.buffer)));
    }
    await loader.load();
  }

  final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
  if (flutterRoot != null) {
    final String fontsDir = '$flutterRoot/bin/cache/artifacts/material_fonts/';
    await load('Roboto', <String>[
      '${fontsDir}Roboto-Regular.ttf',
      '${fontsDir}Roboto-Bold.ttf',
      '${fontsDir}Roboto-Black.ttf',
    ]);
  }

  await load('TanoSerif', <String>[
    'assets/fonts/NotoSerif-Regular.ttf',
    'assets/fonts/NotoSerif-Bold.ttf',
    'assets/fonts/NotoSerif-Italic.ttf',
    'assets/fonts/NotoSerif-BoldItalic.ttf',
  ]);

  await load(
    'packages/material_symbols_icons/MaterialSymbolsOutlined',
    <String>[_symbolsFontPath()],
  );
}

/// Absolute path of the Material Symbols font, resolved from the package
/// config so it follows the version `flutter pub get` actually picked.
String _symbolsFontPath() {
  final Map<String, dynamic> config =
      jsonDecode(File('.dart_tool/package_config.json').readAsStringSync())
          as Map<String, dynamic>;
  final List<dynamic> packages = config['packages'] as List<dynamic>;
  final Map<String, dynamic> entry =
      packages.firstWhere(
            (dynamic p) =>
                (p as Map<String, dynamic>)['name'] == 'material_symbols_icons',
          )
          as Map<String, dynamic>;
  // rootUri has no trailing slash, and `resolve` on a slashless URI replaces
  // its last segment: rebuild the base explicitly.
  final String root = entry['rootUri'] as String;
  final String packageUri = entry['packageUri'] as String? ?? 'lib/';
  return Uri.parse(
    '$root/$packageUri',
  ).resolve('fonts/MaterialSymbolsOutlined.ttf').toFilePath();
}

/// Pumps [child] in the app's colours for the given [brightness], and settles
/// everything. The surface is fixed so the layout never depends on the host.
Future<void> pumpGolden(
  WidgetTester tester, {
  required Brightness brightness,
  required Widget child,
}) async {
  tester.view.physicalSize = const Size(1000.0, 700.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: tanoTheme(brightness),
      // The card's InkWell needs a Material ancestor; the capture stays tight
      // around the card, so the Scaffold never shows in the image.
      home: Scaffold(
        body: Center(
          child: RepaintBoundary(key: goldenKey, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
