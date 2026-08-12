import 'package:flutter/material.dart';
import 'package:tano/data/file_notes_repository.dart';
import 'package:tano/domain/notes_repository.dart';
import 'package:tano/pages/home.dart';
import 'package:tano/pages/search.dart';
import 'package:tano/pages/splash.dart';

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
