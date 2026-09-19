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

/// SQLite-backed [NotesRepository] and [FoldersRepository] implementation.
class SQLiteNotesRepository
    implements
        NotesRepository,
        FoldersRepository,
        AtomicNoteImporter,
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

  Future<Database> get _database async {
    if (_db != null) return _db!;
    _db = await (_opening ??= _initDb().whenComplete(() => _opening = null));
    return _db!;
  }

  static const int _schemaVersion = 9;

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
    final String? password = await _passwordProvider?.call();

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

    return db;
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
        deletedAt TEXT,
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
  Future<String> nextFolderName() async {
    final Set<String> names = (await loadFolders())
        .map((Folder f) => f.name)
        .toSet();
    int i = 1;
    while (names.contains('Folder $i')) {
      i++;
    }
    return 'Folder $i';
  }

  @override
  Future<List<Note>> loadNotes() async {
    final db = await _database;

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
  Future<void> insertImportedNotes(List<Note> notes) async {
    final db = await _database;
    await db.transaction((txn) async {
      for (final note in notes) {
        await txn.insert(
          'notes',
          note.toJson(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
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
  Future<void> toggleLock(String id, {String? password}) async {
    // Authentication belongs to the application boundary, using the OS credential.
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
        {
          'isLocked': currentLock == 1 ? 0 : 1,
          'updatedAt': DateTime.now().toString(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  @override
  Future<void> deleteNotePermanently(String id) async {
    final db = await _database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<Note>> searchNotes(String query) async {
    final db = await _database;
    final String escaped = escapeLikePattern(query);
    final List<Map<String, dynamic>> results = await db.query(
      'notes',
      where:
          "(title LIKE ? ESCAPE '\\' OR description LIKE ? ESCAPE '\\' OR content LIKE ? ESCAPE '\\') AND isDeleted = 0",
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
