import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tano/shared/config/app_config.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.repository});

  final NotesRepository repository;

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load locale data
      await LocaleController.instance.init();

      // The splash screen stays visible until the data is ready.
      final List<Note> notes = await widget.repository.loadNotes();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              Home(repository: widget.repository, initialNotes: notes),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error while loading : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Center(
                    child: SizedBox(
                      width: 90.0,
                      height: 90.0,
                      child: CircleAvatar(
                        radius: 54.0,
                        backgroundColor: Colors.black87,
                        child: Icon(
                          Icons.turned_in_not,
                          color: Colors.white,
                          size: 45.0,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 90.0,
                  child: Center(
                    child: RichText(
                      text: TextSpan(
                        text: AppConfig.appName,
                        style: TextStyle(
                          fontSize: 21.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: AppConfig.appNameSuffix,
                            style: TextStyle(
                              fontSize: 21.0,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
