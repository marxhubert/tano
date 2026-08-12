import 'package:flutter/material.dart';
import 'package:tano/core/repositories/file_notes_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/features/search/search_page.dart';
import 'package:tano/features/splash/splash_page.dart';

void main() {
  runApp(Tano(repository: FileNotesRepository()));
}

class Tano extends StatelessWidget {
  const Tano({super.key, required this.repository});

  /// Composition root: the concrete [NotesRepository] used by the whole app.
  final NotesRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TanoNote',
      theme: ThemeData(
        primaryColor: Colors.blueGrey.shade50,
        canvasColor: Colors.blueGrey.shade50,
      ),
      home: SplashScreen(repository: repository),
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => Home(repository: repository),
        '/search': (BuildContext context) => SearchPage(repository: repository),
      },
    );
  }
}
