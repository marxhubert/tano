import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// One-shot generator for the native splash assets.
///
/// Replicates the design of `lib/features/splash/splash_page.dart`:
///  - black87 circle with the white `turned_in_not` bookmark (icon/circle =
///    45/90, i.e. half the diameter);
///  - the app name below, "Tano" w900 + "Note" w400 at the app's 21 dp,
///    centered in a 90 dp slot at the bottom (mirroring the
///    Column(Expanded(circle), SizedBox(height: 90, text)) of splash_page).
///
/// The source images are 4x (xxxhdpi), so dp values are multiplied by 4.
/// Run with:
///   flutter test test/generate_splash_logo_test.dart
void main() {
  testWidgets('generate native splash assets', (tester) async {
    // Widget tests do not load the real fonts by default, which would render
    // the glyphs as fallback boxes. Load them from the Flutter SDK cache.
    final String? flutterRoot = Platform.environment['FLUTTER_ROOT'];
    if (flutterRoot != null) {
      final String fontsDir =
          '$flutterRoot/bin/cache/artifacts/material_fonts/';
      Future<void> load(String family, List<String> files) async {
        final FontLoader loader = FontLoader(family);
        for (final String file in files) {
          final Uint8List data = File('$fontsDir$file').readAsBytesSync();
          loader.addFont(Future<ByteData>.value(ByteData.view(data.buffer)));
        }
        await loader.load();
      }

      await load('MaterialIcons', <String>['MaterialIcons-Regular.otf']);
      await load('Roboto', <String>[
        'Roboto-Regular.ttf',
        'Roboto-Bold.ttf',
        'Roboto-Black.ttf',
      ]);
    }

    tester.view.physicalSize = const Size(1152, 1536);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> renderAndSave(Widget child, String path) async {
      final GlobalKey boundaryKey = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(key: boundaryKey, child: child),
          ),
        ),
      );
      await tester.pump();

      // Image capture performs real async engine work that the fake-async
      // test zone cannot complete, so run it inside runAsync.
      await tester.runAsync(() async {
        final RenderRepaintBoundary boundary = boundaryKey.currentContext!
            .findRenderObject()! as RenderRepaintBoundary;
        final ui.Image image = await boundary.toImage();
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(byteData!.buffer.asUint8List());
      });
    }

    // Circle + bookmark, replicating splash_page.dart (icon/circle = 45/90).
    Widget logoCircle(double diameter) {
      return SizedBox(
        width: diameter,
        height: diameter,
        child: CircleAvatar(
          radius: diameter / 2,
          backgroundColor: Colors.black87,
          child: Icon(
            Icons.turned_in_not,
            color: Colors.white,
            size: diameter / 2,
          ),
        ),
      );
    }

    // App name "Tano" w900 + "Note" w400 at 21 dp (84 px at 4x), like the
    // RichText of splash_page.dart.
    Widget appName(double fontSize, Color color) {
      return RichText(
        text: TextSpan(
          text: 'Tano',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: color,
          ),
          children: <TextSpan>[
            TextSpan(
              text: 'Note',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: fontSize,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    // Full branding: logo and text grouped in a centered Column with an 8 dp
    // gap (32 px at 4x), matching the Center(Column(...)) of splash_page.dart.
    Widget branding({
      required double canvasWidth,
      required double canvasHeight,
      required double circleDiameter,
      required Color textColor,
    }) {
      return SizedBox(
        width: canvasWidth,
        height: canvasHeight,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              logoCircle(circleDiameter),
              const SizedBox(height: 32), // 8 dp * 4
              appName(84, textColor),
            ],
          ),
        ),
      );
    }

    // Full composite for iOS and pre-Android-12 (text included).
    // Circle at 360 px (90 dp, doubled from the previous 45 dp).
    // Text at the app's exact 21 dp.
    await renderAndSave(
      branding(
        canvasWidth: 1024,
        canvasHeight: 1536,
        circleDiameter: 360,
        textColor: Colors.black87,
      ),
      'assets/splash_logo.png',
    );
    await renderAndSave(
      branding(
        canvasWidth: 1024,
        canvasHeight: 1536,
        circleDiameter: 360,
        textColor: Colors.grey.shade300,
      ),
      'assets/splash_logo_dark.png',
    );

    // Android 12+ icon: the platform masks the image to a centered circle,
    // so only the logo circle is used (no text). Doubled to 384 px.
    await renderAndSave(
      SizedBox(
        width: 1152,
        height: 1152,
        child: Center(child: logoCircle(384)),
      ),
      'assets/splash_logo_android12.png',
    );

    // Android 12+ branding: app name at the bottom of the splash. The
    // branding image must be 800x320 px.
    Widget brandText(Color color) {
      return SizedBox(
        width: 800,
        height: 320,
        child: Center(child: appName(84, color)),
      );
    }

    await renderAndSave(brandText(Colors.black87), 'assets/splash_branding.png');
    await renderAndSave(
      brandText(Colors.grey.shade300),
      'assets/splash_branding_dark.png',
    );
  });
}
