import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pdwatcher/providers/sync_provider.dart';
import 'package:pdwatcher/services/database_service.dart';
import 'package:pdwatcher/services/local_storage_service.dart';
import 'package:provider/provider.dart';
import '../models/change.dart';
import '../utils/consts.dart';
import '../utils/enums.dart';
import '../models/file_folder_info.dart';
import '../utils/types.dart';
import 'file_service.dart';
import 'log_service.dart';

abstract class SyncService {

  static Future<void> syncLocalFileFolderWithLocalDb() async {

    DatabaseService databaseService = DatabaseService();

    List<dynamic> files = await databaseService.queryAllFiles();
    List<dynamic> folders = await databaseService.queryAllFolders();

    String? watchedDirectory = await LocalStorage.getWatchedDirectory();

    final List<FileSystemEntity> foldersInWatchedDirectory = await Directory(watchedDirectory!)
        .list(recursive: true, followLinks: false)
        .toList();

    //check if there is any folder not recorded in local db, then add entry to db
    for (var entity in foldersInWatchedDirectory) {

      FileStat stat = await entity.stat();

      if (entity is Directory && !folders.any((folder) => folder['local_path'] == entity.path)) {
        Log.info('Path: ${entity.path}, Action: createFolder');
        databaseService.createFolder(
          path: entity.path,
          timestamp: stat.changed.millisecondsSinceEpoch
        );
      } else if (entity is File && !files.any((file) => file['local_path'] == entity.path)) {
        Log.info('Path: ${entity.path}, Action: createFile');
        databaseService.createFile(
          path: entity.path,
          timestamp: stat.changed.millisecondsSinceEpoch
        );
      }
    }

    //check if there is any folder in db entry not exist in watched directory, then delete entry
    for (var folder in folders){
      if (!foldersInWatchedDirectory.any((entity) => entity.path == folder['local_path'])) {
        Log.info('Path: ${folder['local_path']}, Action: deleteFolder');
        databaseService.deleteFolder(
          path: folder['local_path']
        );
      }
    }

    //check if there is any file in db entry not exist in watched directory, then delete entry
    for (var file in files){
      if (!foldersInWatchedDirectory.any((entity) => entity.path == file['local_path'])) {
        Log.info('Path: ${file['local_path']}, Action: deleteFile');
        databaseService.deleteFile(
          path: file['local_path']
        );
      }
    }


  }

  static Future<bool> syncRemoteToLocal(context) async {

    //wait until sync finish first;
    if(Provider.of<SyncProvider>(context, listen: false).isSyncing){
      Log.warning('Currently syncing... wait until finish');
      return false;
    }

    //check internet connection
    final connectivityResult = await (Connectivity().checkConnectivity());

    switch (connectivityResult) {
      case ConnectivityResult.none:
        Log.error('No internet connection. Sync operation aborted');
        Provider.of<SyncProvider>(context, listen: false).setOffline();
        return false;
      case ConnectivityResult.ethernet:
      case ConnectivityResult.wifi:
      case ConnectivityResult.vpn:
        Log.info('Internet OK');
        Provider.of<SyncProvider>(context, listen: false).setOnline();
      default:
        Provider.of<SyncProvider>(context, listen: false).setOffline();
        Log.error('Unknown connection status');
        return false;
    }

    await Provider.of<SyncProvider>(context, listen: false).getChanges(context);

    if(Provider.of<SyncProvider>(context, listen: false).change == null){
      Log.error('Error calling api getChanges');
      return false;
    }

    Change change = Provider.of<SyncProvider>(context, listen: false).change!;

    DatabaseService databaseService = DatabaseService();

    for (var file in change.files) {

      Log.info('Started Syncing Remote -> Local For File: ${file.path}');

      //check db if file already registered
      List<FileFolderInfo> localDBData = await databaseService.queryById(id: file.remotefileId, mimetype: file.mimetype);

      if(localDBData.isEmpty){
        Log.verbose('No Local File Found for ${file.path}');

        //Download to temp

        //set move based on file path

        //add ignore list

        //move

        //add to db


      }else{

        Log.verbose('Existing Local File Found for ${file.path}');

        //compare remote_timestamp
        if(file.mtime == localDBData[0].remoteTimestamp!){

          Log.verbose('Remote File Not Updated for ${file.path}');
          Log.verbose('Skipping Download ${file.path}');
          continue;
        }

        Log.verbose('Remote File Updated for ${file.path}');
        Log.verbose('Preparing Download for ${file.path}');

        //download temp

        //compare path
        if(file.path != localDBData[0].localPath){
          Log.verbose('File Path Different');
          Log.verbose('Local  : ${localDBData[0].localPath}');
          Log.verbose('Remote : ${file.path}');
          //
          continue;

        }
        //set move based on local path

        if(localDBData[0].localModified == 1){
          Log.verbose('Local File Updated for ${file.path}');
          //create copy
        }

        //add ignore list

        //move

        //update db

      }

    }

    return true;


  }

  static syncLocalToRemote(context) async {

    //wait until sync finish first;
    if(Provider.of<SyncProvider>(context, listen: false).isSyncing){
      Log.warning('Currently syncing... wait until finish');
      return;
    }

    //check internet connection
    final connectivityResult = await (Connectivity().checkConnectivity());

    switch (connectivityResult) {
      case ConnectivityResult.none:
        Log.error('No internet connection. Sync operation aborted');
        Provider.of<SyncProvider>(context, listen: false).setOffline();
        return;
      case ConnectivityResult.ethernet:
      case ConnectivityResult.wifi:
      case ConnectivityResult.vpn:
        Log.info('Internet OK');
        Provider.of<SyncProvider>(context, listen: false).setOnline();
      default:  
        Provider.of<SyncProvider>(context, listen: false).setOffline();
        Log.error('Unknown connection status');
    }
    

    Provider.of<SyncProvider>(context, listen: false).isSyncing = true;
    Log.info('Sync started');
    Provider.of<SyncProvider>(context, listen: false).updateUI();

    await syncLocalFileFolderWithLocalDb();
    await _uploadNewFoldersAndFiles(context);
    //await syncLocalFileFolderWithLocalDb();
    //await _uploadModifiedFoldersAndFiles(context);

    Provider.of<SyncProvider>(context, listen: false).isSyncing = false;
    Log.info('Sync finished');
    Provider.of<SyncProvider>(context, listen: false).updateUI();

  }

  static _uploadModifiedFoldersAndFiles(context) async {

  Provider.of<SyncProvider>(context, listen: false).modifiedFolders.clear();
  Provider.of<SyncProvider>(context, listen: false).modifiedFiles.clear();
  Provider.of<SyncProvider>(context, listen: false).updateUI();

  DatabaseService databaseService = DatabaseService();

  List<FileFolderInfo> modifiedFolders = await databaseService.queryModifiedFolders();
  List<FileFolderInfo> modifiedFiles = await databaseService.queryModifiedFiles();

  Provider.of<SyncProvider>(context, listen: false).setModifiedFolders(modifiedFolders);
  Provider.of<SyncProvider>(context, listen: false).setModifiedFiles(modifiedFiles);

  for (var folder in modifiedFolders) {
    await Future.delayed(const Duration(seconds: 2));  // Wait for 2 seconds before proceeding

    int index = modifiedFolders.indexOf(folder);

    Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
      syncType: SyncType.modifiedFolder,
      index: index,
      status: SyncStatus.syncing,
    );

    await Future.delayed(const Duration(seconds: 2));

    Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
      syncType: SyncType.modifiedFolder,
      index: index,
      status: SyncStatus.success,
    );
  }

  for (var file in modifiedFiles) {
    await Future.delayed(const Duration(seconds: 2));  // Wait for 2 seconds before proceeding

    int index = modifiedFiles.indexOf(file);

    Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
      syncType: SyncType.modifiedFile,
      index: index,
      status: SyncStatus.syncing,
    );

    await Future.delayed(const Duration(seconds: 2));

    Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
      syncType: SyncType.modifiedFile,
      index: index,
      status: SyncStatus.success,
    );
  }
  }

  static _uploadNewFoldersAndFiles(context) async {

    Provider.of<SyncProvider>(context, listen: false).newFolders.clear();
    Provider.of<SyncProvider>(context, listen: false).newFiles.clear();
    Provider.of<SyncProvider>(context, listen: false).updateUI();

    DatabaseService databaseService = DatabaseService();

    List<FileFolderInfo> newFolders  = await databaseService.queryNewFolders();
    List<FileFolderInfo> newFiles    = await databaseService.queryNewFiles();

    Provider.of<SyncProvider>(context, listen: false).setNewFolders(newFolders);
    Provider.of<SyncProvider>(context, listen: false).setNewFiles(newFiles);

    for (var folder in newFolders) {

      //check if exist or not
      bool exists = await Directory(folder.localPath).exists();
      if (!exists) {
        int index = newFolders.indexOf(folder);
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.newFolder,
          index: index,
          status: SyncStatus.failed,
        );
        Log.warning('Folder ${folder.localPath} does not exist. Skipping');
        continue; // Skip to the next iteration
      }

      int index = newFolders.indexOf(folder);

      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
        syncType: SyncType.newFolder,
        index: index,
        status: SyncStatus.syncing,
      );

      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
        syncType: SyncType.newFolder,
        index: index,
        status: SyncStatus.success,
      );

    }

    for (var file in newFiles) {

      //check if exist or not
      bool exists = await File(file.localPath).exists();

      int index = newFiles.indexOf(file);

      if (!exists) {

        String errorMessage = 'File ${file.localPath} does not exist. Skipping';

        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.newFile,
          index: index,
          status: SyncStatus.failed,
          message: errorMessage,
        );

        Log.info(Provider.of<SyncProvider>(context, listen: false).newFiles[index].toString());
        continue; // Skip to the next iteration

      }

      int fileSize = await File(file.localPath).length();

      if(fileSize == 0){

        String errorMessage = 'File ${file.localPath} is empty. Skipping';

        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.newFile,
          index: index,
          status: SyncStatus.failed,
          message: errorMessage,
        );

        Log.warning(errorMessage);

        continue;
      }

      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
        syncType: SyncType.newFile,
        index: index,
        status: SyncStatus.syncing,
      );

      String? fileUuid = await Isolate. run(() => FileService.copyToTempAndChunk(filePath: file.localPath));

      if(fileUuid == null){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.newFile,
          index: index,
          status: SyncStatus.failed,
        );
        continue;
      }

      final List<FileSystemEntity> chunks = await Directory('$tempDir$fileUuid')
          .list(recursive: false, followLinks: false)
          .toList();

      int currentChunk = 0;
      double lastUpdatePercent = 0;

      for(var chunk in chunks){

        await Future.delayed(Duration(milliseconds: 100));

        double currentPercent = ((currentChunk/chunks.length)*100);

        if(currentPercent - lastUpdatePercent > 5 || currentPercent == 100){
          Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
            syncType: SyncType.newFile,
            index: index,
            status: SyncStatus.syncing,
            progress: currentPercent
          );
          lastUpdatePercent = currentPercent;
        }

        Log.verbose('Upload chunk ${currentPercent.toInt()}%');

        currentChunk++;
      }

      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
        syncType: SyncType.newFile,
        index: index,
        status: SyncStatus.success,
      );

    }


  }
}