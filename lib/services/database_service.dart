import 'package:pdwatcher/utils/consts.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/file_folder_info.dart';
import '../utils//types.dart';
import '../services/log_service.dart';

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

    Log.info('Database not initialized');

    _database = await _initDatabase();

    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {

    Log.info('Initializing Database......');
    // Get the database path
    String path = '${dbDir}asdsadsad.db';

    Log.info('Database path: $path');

    // Open the database, create tables if necessary
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE files (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            local_path        TEXT,
            local_timestamp   INTEGER,
            local_modified    INTEGER,
            remote_id         INTEGER,
            remote_timestamp  INTEGER,
            to_delete         INTEGER
          )
        ''');

        db.execute('''
          CREATE TABLE folders (
            id                INTEGER PRIMARY KEY AUTOINCREMENT,
            local_path        TEXT,
            local_timestamp   INTEGER,
            local_modified    INTEGER,
            remote_id         INTEGER,
            remote_timestamp  INTEGER,
            to_delete         INTEGER
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

    var result = await db.query(
        'files',
        where: 'local_path =?',
        whereArgs: [path]
    );

    if(result.isNotEmpty){
      Log.error('Duplicate entry');
      return;
    }

    await db.insert(
      'files', 
      {
        'local_path'        : path,
        'local_timestamp'   : timestamp ~/ 1000,
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
        'local_timestamp'   : timestamp ~/ 1000,
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
        'local_timestamp'   : timestamp ~/ 1000,
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

    // Step 1: Check if a record with the destination path exists
    final result = await db.query(
      'files',
      where: 'local_path = ?',
      whereArgs: [destination],
    );

    // Step 2: If a record exists with the destination path, delete the record with the original path
    if (result.isNotEmpty) {
      await db.delete(
        'files',
        where: 'local_path = ?',
        whereArgs: [path],
      );

      await db.update(
        'files',
        {
          'local_path'      : destination,
          'local_timestamp' : timestamp ~/ 1000,
          'local_modified'  : 1,
        },
        where: 'local_path = ?',
        whereArgs: [destination],
      );
    }else{
      await db.update(
        'files',
        {
          'local_path'      : destination,
          'local_timestamp' : timestamp ~/ 1000,
          'local_modified'  : 1,
        },
        where: 'local_path = ?',
        whereArgs: [path],
      );
    }



    // Step 3: Update the record with the new destination


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
        'local_timestamp'  : timestamp ~/ 1000,
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
    bool updateLocalModified = false
  }) async {

    if(path == destination){
      return;
    }
    final db = await database;

    print('moving $path $destination');

    var field = {
      'local_path'        : destination,
      'local_timestamp'   : timestamp ~/ 1000,
    };

    if(updateLocalModified){
      field.addAll({
        'local_modified'    : 1
      });
    }

    db.update(
      'files',
      field,
      where     : 'local_path = ?',
      whereArgs : [path],
      );
  }

  Future<void> _moveFolder({
    required String path,
    required String destination,
    required int timestamp,
    bool updateLocalModified = false
  }) async {
    final db = await database;

    var field = {
      'local_path'        : destination,
      'local_timestamp'   : timestamp ~/ 1000,
    };

    if(updateLocalModified){
      field.addAll({
        'local_modified'    : 1
      });
    }

    db.update(
      'folders',
      field,
      where     : 'local_path = ?',
      whereArgs : [path],
      );
  }

  Future<void> deleteFile({
    required String path,
    bool forceDelete = false
  }) async {
    final db = await database;

    final queryResult = await db.query(
      'files',
      where     : 'local_path = ?',
      whereArgs : [path],
    );

    List<FileFolderInfo> files = queryResult.map((map) => FileFolderInfo.fromMap(map)).toList();

    if(files.isEmpty){
      return;
    }

    //delete record if remote id null (new files), if remote id not null , set to delete = 1. (files already in cloud)
    if(files.first.remoteId == null || forceDelete){
      db.delete(
        'files',
        where     : 'local_path = ?',
        whereArgs : [path],
      );
    }else{
      db.update(
        'files',
        {
          'to_delete': 1
        },
        where     : 'local_path = ?',
        whereArgs : [path],
      );
    }

  }

  Future<void> deleteFolder({
    required String path,
    bool forceDelete = false,
  }) async {
    final db = await database;

    final queryResult = await db.query(
      'folders',
      where     : 'local_path = ?',
      whereArgs : [path],
    );

    List<FileFolderInfo> folders = queryResult.map((map) => FileFolderInfo.fromMap(map)).toList();

    if(folders.isEmpty){
      return;
    }

    //delete record if remote id null (new files), if remote id not null , set to 0. (files already in cloud)
    if(folders.first.remoteId == null || forceDelete){
      db.delete(
        'folders',
        where     : 'local_path = ?',
        whereArgs : [path],
      );
    }else{
      db.update(
        'folders',
        {
          'to_delete': 1
        },
        where     : 'local_path = ?',
        whereArgs : [path],
      );

      db.update(
        'files',
        {
          'to_delete': 1
        },
        where     : 'local_path LIKE ?',
        whereArgs : ['%$path%'],
      );
    }

  }

  Future queryAllFiles() async {

    final db = await database;

    final data = await db.query('files');

    print(data);

    return data;

  }

  Future queryAllFolders() async {

    final db = await database;

    return await db.query('folders');
    
  }

  Future<List<FileFolderInfo>> queryNewFolders() async {

    final db = await database;

    var result = await db.query(
      'folders',
      where: 'remote_id IS NULL'
    );

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  Future<List<FileFolderInfo>> queryByRemoteId({required int remoteId, required mimetype}) async {

    Log.verbose('Querying ${mimetype == 2 ? 'folders' : 'files'} with remote id $remoteId');

    final db = await database;

    var result = await db.query(
        mimetype == 2 ? 'folders' : 'files',
        where     : 'remote_id = ?',
        whereArgs : [remoteId],
    );

    Log.verbose('found ${result.length}');

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  Future updateRemoteNullByPath({required int mimetype, required String localPath}) async {

    final db = await database;

    final target = mimetype == 2 ? 'folders' : 'files';

    return db.update(
        target,
        {
          'local_modified'    : 0,
          'remote_id'         : null,
          'remote_timestamp'  : null,
        },
        where: 'local_path = ?',
        whereArgs: [localPath]
    );
  }

  Future resetRemoteByPath({required String localPath, required String type}) async {

    final db = await database;

    return db.update(
      type == FileType.file ? 'files' : 'folders',
      {
        'remote_id'         : null,
        'remote_timestamp'  : null,
      },
      where: 'local_path = ?',
      whereArgs: [localPath]
    );
  }

  Future updateRemoteByPath({
    required String localPath,
    required String type,
    int? remoteId,
    int? remoteTimeStamp,
    int? localModified,
  }) async {

    final db = await database;

    Map<String,dynamic> toUpdate = {};

    if(localModified != null){
      toUpdate.addAll({'local_modified' : localModified});
    }

    if(remoteId != null){
      toUpdate.addAll({'remote_id' : remoteId});
    }

    if(remoteTimeStamp != null){
      toUpdate.addAll({'remote_timestamp' : remoteTimeStamp});
    }

    var modifiedCount = await db.update(
      type == FileType.file ? 'files' : 'folders',
      toUpdate,
      where: 'local_path = ?',
      whereArgs: [localPath],
    );

    Log.verbose('$localPath|$type|$remoteId|$remoteTimeStamp');
    Log.verbose('updateRemoteByPath | Updated Rows: $modifiedCount');

    return modifiedCount;
  }

  Future<List<FileFolderInfo>> queryNewFiles() async {

    final db = await database;

    var result = await db.query(
        'files',
        where: 'remote_id IS NULL'
    );

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  Future<List<FileFolderInfo>> queryModifiedFiles() async {

    final db = await database;

    var result = await db.query(
        'files',
        where : 'local_modified = 1 AND remote_id IS NOT NULL AND (to_delete = 0 OR to_delete IS NULL)'
    );

    print(result);

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  Future<List<FileFolderInfo>> queryDeletedFiles() async {

    final db = await database;

    var result = await db.query(
        'files',
        where : 'to_delete = 1'
    );

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  Future<List<FileFolderInfo>> queryDeletedFolders() async {

    final db = await database;

    var result = await db.query(
        'folders',
        where : 'to_delete = 1'
    );

    return result.map((map) => FileFolderInfo.fromMap(map)).toList();
  }

  Future<List<FileFolderInfo>> queryModifiedFolders() async {

    final db = await database;

    var result = await db.query(
        'folders',
        where : 'local_modified = 1 AND remote_id IS NOT NULL AND (to_delete = 0 OR to_delete IS NULL)'
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

      // Check if the file is alphanumeric, has length 8, and contains no dot (no ext) for excel tmp file
      String fileName = queue['event']['path'].toString().split('\\').last;

      if(fileName.length == 8 && RegExp(r'^[a-zA-Z0-9]+$').hasMatch(fileName) && !fileName.contains('.')){
        Log.info('file is excel');
        return;
      }

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
        path                : queue['event']['from'],
        destination         : queue['event']['to'],
        timestamp           : queue['timestamp'],
        updateLocalModified : queue['update_modified'] ?? true
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
        timestamp   : queue['timestamp'],
        updateLocalModified: queue['update_modified'] ?? true
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
