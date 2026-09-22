import 'package:tano/features/splash/startup_gate.dart';
import 'package:tano/shared/widgets/privacy_guard.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/repositories/attachments_store.dart';
import 'package:tano/core/services/attachment_maintenance.dart';
import 'package:flutter/material.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/features/onboarding/onboarding_page.dart';
import 'package:tano/features/splash/splash_page.dart';
import 'package:tano/features/settings/settings_page.dart';
import 'package:tano/features/lab/lab_page.dart';
import 'package:tano/features/trash/trash_page.dart';
import 'package:tano/shared/config/feedback_controller.dart';
import 'package:tano/shared/config/fab_side_controller.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/onboarding_controller.dart';
import 'package:tano/shared/config/search_history_controller.dart';
import 'package:tano/shared/config/text_scale_controller.dart';
import 'package:tano/shared/config/theme_controller.dart';
import 'package:tano/shared/config/language_references_controller.dart';
import 'package:tano/shared/config/route_observer.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';
import 'package:tano/core/services/crash_reports.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(StartupGate(initialize: initializeApplication, child: const Tano()));
}

Future<void> initializeApplication() async {
  await setupServiceLocator();
  await Future.wait([
    LocaleController.instance.init(),
    ThemeController.instance.init(),
    LanguageReferencesController.instance.init(),
    OnboardingController.instance.init(),
    TextScaleController.instance.init(),
    FeedbackController.instance.init(),
    SearchHistoryController.instance.init(),
    FabSideController.instance.load(),
  ]);

  final repository = getIt<NotesRepository>();
  await repository.loadNotes();
  if (repository is AttachmentReferenceSource) {
    await AttachmentMaintenance(
      source: repository as AttachmentReferenceSource,
      store: getIt<AttachmentsStore>(),
    ).collectAtStartup();
  }
  // No routes or diagnostics before storage and consent are available.
  if (await CrashReports.hasConsent()) await CrashReports.start();
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
          theme: tanoTheme(Brightness.light),
          darkTheme: tanoTheme(Brightness.dark),
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
              child: PrivacyGuard(child: child ?? const SizedBox.shrink()),
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
