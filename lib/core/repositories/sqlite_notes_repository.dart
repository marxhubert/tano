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
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT,
            content TEXT,
            date TEXT,
            important INTEGER,
            category TEXT,
            isDeleted INTEGER DEFAULT 0,
            isPinned INTEGER DEFAULT 0,
            isLocked INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE notes ADD COLUMN isDeleted INTEGER DEFAULT 0');
          await db.execute(
              'ALTER TABLE notes ADD COLUMN isPinned INTEGER DEFAULT 0');
          await db.execute(
              'ALTER TABLE notes ADD COLUMN isLocked INTEGER DEFAULT 0');
        }
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

  @override
  Future<void> trashNote(String id) async {
    final db = await _database;
    await db.update(
      'notes',
      {'isDeleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> restoreNote(String id) async {
    final db = await _database;
    await db.update(
      'notes',
      {'isDeleted': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> togglePin(String id) async {
    final db = await _database;
    final List<Map<String, dynamic>> result =
        await db.query('notes', columns: ['isPinned'], where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final int currentPin = result.first['isPinned'] as int;
      await db.update(
        'notes',
        {'isPinned': currentPin == 1 ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  @override
  Future<void> toggleLock(String id, {String? password}) async {
    // Basic toggle for now. Password logic will be added in Phase 3.
    final db = await _database;
    final List<Map<String, dynamic>> result =
        await db.query('notes', columns: ['isLocked'], where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final int currentLock = result.first['isLocked'] as int;
      await db.update(
        'notes',
        {'isLocked': currentLock == 1 ? 0 : 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
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
