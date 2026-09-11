import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/features/notes/home_page.dart';
import 'package:tano/shared/config/l10n.dart';
import 'package:tano/shared/config/service_locator.dart';
import 'package:tano/shared/widgets/theme.dart';

/// First screen: loads the notes, then hands them over to the home screen.
///
/// When loading fails (for example a database that cannot be opened on this
/// device), it shows a dedicated error state with "Retry" and "Quit" instead of
/// leaving the user in front of an endless loader.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final NotesRepository repository = getIt<NotesRepository>();
      // The loader stays visible until the data is ready.
      final List<Note> notes = await repository.loadNotes();

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => Home(initialNotes: notes),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
      });
    }
  }

  void _retry() {
    setState(() {
      _error = null;
    });
    _loadInitialData();
  }

  void _quit() {
    // On Android this closes the app. On iOS the platform ignores it, since
    // Apple's guidelines forbid programmatic termination.
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: barColor(context),
      body: Center(
        child: _error == null
            ? const CircularProgressIndicator.adaptive()
            : _buildError(context, _error!),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    final Color textColor = primaryTextColor(context);
    final Color muted = mutedTextColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline, size: 48.0, color: muted),
          const SizedBox(height: 16.0),
          Text(
            AppText.tr('load_error_title'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            AppText.tr('load_error_message'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.0, color: muted),
          ),
          const SizedBox(height: 12.0),
          Text(
            '$error',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.0,
              color: muted.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _retry,
              style: FilledButton.styleFrom(backgroundColor: tanoTeal),
              child: Text(AppText.tr('retry')),
            ),
          ),
          const SizedBox(height: 4.0),
          TextButton(
            onPressed: _quit,
            child: Text(
              AppText.tr('quit_app'),
              style: TextStyle(color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
