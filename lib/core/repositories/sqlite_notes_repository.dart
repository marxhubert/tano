import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/models/notes_json_codec.dart';
import 'package:tano/core/repositories/notes_fixtures.dart';
import 'package:tano/core/repositories/notes_repository.dart';

/// SQLite-backed [NotesRepository] implementation.
class SQLiteNotesRepository implements NotesRepository {
  SQLiteNotesRepository({
    DatabaseFactory? databaseFactoryOverride,
    String? databasePath,
    Future<Directory> Function()? documentsDirectory,
  })  : _databaseFactory = databaseFactoryOverride ?? databaseFactory,
        _databasePath = databasePath,
        _documentsDirectory =
            documentsDirectory ?? getApplicationDocumentsDirectory;

  /// Injectable for tests (e.g. `databaseFactoryFfi`); defaults to the
  /// platform implementation.
  final DatabaseFactory _databaseFactory;

  /// Full path to the SQLite file. When null, the platform default database
  /// directory is used.
  final String? _databasePath;

  /// Location of the legacy JSON file migrated on first launch.
  final Future<Directory> Function() _documentsDirectory;

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final String path = _databasePath ??
        join(await _databaseFactory.getDatabasesPath(), 'tano_notes.db');
    return await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 3,
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
            isLocked INTEGER DEFAULT 0,
            deletedAt TEXT
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
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE notes ADD COLUMN deletedAt TEXT');
        }
      },
      ),
    );
  }

  @override
  Future<List<Note>> loadNotes() async {
    final db = await _database;

    // 1. Check if database is empty to handle first-run/migration
    final List<Map<String, dynamic>> existing = await db.query('notes');
    if (existing.isEmpty) {
      final List<Note> migrated = await _handleMigration(db);
      return migrated.where((n) => !n.isDeleted).toList();
    }

    final List<Map<String, dynamic>> active = await db.query(
      'notes',
      where: 'isDeleted = 0',
    );
    return active.map((json) => Note.fromJson(json)).toList();
  }

  @override
  Future<List<Note>> loadTrashNotes() async {
    final db = await _database;
    final List<Map<String, dynamic>> results = await db.query(
      'notes',
      where: 'isDeleted = 1',
    );
    return results.map((json) => Note.fromJson(json)).toList();
  }

  @override
  Future<void> upsertNote(Note note) async {
    final db = await _database;
    await db.insert(
      'notes',
      note.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> trashNote(String id) async {
    final db = await _database;
    await db.update(
      'notes',
      {
        'isDeleted': 1,
        'deletedAt': DateTime.now().toString(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> restoreNote(String id) async {
    final db = await _database;
    await db.update(
      'notes',
      {
        'isDeleted': 0,
        'deletedAt': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> togglePin(String id) async {
    final db = await _database;
    final List<Map<String, dynamic>> result = await db.query(
      'notes',
      columns: ['isPinned'],
      where: 'id = ?',
      whereArgs: [id],
    );
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
    final List<Map<String, dynamic>> result = await db.query(
      'notes',
      columns: ['isLocked'],
      where: 'id = ?',
      whereArgs: [id],
    );
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

  @override
  Future<void> deleteNotePermanently(String id) async {
    final db = await _database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final db = await _database;
    final String escaped = escapeLikePattern(query);
    final List<Map<String, dynamic>> results = await db.query(
      'notes',
      where:
          "(title LIKE ? ESCAPE '\\' OR content LIKE ? ESCAPE '\\') AND isDeleted = 0",
      whereArgs: ['%$escaped%', '%$escaped%'],
    );
    return results.map((json) => Note.fromJson(json)).toList();
  }

  /// Migrates data from the old JSON file if it exists.
  Future<List<Note>> _handleMigration(Database db) async {
    try {
      final Directory directory = await _documentsDirectory();
      final File legacyFile = File('${directory.path}/local_persistence.json');

      if (legacyFile.existsSync()) {
        debugPrint('SQLite: Migrating from legacy JSON file...');
        final String contents = await legacyFile.readAsString();
        final List<Note> legacyNotes = decodeNotes(contents);

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

/// Escapes `%`, `_` and `\` so a user query is matched literally by a
/// `LIKE ... ESCAPE '\'` clause instead of being interpreted as wildcards.
String escapeLikePattern(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('%', '\\%')
      .replaceAll('_', '\\_');
}
