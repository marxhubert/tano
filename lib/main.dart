import 'package:flutter/material.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/features/onboarding/onboarding_page.dart';
import 'package:tano/features/splash/splash_page.dart';
import 'package:tano/features/settings/settings_page.dart';
import 'package:tano/features/lab/lab_page.dart';
import 'package:tano/features/trash/trash_page.dart';
import 'package:tano/shared/config/feedback_controller.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/onboarding_controller.dart';
import 'package:tano/shared/config/text_scale_controller.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/config/language_references_controller.dart';
import 'package:tano/shared/config/route_observer.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/core/services/crash_reports.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  await Future.wait([
    LocaleController.instance.init(),
    ThemeController.instance.init(),
    LanguageReferencesController.instance.init(),
    OnboardingController.instance.init(),
    TextScaleController.instance.init(),
    FeedbackController.instance.init(),
  ]);

  // Crash reports are opt-in: without the user's consent the SDK is not even
  // initialised, and nothing leaves the device. See docs/observabilite.md.
  if (await CrashReports.hasConsent()) {
    await CrashReports.start(appRunner: () => runApp(const Tano()));
  } else {
    runApp(const Tano());
  }
}

class Tano extends StatelessWidget {
  const Tano({super.key, this.themeMode});

  /// How the light/dark themes are selected. Exposed so tests can pin a
  /// brightness instead of relying on the host platform.
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeController.instance,
        LocaleController.instance,
        TextScaleController.instance,
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
          // The chosen size multiplies the system one instead of replacing it:
          // a user who needs large text keeps their accessibility setting.
          builder: (BuildContext context, Widget? child) {
            final TextScaler system = MediaQuery.textScalerOf(context);
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  system.scale(1.0) * TextScaleController.instance.scale,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
          navigatorObservers: <NavigatorObserver>[routeObserver],
          // The introduction opens only on the very first run; after that the
          // splash screen loads the notes and hands them to the home.
          home: OnboardingController.instance.seen
              ? const SplashScreen()
              : const OnboardingPage(),
          routes: <String, WidgetBuilder>{
            '/home': (BuildContext context) => const Home(),
            '/settings': (BuildContext context) => const SettingsPage(),
            '/trash': (BuildContext context) => const TrashPage(),
            '/lab': (BuildContext context) => const LabPage(),
          },
        );
      },
    );
  }
}
