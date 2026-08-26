import 'package:flutter/material.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/features/splash/splash_page.dart';
import 'package:tano/features/settings/settings_page.dart';
import 'package:tano/features/trash/trash_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/config/language_references_controller.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  await Future.wait([
    LocaleController.instance.init(),
    ThemeController.instance.init(),
    LanguageReferencesController.instance.init(),
  ]);
  runApp(const Tano());
}

class Tano extends StatelessWidget {
  const Tano({
    super.key,
    this.themeMode,
  });

  /// How the light/dark themes are selected. Exposed so tests can pin a
  /// brightness instead of relying on the host platform.
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance,
        LocaleController.instance,
      ]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TanoNote',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: tanoTeal,
              primary: tanoTeal,
              secondary: tanoAmber,
              surface: lightBackground,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: lightBackground,
            canvasColor: lightBackground,
            appBarTheme: const AppBarTheme(
              backgroundColor: lightBackground,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: tanoTeal,
              brightness: Brightness.dark,
              primary: tanoTeal,
              secondary: tanoAmberDark,
              surface: darkBackground,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: darkBackground,
            canvasColor: darkBackground,
            appBarTheme: const AppBarTheme(
              backgroundColor: darkBackground,
              elevation: 0,
            ),
          ),
          themeMode: themeMode ?? ThemeController.instance.themeMode,
          home: const SplashScreen(),
          routes: <String, WidgetBuilder>{
            '/home': (BuildContext context) => const Home(),
            '/settings': (BuildContext context) => const SettingsPage(),
            '/trash': (BuildContext context) => const TrashPage(),
          },
        );
      },
    );
  }
}
