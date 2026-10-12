
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = 'MyDatabase.db';
  static const _databaseVersion = 2;

  // Existing Part I table
  static const table = 'my_table';
  static const columnId = '_id';
  static const columnName = 'name';
  static const columnAge = 'age';

  // New Part II tables
  static const foldersTable = 'folders';
  static const cardsTable = 'cards';

  late Database _db;

  // Initialize database
  Future<void> init() async {
    final documentsDirectory =
        await getApplicationDocumentsDirectory();

    final path = join(
      documentsDirectory.path,
      _databaseName,
    );

    _db = await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database for a fresh installation
  Future<void> _onCreate(
    Database db,
    int version,
  ) async {
    await _createPartOneTable(db);
    await _createCatalogueTables(db);
  }

  // Preserve the original Part I table
  Future<void> _createPartOneTable(Database db) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnAge INTEGER NOT NULL
      )
    ''');
  }

  // Create folders, cards, and index
  Future<void> _createCatalogueTables(Database db) async {
    await db.execute('''
      CREATE TABLE folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        suit TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        image_ref TEXT,
        folder_id INTEGER NOT NULL,
        FOREIGN KEY (folder_id)
          REFERENCES folders(id)
          ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_cards_folder_id
      ON cards(folder_id)
    ''');
  }

  // Upgrade Version 1 to Version 2
  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _createCatalogueTables(db);
    }
  }

  // =====================================
  // Part I: Existing Guest CRUD
  // =====================================

  Future<int> insert(Map<String, dynamic> row) async {
    return await _db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    return await _db.query(table);
  }

  Future<int> queryRowCount() async {
    final results =
        await _db.rawQuery('SELECT COUNT(*) FROM $table');

    return Sqflite.firstIntValue(results) ?? 0;
  }

  Future<int> update(Map<String, dynamic> row) async {
    final int id = row[columnId] as int;

    return await _db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    return await _db.delete(
      table,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // =====================================
  // Part II: Folder Operations
  // =====================================

  Future<int> insertFolder(String name) async {
    return await _db.insert(
      foldersTable,
      {
        'name': name.trim(),
        'created_at': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<List<Map<String, dynamic>>>
      getFoldersWithCounts() async {
    return await _db.rawQuery('''
      SELECT
        folders.id,
        folders.name,
        folders.created_at,
        COUNT(cards.id) AS card_count
      FROM folders
      LEFT JOIN cards
        ON folders.id = cards.folder_id
      GROUP BY
        folders.id,
        folders.name,
        folders.created_at
      ORDER BY folders.name COLLATE NOCASE ASC
    ''');
  }

  Future<int> deleteFolder(int id) async {
    return await _db.delete(
      foldersTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =====================================
  // Part II: Card Operations
  // =====================================

  Future<List<Map<String, dynamic>>> getCards(
    int folderId,
  ) async {
    return await _db.query(
      cardsTable,
      where: 'folder_id = ?',
      whereArgs: [folderId],
      orderBy: 'title COLLATE NOCASE ASC',
    );
  }

  Future<int> insertCard({
    required String title,
    required String suit,
    required int folderId,
    String notes = '',
    String? imageRef,
  }) async {
    return await _db.insert(
      cardsTable,
      {
        'title': title.trim(),
        'suit': suit,
        'notes': notes,
        'image_ref': imageRef,
        'folder_id': folderId,
      },
    );
  }

  Future<int> updateCard({
    required int id,
    required String title,
    required String suit,
    required int folderId,
    String notes = '',
    String? imageRef,
  }) async {
    return await _db.update(
      cardsTable,
      {
        'title': title.trim(),
        'suit': suit,
        'notes': notes,
        'image_ref': imageRef,
        'folder_id': folderId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCard(int id) async {
    return await _db.delete(
      cardsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close database
  Future<void> close() async {
    await _db.close();
  }
}
