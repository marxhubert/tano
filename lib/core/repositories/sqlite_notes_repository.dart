import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/notes_repository.dart';
import 'package:tano/core/repositories/notes_fixtures.dart';
import 'package:tano/core/models/database.dart';

/// SQLite-backed [NotesRepository] implementation.
class SQLiteNotesRepository implements NotesRepository {
  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final String path = join(await getDatabasesPath(), 'tano_notes.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT,
            content TEXT,
            date TEXT,
            important INTEGER,
            category TEXT
          )
        ''');
      },
    );
  }

  @override
  Future<List<Note>> loadNotes() async {
    final db = await _database;

    // 1. Check if database is empty to handle first-run/migration
    final List<Map<String, dynamic>> existing = await db.query('notes');
    if (existing.isEmpty) {
      return await _handleMigration(db);
    }

    return existing.map((json) => Note.fromJson(json)).toList();
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    final db = await _database;
    await db.transaction((txn) async {
      // Current interface replaces everything (legacy File behaviour)
      await txn.delete('notes');
      for (final note in notes) {
        await txn.insert('notes', note.toJson());
      }
    });
  }

  /// Migrates data from the old JSON file if it exists.
  Future<List<Note>> _handleMigration(Database db) async {
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final File legacyFile = File('${directory.path}/local_persistence.json');

      if (legacyFile.existsSync()) {
        debugPrint('SQLite: Migrating from legacy JSON file...');
        final String contents = await legacyFile.readAsString();
        final List<Note> legacyNotes = dbFromJson(contents).note;
        
        if (legacyNotes.isNotEmpty) {
          await db.transaction((txn) async {
            for (final note in legacyNotes) {
              await txn.insert('notes', note.toJson());
            }
          });
          // Rename or delete to avoid re-migration
          await legacyFile.rename('${legacyFile.path}.bak');
          debugPrint('SQLite: Migration successful.');
          return legacyNotes;
        }
      }
    } catch (e) {
      debugPrint('SQLite: Migration error: $e');
    }

    // Default seed if no legacy data found
    debugPrint('SQLite: Seeding default notes...');
    final List<Note> seed = buildNotesFixtures();
    await db.transaction((txn) async {
      for (final note in seed) {
        await txn.insert('notes', note.toJson());
      }
    });
    return seed;
  }
}
