import 'package:flutter/material.dart';
import 'package:tano/core/repositories/file_notes_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/features/search/search_page.dart';
import 'package:tano/features/splash/splash_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    LocaleController.instance.init(),
    ThemeController.instance.init(),
  ]);
  runApp(Tano(repository: FileNotesRepository()));
}

class Tano extends StatelessWidget {
  const Tano({
    super.key,
    required this.repository,
    this.themeMode,
  });

  /// Composition root: the concrete [NotesRepository] used by the whole app.
  final NotesRepository repository;

  /// How the light/dark themes are selected. Exposed so tests can pin a
  /// brightness instead of relying on the host platform.
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TanoNote',
          theme: ThemeData(
            primaryColor: Colors.blueGrey.shade50,
            canvasColor: Colors.blueGrey.shade50,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueGrey,
              brightness: Brightness.dark,
            ),
            canvasColor: Colors.blueGrey.shade900,
            scaffoldBackgroundColor: Colors.blueGrey.shade900,
          ),
          themeMode: themeMode ?? ThemeController.instance.themeMode,
          home: SplashScreen(repository: repository),
          routes: <String, WidgetBuilder>{
            '/home': (BuildContext context) => Home(repository: repository),
            '/search': (BuildContext context) => SearchPage(repository: repository),
          },
        );
      },
    );
  }
}
