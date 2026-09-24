import 'dart:convert';
import 'package:tano/core/services/attachment_maintenance.dart';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:tano/core/models/folder.dart';
import 'package:tano/core/models/note.dart';
import 'package:tano/core/repositories/folders_repository.dart';
import 'package:tano/core/repositories/notes_repository.dart';

/// Raised when the encrypted store cannot be opened safely.
///
/// Startup shows its retry screen for it instead of touching the data.
class StorageUnavailableException implements Exception {
  const StorageUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'StorageUnavailableException: $message';
}

/// SQLite-backed [NotesRepository] and [FoldersRepository] implementation.
class SQLiteNotesRepository
    implements
        NotesRepository,
        FoldersRepository,
        AtomicNoteImporter,
        AtomicNotesWriter,
        ArchiveRepository,
        AttachmentReferenceSource {
  SQLiteNotesRepository({
    DatabaseFactory? databaseFactoryOverride,
    String? databasePath,
    Future<Directory> Function()? documentsDirectory,
    Future<String?> Function()? passwordProvider,
  }) : _databaseFactory = databaseFactoryOverride ?? databaseFactory,
       _databasePath = databasePath,
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _passwordProvider = passwordProvider;

  /// Injectable for tests (e.g. `databaseFactoryFfi`); defaults to the
  /// platform implementation.
  final DatabaseFactory _databaseFactory;

  /// Full path to the SQLite file. When null, the platform default database
  /// directory is used.
  final String? _databasePath;

  /// Location of disposable pre-release JSON files to clean up.
  final Future<Directory> Function() _documentsDirectory;

  /// Provides the SQLCipher passphrase. When null (tests), the database is
  /// opened in the clear.
  final Future<String?> Function()? _passwordProvider;

  Database? _db;
  Future<Database>? _opening;

  /// Whether the FTS5 index is available on this SQLite build. Set once, after
  /// the database opens.
  bool _ftsAvailable = false;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await (_opening ??= _initDb().whenComplete(() => _opening = null));
    return _db!;
  }

  static const int _schemaVersion = 11;

  /// SQLite magic header ("SQLite format 3\u0000"): an unencrypted file starts
  /// with these bytes, an encrypted one does not.
  static const List<int> _sqliteMagic = <int>[
    0x53, 0x51, 0x4C, 0x69, 0x74, 0x65, 0x20, // "SQLite "
    0x66, 0x6F, 0x72, 0x6D, 0x61, 0x74, 0x20, 0x33, // "format 3"
    0x00,
  ];

  Future<Database> _initDb() async {
    final String path =
        _databasePath ??
        join(await _databaseFactory.getDatabasesPath(), 'tano_notes.db');
    // A null provider is the explicit test-only cleartext mode. When a
    // provider is configured, it must yield a passphrase: falling back to a
    // cleartext database would silently drop the encryption the key protects.
    final String? password;
    if (_passwordProvider == null) {
      password = null;
    } else {
      password = await _passwordProvider();
      if (password == null || password.isEmpty) {
        throw const StorageUnavailableException(
          'The database passphrase is unavailable.',
        );
      }
    }

    // Pre-release data is disposable. Never recover plaintext test databases.
    final directory = await _documentsDirectory();
    for (final obsolete in [
      '$path.plain.bak',
      join(directory.path, 'local_persistence.json'),
      join(directory.path, 'local_persistence.json.bak'),
    ]) {
      final file = File(obsolete);
      if (await file.exists()) await file.delete();
    }
    final file = File(path);
    if (password != null &&
        await file.exists() &&
        await _isPlaintextSqlite(file)) {
      await _databaseFactory.deleteDatabase(path);
    }

    final Database db = await _databaseFactory.openDatabase(
      path,
      options: SqlCipherOpenDatabaseOptions(
        version: _schemaVersion,
        password: password,
        onCreate: _createSchema,
        onUpgrade: _upgradeSchema,
      ),
    );
    await _ensureFts(db);

    return db;
  }

  /// Creates the FTS5 index and the triggers that keep it in sync.
  ///
  /// The index is external-content: it stores the inverted index, not a second
  /// copy of the note text. When the SQLite build has no FTS5, the flag stays
  /// false and [searchNotes] keeps its LIKE fallback, so the app still works.
  Future<void> _ensureFts(Database db) async {
    try {
      final List<Map<String, Object?>> existing = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'notes_fts'",
      );
      final bool created = existing.isEmpty;
      await db.execute(
        'CREATE VIRTUAL TABLE IF NOT EXISTS notes_fts USING fts5('
        "title, description, content, content='notes', content_rowid='rowid')",
      );
      await db.execute(
        'CREATE TRIGGER IF NOT EXISTS notes_fts_ai AFTER INSERT ON notes BEGIN '
        'INSERT INTO notes_fts(rowid, title, description, content) '
        'VALUES (new.rowid, new.title, new.description, new.content); END',
      );
      await db.execute(
        'CREATE TRIGGER IF NOT EXISTS notes_fts_ad AFTER DELETE ON notes BEGIN '
        "INSERT INTO notes_fts(notes_fts, rowid, title, description, content) "
        "VALUES('delete', old.rowid, old.title, old.description, old.content); "
        'END',
      );
      await db.execute(
        'CREATE TRIGGER IF NOT EXISTS notes_fts_au AFTER UPDATE ON notes BEGIN '
        "INSERT INTO notes_fts(notes_fts, rowid, title, description, content) "
        "VALUES('delete', old.rowid, old.title, old.description, old.content); "
        'INSERT INTO notes_fts(rowid, title, description, content) '
        'VALUES (new.rowid, new.title, new.description, new.content); END',
      );
      if (created) {
        // Index the notes that already exist when the index is first created.
        await db.execute("INSERT INTO notes_fts(notes_fts) VALUES('rebuild')");
      }
      _ftsAvailable = true;
    } catch (_) {
      _ftsAvailable = false;
    }
  }

  Future<bool> _isPlaintextSqlite(File file) async {
    final RandomAccessFile handle = await file.open();
    try {
      final List<int> header = await handle.read(_sqliteMagic.length);
      if (header.length != _sqliteMagic.length) return false;
      for (int i = 0; i < _sqliteMagic.length; i++) {
        if (header[i] != _sqliteMagic[i]) return false;
      }
      return true;
    } finally {
      await handle.close();
    }
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL DEFAULT 'note' CHECK(kind IN ('note', 'task')),
        title TEXT,
        content TEXT,
        description TEXT NOT NULL DEFAULT '',
        date TEXT,
        important INTEGER,
        category TEXT,
        isDeleted INTEGER DEFAULT 0,
        isLocked INTEGER DEFAULT 0,
        isArchived INTEGER DEFAULT 0,
        deletedAt TEXT,
        archivedAt TEXT,
        attachments TEXT,
        coverImage TEXT,
        folderId TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE folders (
        id TEXT PRIMARY KEY,
        name TEXT,
        date TEXT,
        important INTEGER DEFAULT 0,
        category TEXT,
        isLocked INTEGER DEFAULT 0,
        isDeleted INTEGER DEFAULT 0,
        deletedAt TEXT,
        coverImage TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
  }

  Future<void> _upgradeSchema(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 11) {
      await _addColumnIfMissing(db, 'notes', 'isArchived', 'INTEGER DEFAULT 0');
      await _addColumnIfMissing(db, 'notes', 'archivedAt', 'TEXT');
    }
    if (oldVersion < 9) {
      await _addColumnIfMissing(
        db,
        'notes',
        'description',
        "TEXT NOT NULL DEFAULT ''",
      );
    }
    if (oldVersion < 8) {
      await _addColumnIfMissing(
        db,
        'notes',
        'kind',
        "TEXT NOT NULL DEFAULT 'note'",
      );
    }
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE notes ADD COLUMN isDeleted INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE notes ADD COLUMN isLocked INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE notes ADD COLUMN deletedAt TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE notes ADD COLUMN attachments TEXT');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE notes ADD COLUMN coverImage TEXT');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE notes ADD COLUMN folderId TEXT');
      await db.execute('''
        CREATE TABLE folders (
          id TEXT PRIMARY KEY,
          name TEXT,
          date TEXT,
          important INTEGER DEFAULT 0,
          category TEXT,
          isLocked INTEGER DEFAULT 0,
          isDeleted INTEGER DEFAULT 0,
          deletedAt TEXT,
          coverImage TEXT,
          createdAt TEXT,
          updatedAt TEXT
        )
      ''');
    }
    if (oldVersion < 7) {
      // `createdAt`/`updatedAt` back the "recently modified" sort and the
      // future sync work. They default to `date` for existing rows.
      await _addColumnIfMissing(db, 'notes', 'createdAt', 'TEXT');
      await _addColumnIfMissing(db, 'notes', 'updatedAt', 'TEXT');
      await _addColumnIfMissing(db, 'folders', 'createdAt', 'TEXT');
      await _addColumnIfMissing(db, 'folders', 'updatedAt', 'TEXT');
      // Covers and the lock flag reached the folders table without a schema
      // bump, so databases upgraded to v6 may still miss the columns.
      await _addColumnIfMissing(db, 'folders', 'coverImage', 'TEXT');
      await _addColumnIfMissing(db, 'folders', 'isLocked', 'INTEGER DEFAULT 0');
      await db.execute(
        'UPDATE notes SET createdAt = date WHERE createdAt IS NULL',
      );
      await db.execute(
        'UPDATE notes SET updatedAt = date WHERE updatedAt IS NULL',
      );
      await db.execute(
        'UPDATE folders SET createdAt = date WHERE createdAt IS NULL',
      );
      await db.execute(
        'UPDATE folders SET updatedAt = date WHERE updatedAt IS NULL',
      );
    }
  }

  /// Adds [column] to [table] only when it does not exist yet.
  ///
  /// `ALTER TABLE ... ADD COLUMN` fails on a duplicate column, and upgrade
  /// paths differ (fresh v6 installs already carry `folders.coverImage`).
  Future<void> _addColumnIfMissing(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    final List<Map<String, Object?>> columns = await db.rawQuery(
      'PRAGMA table_info($table)',
    );
    final bool exists = columns.any(
      (Map<String, Object?> c) => c['name'] == column,
    );
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $type');
    }
  }

  @override
  Future<Set<String>> referencedAttachments() async {
    final db = await _database;
    return db.transaction((txn) async {
      final names = <String>{};
      // No trash filter: deleted notes/folders remain restorable.
      for (final row in await txn.query(
        'notes',
        columns: ['attachments', 'coverImage'],
      )) {
        final raw = row['attachments'];
        if (raw != null) {
          final decoded = jsonDecode(raw as String);
          if (decoded is! List || decoded.any((name) => name is! String)) {
            throw const FormatException('Invalid attachment references');
          }
          names.addAll(decoded.cast<String>());
        }
        final cover = row['coverImage'];
        if (cover != null) names.add(cover as String);
      }
      for (final row in await txn.query('folders', columns: ['coverImage'])) {
        final cover = row['coverImage'];
        if (cover != null) names.add(cover as String);
      }
      return names;
    });
  }

  @override
  Future<List<Folder>> loadFolders() async {
    final db = await _database;
    final List<Map<String, dynamic>> results = await db.query(
      'folders',
      where: 'isDeleted = 0',
    );
    return results.map((json) => Folder.fromJson(json)).toList();
  }

  @override
  Future<void> upsertFolder(Folder folder) async {
    final db = await _database;
    await db.insert(
      'folders',
      folder.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Folder>> loadTrashFolders() async {
    final db = await _database;
    final List<Map<String, dynamic>> results = await db.query(
      'folders',
      where: 'isDeleted = 1',
    );
    return results.map((json) => Folder.fromJson(json)).toList();
  }

  @override
  Future<void> trashFolder(String id) async {
    final db = await _database;
    // The notes keep their `folderId`: the folder stays whole in the trash and
    // restoring it brings its content back with it.
    await db.update(
      'folders',
      <String, Object?>{
        'isDeleted': 1,
        'deletedAt': DateTime.now().toString(),
        'updatedAt': DateTime.now().toString(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> restoreFolder(String id) async {
    final db = await _database;
    await db.update(
      'folders',
      <String, Object?>{
        'isDeleted': 0,
        'deletedAt': null,
        'updatedAt': DateTime.now().toString(),
      },
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  @override
  Future<void> deleteFolderPermanently(String id) async {
    final db = await _database;
    // The folder goes with its notes: they are only reachable through it.
    await db.transaction((txn) async {
      await txn.delete(
        'notes',
        where: 'folderId = ?',
        whereArgs: <Object?>[id],
      );
      await txn.delete('folders', where: 'id = ?', whereArgs: <Object?>[id]);
    });
  }

  @override
  Future<List<Note>> loadNotes() async {
    final db = await _database;

    final List<Map<String, dynamic>> active = await db.query(
      'notes',
      where: 'isDeleted = 0 AND isArchived = 0',
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
    final Database db = await _database;
    final Map<String, Object?> values = note.toJson();
    // Update first, insert only when the row is new. A REPLACE would remove the
    // old row without firing the FTS delete trigger, leaving a stale index.
    final int updated = await db.update(
      'notes',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[note.id],
    );
    if (updated == 0) {
      await db.insert(
        'notes',
        values,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    }
  }

  @override
  Future<void> insertImportedNotes(
    List<Note> notes, {
    List<Folder> folders = const <Folder>[],
  }) async {
    final db = await _database;
    await db.transaction((Transaction txn) async {
      for (final Folder folder in folders) {
        await txn.insert(
          'folders',
          folder.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      for (final Note note in notes) {
        await txn.insert(
          'notes',
          note.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  @override
  Future<void> upsertNotes(List<Note> notes) async {
    if (notes.isEmpty) return;
    final Database db = await _database;
    await db.transaction((Transaction txn) async {
      for (final Note note in notes) {
        final Map<String, Object?> values = note.toJson();
        final int updated = await txn.update(
          'notes',
          values,
          where: 'id = ?',
          whereArgs: <Object?>[note.id],
        );
        if (updated == 0) {
          await txn.insert(
            'notes',
            values,
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      }
    });
  }

  @override
  Future<void> trashNote(String id) async {
    final db = await _database;
    await db.update(
      'notes',
      {
        'isDeleted': 1,
        'deletedAt': DateTime.now().toString(),
        'updatedAt': DateTime.now().toString(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> trashNotes(List<String> ids) async {
    if (ids.isEmpty) return;
    final Database db = await _database;
    final String now = DateTime.now().toString();
    await db.transaction((Transaction txn) async {
      for (final String id in ids) {
        await txn.update(
          'notes',
          <String, Object?>{
            'isDeleted': 1,
            'deletedAt': now,
            'updatedAt': now,
          },
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
      }
    });
  }

  @override
  Future<void> restoreNote(String id) async {
    final db = await _database;
    await db.update(
      'notes',
      {
        'isDeleted': 0,
        'deletedAt': null,
        'updatedAt': DateTime.now().toString(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> deleteNotePermanently(String id) async {
    final db = await _database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Note>> loadArchivedNotes() async {
    final db = await _database;
    final List<Map<String, dynamic>> results = await db.query(
      'notes',
      where: 'isArchived = 1 AND isDeleted = 0',
    );
    return results.map((json) => Note.fromJson(json)).toList();
  }

  @override
  Future<void> archiveNote(String id) => archiveNotes(<String>[id]);

  @override
  Future<void> archiveNotes(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _database;
    final String now = DateTime.now().toString();
    await db.transaction((Transaction txn) async {
      for (final String id in ids) {
        await txn.update(
          'notes',
          <String, Object?>{
            'isArchived': 1,
            'archivedAt': now,
            'updatedAt': now,
          },
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
      }
    });
  }

  @override
  Future<void> restoreArchivedNote(String id) => restoreArchivedNotes(<String>[id]);

  @override
  Future<void> restoreArchivedNotes(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await _database;
    final String now = DateTime.now().toString();
    await db.transaction((Transaction txn) async {
      for (final String id in ids) {
        await txn.update(
          'notes',
          <String, Object?>{
            'isArchived': 0,
            'archivedAt': null,
            // Restoring brings the document back to Home and, by contract, its
            // creation date becomes the restore date.
            'folderId': null,
            'date': now,
            'updatedAt': now,
          },
          where: 'id = ?',
          whereArgs: <Object?>[id],
        );
      }
    });
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final Database db = await _database;
    if (_ftsAvailable) {
      final String? fts = ftsPrefixQuery(query);
      if (fts == null) return <Note>[];
      final List<Map<String, dynamic>> results = await db.rawQuery(
        'SELECT n.* FROM notes n JOIN notes_fts ON notes_fts.rowid = n.rowid '
        'WHERE notes_fts MATCH ? AND n.isDeleted = 0 AND n.isArchived = 0 '
        'ORDER BY n.rowid',
        <Object?>[fts],
      );
      return results.map((json) => Note.fromJson(json)).toList();
    }
    final String escaped = escapeLikePattern(query);
    final List<Map<String, dynamic>> results = await db.query(
      'notes',
      where:
          "(title LIKE ? ESCAPE '\\' OR description LIKE ? ESCAPE '\\' OR content LIKE ? ESCAPE '\\') AND isDeleted = 0 AND isArchived = 0",
      whereArgs: ['%$escaped%', '%$escaped%', '%$escaped%'],
    );
    return results.map((json) => Note.fromJson(json)).toList();
  }

  @override
  Future<void> deleteAllNotes() async {
    final db = await _database;
    await db.delete('notes');
  }

  @override
  Future<void> deleteAllFolders() async {
    final db = await _database;
    await db.delete('folders');
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

/// A safe FTS5 prefix query for [raw], or null when it holds no word.
///
/// Only letters and digits survive, one quoted prefix term per word, so user
/// text can never be read as an FTS operator ("AND", quotes, colons...). The
/// term count is bounded so a pasted paragraph cannot build a huge query.
String? ftsPrefixQuery(String raw) {
  final List<String> tokens = raw
      .toLowerCase()
      .split(RegExp(r'[^\p{L}\p{N}]+', unicode: true))
      .where((String token) => token.isNotEmpty)
      .take(8)
      .toList();
  if (tokens.isEmpty) return null;
  return tokens.map((String token) => '"$token"*').join(' ');
}
