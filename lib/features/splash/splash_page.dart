import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/shared/widgets/theme.dart';

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
      // The loader stays visible until the data is ready.
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
      backgroundColor: barColor(context),
      body: const Center(
        child: CircularProgressIndicator.adaptive(),
      ),
    );
  }
}
