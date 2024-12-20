import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../utils//types.dart';
import '../models/FileFolderInfo.dart';

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
    String path = join(await getDatabasesPath(), 'my_databse.db');

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
            local_modified    INTEGER,
            remote_id         INTEGER,
            remote_timestamp  INTEGER
          )
        ''');

        db.execute('''
          CREATE TABLE folders (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            local_path        TEXT,
            local_timestamp   INTEGER,
            local_modified    INTEGER,
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
        'local_modified'    : 0,
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
        'local_modified'    : 0,
        'remote_id'         : null,
        'remote_timestamp'  : null

      }
    );
  }

  Future<void> _modifyFile({
    required String path,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'files',
      {
        'local_timestamp'   : timestamp,
        'local_modified'    : 1,
      },
      where       : 'local_path = ?',
      whereArgs   : [path],
    );
    
  }

  Future<void> _renameFile({
    required String path,
    required String destination,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'files',
      {
        'local_path'        : destination,
        'local_timestamp'   : timestamp,
        'local_modified'    : 1
      }, // The values to update
      where     : 'local_path = ?',
      whereArgs : [path],
    );

    print('patutnya jadi');
  }

  Future<void> _renameFolder({
    required String path,
    required String destination,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'folders',
      {
        'local_path'       : destination,
        'local_timestamp'  : timestamp,
        'local_modified'   : 1
      }, // The values to update
      where     : 'local_path = ?',
      whereArgs : [path],
      );
  }

  Future<void> _moveFile({
    required String path,
    required String destination,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'files',
      {
        'local_path'      : destination,
        'local_timestamp' : timestamp,
        'local_modified'  : 1
      },
      where     : 'local_path = ?',
      whereArgs : [path],
      );
  }

  Future<void> _moveFolder({
    required String path,
    required String destination,
    required int timestamp,
  }) async {
    final db = await database;

    db.update(
      'folders',
      {
        'local_path'        : destination,
        'local_timestamp'   : timestamp,
        'local_modified'    : 1
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

    return await db.query('files');

  }

  Future queryAllFolders() async {

    final db = await database;

    return await db.query('folders');
    
  }

  Future queryNewFolders() async {

    final db = await database;

    var result = await db.query(
      'folders',
      where: 'remote_id IS NULL'
    );

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  Future queryNewFiles() async {

    final db = await database;

    var result = await db.query(
        'files',
        where: 'remote_id IS NULL'
    );

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  Future queryModifiedFiles() async {

    final db = await database;

    var result = await db.query(
        'files',
        where : 'local_modified = 1'
    );

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  queryModifiedFolders() async {

    final db = await database;

    var result = await db.query(
        'folders',
        where : 'local_modified = 1'
    );

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  Future deleteAll() async {

    final db = await database;

    db.delete('folders');

    db.delete('files');

  }

  updateLocalDatabaseRecord({
  required queue,
  required DatabaseService db
  }){


  if(queue['event']['type'] == FileType.file){

    if(queue['event']['action'] == QueueAction.create){
      db.createFile(
        path        : queue['event']['path'], 
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.modify){
      db._modifyFile(
        path        : queue['event']['path'], 
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.rename){
      db._renameFile(
        path        : queue['event']['from'], 
        destination : queue['event']['to'],
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.move){
      db._moveFile(
        path        : queue['event']['from'], 
        destination : queue['event']['to'],
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.delete){
      db.deleteFile(
        path        : queue['event']['path'], 
      );
    }
    
  }else{

    if(queue['event']['action'] == QueueAction.create){
      db.createFolder(
        path        : queue['event']['path'], 
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.rename){
      db._renameFolder(
        path        : queue['event']['from'], 
        destination : queue['event']['to'],
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.move){
      db._moveFolder(
        path        : queue['event']['from'], 
        destination : queue['event']['to'],
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.delete){
      db.deleteFolder(
        path        : queue['event']['path'], 
      );
    }

  }
}

}
