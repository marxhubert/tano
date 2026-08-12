import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tano/domain/notes_repository.dart';
import 'package:tano/fixtures/notes_fixtures.dart';
import 'package:tano/models/database.dart';
import 'package:tano/models/note.dart';

/// File-backed [NotesRepository] implementation.
///
/// All disk and JSON concerns live here: the rest of the app only talks
/// to [NotesRepository].
class FileNotesRepository implements NotesRepository {
    Future<File> get _localFile async {
        final Directory directory = await getApplicationDocumentsDirectory();
        return File('${directory.path}/local_persistence.json');
    }

    @override
    Future<List<Note>> loadNotes() async {
        try {
            final File file = await _localFile;
            if (!file.existsSync()) {
                debugPrint('File does not exist: ${file.absolute}');
                // First launch: seed the app with 24 demo notes so every
                // category, date range and favorite status is represented.
                await saveNotes(buildNotesFixtures());
            }
            final String contents = await file.readAsString();
            return dbFromJson(contents).note;
        } catch (e) {
            debugPrint('Error readNotes: $e');
            return <Note>[];
        }
    }

    @override
    Future<void> saveNotes(List<Note> notes) async {
        final File file = await _localFile;
        await file.writeAsString(dbToJson(Database(note: notes)));
    }
}
