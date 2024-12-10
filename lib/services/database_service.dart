import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  // Private constructor
  DatabaseService._internal();

  // Factory constructor to return the same instance
  factory DatabaseService() {
    return _instance;
  }

  // Initialize or retrieve the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {

    print('running _initDatabase');
    // Get the database path
    String path = join(await getDatabasesPath(), 'my_database.db');

    // Open the database, create tables if necessary
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE files (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            local_path        TEXT,
            local_timestamp   INTEGER,
            remote_id         INTEGER,
            remote_timestamp  INTEGER
          )
        ''');

        db.execute('''
          CREATE TABLE folders (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            local_path        TEXT,
            local_timestamp   INTEGER,
            remote_id         INTEGER,
            remote_timestamp  INTEGER
          )
        ''');
        
      },
    );
  }

  Future<void> createFile({
    required String path,
    required int timestamp,
  }) async {
    final db = await database;
    await db.insert(
      'files', 
      {
        'local_path'        : path,
        'local_timestamp'   : timestamp,
        'remote_id'         : null,
        'remote_timestamp'  : null

      }
    );
  }

  Future<void> createFolder({
    required String path,
    required int timestamp,
  }) async {
    final db = await database;
    await db.insert(
      'folders', 
      {
        'local_path'        : path,
        'local_timestamp'   : timestamp,
        'remote_id'         : null,
        'remote_timestamp'  : null

      }
    );
  }

  Future<void> modifyFile({
    required String path,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'files',
      {
        'local_timestamp': timestamp
      },
      where       : 'local_path = ?',
      whereArgs   : [path],
      );

    
  }

  Future<void> renameFile({
    required String path,
    required String destination,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'files',
      {
        'local_path'        : destination,
        'local_timestamp'   : timestamp
      }, // The values to update
      where     : 'local_path = ?',
      whereArgs : [path],
      );
  }

  Future<void> renameFolder({
    required String path,
    required String destination,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'folders',
      {
        'local_path'       : destination,
        'local_timestamp'  : timestamp
      }, // The values to update
      where     : 'local_path = ?',
      whereArgs : [path],
      );
  }

  Future<void> moveFile({
    required String path,
    required String destination,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'files',
      {
        'local_path'      : destination,
        'local_timestamp' : timestamp
      },
      where     : 'local_path = ?',
      whereArgs : [path],
      );
  }

  Future<void> moveFolder({
    required String path,
    required String destination,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'folders',
      {
        'local_path'        : destination,
        'local_timestamp'   : timestamp
      },
      where     : 'local_path = ?',
      whereArgs : [path],
      );
  }

  Future<void> deleteFile({
    required String path,
  }) async {
    final db = await database;

    db.delete(
      'files',
      where     : 'local_path = ?',
      whereArgs : [path],
      );
  }

  Future<void> deleteFolder({
    required String path,
  }) async {
    final db = await database;

    db.delete(
      'folders',
      where     : 'local_path = ?',
      whereArgs : [path],
    );

    db.delete(
      'files',
      where     : 'local_path LIKE ?',
      whereArgs : ['%$path%'],
    );
  }

  Future queryAllFiles() async {

    final db = await database;
    
    //return await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');

    return await db.query('files');

  }

  Future queryAllFolders() async {

    final db = await database;

    return await db.query('folders');
    
  }

  Future deleteAll() async {
    final db = await database;

    db.delete('folders');

    db.delete('files');

  }

}
