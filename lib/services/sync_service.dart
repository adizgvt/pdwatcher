import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hashids2/hashids2.dart';
import 'package:pdwatcher/models/api_response.dart';
import 'package:pdwatcher/providers/sync_provider.dart';
import 'package:pdwatcher/services/api_service.dart';
import 'package:pdwatcher/services/database_service.dart';
import 'package:pdwatcher/services/hash_service.dart';
import 'package:pdwatcher/services/local_storage_service.dart';
import 'package:pdwatcher/utils/extensions.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/change.dart';
import '../providers/user_provider.dart';
import '../utils/consts.dart';
import '../utils/enums.dart';
import '../models/file_folder_info.dart';
import '../utils/types.dart';
import 'file_service.dart';
import 'log_service.dart';
import 'package:collection/collection.dart';

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

        String name = entity.path.split('\\').last;

        if(name.startsWith('~\$') && microsoftOfficeExtensions.any(name.endsWith)){
          continue;
        }

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
          path: folder['local_path'],);
      }
    }

    //check if there is any file in db entry not exist in watched directory, then delete entry
    for (var file in files){
      if (!foldersInWatchedDirectory.any((entity) => entity.path == file['local_path'])) {
        Log.info('Path: ${file['local_path']}, Action: deleteFile');
        databaseService.deleteFile(
          path: file['local_path']);
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
    String watchedDir = await LocalStorage.getWatchedDirectory() ?? '';

    var uuid = const Uuid();

    for (var file in change.files) {


      Log.info('Started Syncing Remote -> Local For File: ${file.path}');

      //check db if file already registered
      List<dynamic> localDBData = await databaseService.queryByRemoteId(remoteId: file.remotefileId, mimetype: file.mimetype);

      //generate local path
      String localPath = '$watchedDir\\${file.path}';

      //generate UUID
      String tempName = uuid.v1();

      int index = change.files.indexOf(file);

      try{

        //if is folder || mimetype == 2;
        if(file.mimetype == 2){

          Log.verbose('Type: FOLDER   | ${file.path}');

          if(localDBData.isEmpty){

            Log.verbose('No Local Folder Data found in local db with remoted id ${file.remotefileId}.');

            Directory directory = Directory(localPath);

            if(!directory.existsSync()){
              Log.verbose('Creating new directory $localPath');
              directory.createSync(recursive: true);
            }

            await Future.delayed(const Duration(seconds: 3));

            await databaseService.updateRemoteByPath(
                localPath: localPath,
                type: FileType.directory,
                remoteId: file.remotefileId,
                remoteTimeStamp: file.mtime
            );

          }else{

            Log.verbose('Local Folder Data found in local db.');

            if(localDBData[0].toDelete == 1){
              Log.verbose('Local Folder marked for deletion');
              Log.verbose('Skipping....');
              continue;
            }

            if(file.path == localDBData[0].localPath.replaceFirst('$watchedDir\\', '')){
              Log.verbose('path is same');
              Provider.of<SyncProvider>(context, listen: false).change!.files[index].syncStatus = SyncStatus.success;
              Provider.of<SyncProvider>(context, listen: false).updateUI();

              await databaseService.updateRemoteByPath(
                  localPath: localPath,
                  type: FileType.directory,
                  remoteId: file.remotefileId,
                  remoteTimeStamp: null
              );

            }else {
              Log.verbose('path is different');
              Log.verbose('Local  : ${localDBData[0].localPath}');
              Log.verbose('Remote : ${file.path}');

              final d = Directory(localDBData[0].localPath);

              String folderName = localDBData[0].localPath.split('\\').last;

              if(localDBData[0].localTimestamp >= file.mtime){
                print('local folder named changed after remote');
                //remote change after local
              }else{
                final newD = await d.rename(localDBData[0].localPath.toString().replaceLast(folderName, file.name));
                print('Folder renamed to: ${newD.path}');
              }


            }
          }
        }
        //------------------------------------------------------------------------------------------------------------------------------------------
        //else if file || mimetype != 2
        else {

          Log.verbose('Type: FILE     | ${file.path}');

          if(localDBData.isEmpty){
            Log.verbose('No Local File Found for ${file.path}');

            //update UI
            Provider.of<SyncProvider>(context, listen: false).change!.files[index].syncStatus = SyncStatus.syncing;
            Provider.of<SyncProvider>(context, listen: false).change!.files[index].errorMessage = null;
            Provider.of<SyncProvider>(context, listen: false).updateUI();

            //Download to temp
            bool? result = await FileService.download(fileId: file.remotefileId, tempName: tempName);

            if(result == null){
              throw 'download failed';
            }

            //todo
            Provider.of<SyncProvider>(context, listen: false).change!.files[index].syncStatus = SyncStatus.success;
            Provider.of<SyncProvider>(context, listen: false).updateUI();

            //move to local path
            File('$tempDir$tempName').renameSync(localPath);

            //add to db
            await Future.delayed(const Duration(seconds: 3));

            await databaseService.updateRemoteByPath(
                localPath: localPath,
                type: FileType.file,
                remoteId: file.remotefileId,
                remoteTimeStamp: file.mtime
            );


          }else{

            Log.verbose('Existing Local File Found for ${file.path}');

            if(localDBData[0].toDelete == 1){
              Log.verbose('Local File marked for deletion');
              Log.verbose('Skipping....');
              continue;
            }

            //compare remote_timestamp
            if(file.mtime == localDBData[0].remoteTimestamp!){

              //if local not modified, remote renamed, timestamp don't change IDK why
              if(localDBData[0].localModified == 0 && localDBData[0].localPath != localPath){

                File(localDBData[0].localPath).renameSync(localPath);
                Log.verbose('Renamed File for ${file.path}');
              }

              Log.verbose('Remote File Not Updated for ${file.path}');
              Log.verbose('Skipping Download ${file.path}');
              Provider.of<SyncProvider>(context, listen: false).change!.files[index].syncStatus = SyncStatus.success;
              Provider.of<SyncProvider>(context, listen: false).updateUI();
              continue;
            }

            Log.verbose('Remote File Updated for ${file.path}');
            Log.verbose('Preparing Download for ${file.path}');

            //update UI
            Provider.of<SyncProvider>(context, listen: false).change!.files[index].syncStatus = SyncStatus.syncing;
            Provider.of<SyncProvider>(context, listen: false).change!.files[index].errorMessage = null;
            Provider.of<SyncProvider>(context, listen: false).updateUI();

            try{
              print('wush');
              //todo check if file is open
              final raf = File(localDBData[0].localPath).renameSync(localDBData[0].localPath);

            } catch (e) {
              Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
                  syncType: SyncType.modifiedFile,
                  index: index,
                  status: SyncStatus.failed,
                  message: 'File is current opened'
              );
              continue;
            }
            //download to temp
            bool? result = await FileService.download(fileId: file.remotefileId, tempName: tempName);

            if(result == null){
              throw 'download failed';
            }

            //if local modified
            if(localDBData[0].localModified == 1  && await File(localDBData[0].localPath).length() != file.size){

              //rename local file
              String renamed = localDBData[0].localPath.toString().renameWithTimestamp();

              File(localDBData[0].localPath).renameSync(renamed);

              await Future.delayed(const Duration(seconds: 3));

              await databaseService.updateRemoteNullByPath(
                  mimetype: file.mimetype,
                  localPath: renamed
              );
            }

            //move downloaded temp to replace new file
            File('$tempDir$tempName').renameSync(localPath);

            await Future.delayed(const Duration(seconds: 3));

            await databaseService.updateRemoteByPath(
              localPath: localPath,
              type: FileType.file,
              remoteId: file.remotefileId,
              remoteTimeStamp: file.mtime,
            );

          }

        }

        Provider.of<SyncProvider>(context, listen: false).change!.files[index].syncStatus = SyncStatus.success;
        Provider.of<SyncProvider>(context, listen: false).change!.files[index].errorMessage = '';
        Provider.of<SyncProvider>(context, listen: false).updateUI();

      }catch(e){
        Provider.of<SyncProvider>(context, listen: false).change!.files[index].syncStatus = SyncStatus.failed;
        Provider.of<SyncProvider>(context, listen: false).change!.files[index].errorMessage = e.toString();
        continue;
      }

    }

    int? lastDelete = await LocalStorage.getLastDelete();

    if(lastDelete != null && DateTime.now().millisecondsSinceEpoch <  lastDelete + 60000){ // 1min
      return true;
    }

    LocalStorage.setLastDelete(DateTime.now().millisecondsSinceEpoch);

    for (FilesDeleted fileToDelete in change.filesDeleted){

      //search in files first
      bool isFile = true;
      List<FileFolderInfo> toDelete = await databaseService.queryByRemoteId(remoteId: fileToDelete.fileid, mimetype: 0);

      //if empty search in folders instead
      if(toDelete.isEmpty){
        isFile = false;
        Log.error('not found files, searching in folders');
        toDelete = await databaseService.queryByRemoteId(remoteId: fileToDelete.fileid, mimetype: 2);

      }

      if(toDelete.isEmpty){
        Log.error('File to delete with id ${fileToDelete.fileid} not found');
        continue;
      }

      try{

        if(isFile){
          File(toDelete[0].localPath).deleteSync();
          databaseService.deleteFile(path: toDelete[0].localPath, forceDelete: true);
        }
        else {
          Directory(toDelete[0].localPath).deleteSync(recursive: true);
          databaseService.deleteFolder(path: toDelete[0].localPath, forceDelete: true);
        }
      } catch (e){
        print('error deleting $e');
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
    Log.info('Sync Local -> Remote started');
    Provider.of<SyncProvider>(context, listen: false).updateUI();

    await syncLocalFileFolderWithLocalDb();
    await _uploadModifiedFoldersAndFiles(context);
    await syncLocalFileFolderWithLocalDb();
    await _uploadNewFoldersAndFiles(context);
    await syncLocalFileFolderWithLocalDb();
    await _deleteFoldersAndFiles(context);


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
  print('modified folders ${modifiedFolders.length}');
  List<FileFolderInfo> modifiedFiles = await databaseService.queryModifiedFiles();
  print('modified files ${modifiedFiles.length}');

  Provider.of<SyncProvider>(context, listen: false).setModifiedFolders(modifiedFolders);
  Provider.of<SyncProvider>(context, listen: false).setModifiedFiles(modifiedFiles);

  String watchedDir = await LocalStorage.getWatchedDirectory() ?? '';

  for (var folder in modifiedFolders) {

    if(folder.toDelete == 1){
      continue;
    }

    print('weng');

    int index = modifiedFolders.indexOf(folder);

    Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
      syncType: SyncType.modifiedFolder,
      index: index,
      status: SyncStatus.syncing,
    );

    ApiResponse apiResponse = await apiService(
        serviceMethod: ServiceMethod.post,
        path: '/api/getChanges'
    );

    if(apiResponse.statusCode != 200){
      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
        syncType: SyncType.modifiedFolder,
        index: index,
        status: SyncStatus.failed,
        message: 'error calling api getChanges'
      );
      continue;
    }

    Change change = changeFromJson(jsonEncode(apiResponse.data));

    FileElement? remoteFileInfo = change.files.firstWhereOrNull((element) => element.remotefileId == folder.remoteId);

    if(remoteFileInfo == null){
      continue;
    }

    String localFolderName = folder.localPath.split('\\').last;
    String remoteFolderName = remoteFileInfo!.name;

    if(localFolderName != remoteFolderName){

      apiResponse = await apiService(
          serviceMethod: ServiceMethod.post,
          path: '/api/rename',
          data: {
            'path'      : remoteFileInfo.path.replaceFirst('files/', ''),
            'new_name'  : localFolderName
          }
      );

      if(apiResponse.statusCode != 200){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
            syncType: SyncType.modifiedFolder,
            index: index,
            status: SyncStatus.failed,
            message: apiResponse.message ?? 'Fail to call api rename'
        );
        continue;
      }else{
        //if succeed need to refetch change

        ApiResponse apiResponse = await apiService(
            serviceMethod: ServiceMethod.post,
            path: '/api/getChanges'
        );

        if(apiResponse.statusCode != 200){
          Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
              syncType: SyncType.modifiedFolder,
              index: index,
              status: SyncStatus.failed,
              message: 'error calling api getChanges'
          );
          continue;
        }

        change = changeFromJson(jsonEncode(apiResponse.data));

        remoteFileInfo = null;

        remoteFileInfo = change.files.firstWhereOrNull((element) => element.remotefileId == folder.remoteId);

        if(remoteFileInfo == null){
          continue;
        }
      }

      databaseService.updateRemoteByPath(
          localPath: folder.localPath,
          type: FileType.directory,
          localModified: 0,
      );
    }

    String localPath = folder.localPath
        .replaceFirst(watchedDir, 'files/')
        .replaceBackSlashWithSlash()
        .removeDuplicateSlash()
        .replaceLast(localFolderName, '')
        .removeTrailingSlash();

    String remotePath = remoteFileInfo.path
        .replaceLast(localFolderName, '')
        .removeTrailingSlash();

    print('localPath: $localPath | remoteFolderPath $remotePath');

    if(localPath != remotePath){//

      int? destinationId = change.files.firstWhereOrNull((element) => element.path == localPath)?.remotefileId;

      if(destinationId == null){

        String parentPath = localPath;
        while (parentPath.isNotEmpty) {
          parentPath = parentPath.split('/').sublist(0, parentPath.split('/').length - 1).join('/');

          print('parentPath: $parentPath');

          if (!change.files.any((element) => element.path == parentPath)) {
            databaseService.updateRemoteNullByPath(
              mimetype: 2, // Assuming 2 is the mimetype for folders
              localPath: parentPath,
            );
          }
        }

        //remove remote id, timestamp for all files and folders in said directory;
        final List<FileSystemEntity> children = await Directory(watchedDir + '\\' + parentPath.removeDuplicateSlash().replacelashWithBackSlash().removeDuplicateSlash())
                                                      .list(recursive: true, followLinks: false)
                                                      .toList();

        databaseService.resetRemoteByPath(
          localPath: folder.localPath,
          type: FileType.directory,
        );

        for (var child in children) {
          if (child is Directory) {
            await databaseService.resetRemoteByPath(
                localPath: child.path,
                type: FileType.directory,
            );
          }

          if (child is File) {
            await databaseService.resetRemoteByPath(
                localPath: child.path,
                type: FileType.file,
            );
          }
        }
        //break loop and requery;
        break;
      }

      apiResponse = await apiService(
          serviceMethod: ServiceMethod.post,
          path: '/api/move',
          data: {
            'file_id'         : folder.remoteId,
            'destination_id'  : destinationId
          }
      );

      if(apiResponse.statusCode != 200){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
            syncType        : SyncType.modifiedFolder,
            index           : index,
            status          : SyncStatus.failed,
            message         : apiResponse.message ?? 'Fail to call api move'
        );
        continue;
      }

      databaseService.updateRemoteByPath(
        localPath       : folder.localPath,
        type            : FileType.directory,
        localModified   : 0,
      );

    }

    Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
      syncType: SyncType.modifiedFolder,
      index: index,
      status: SyncStatus.success,
    );
  }

  for (var file in modifiedFiles) {

    if(file.toDelete == 1){
      continue;
    }

    print('wong');

    int index = modifiedFiles.indexOf(file);

    Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
      syncType: SyncType.modifiedFile,
      index: index,
      status: SyncStatus.syncing,
    );

    try{

      //todo check if file is open
      final raf = File(file.localPath).renameSync(file.localPath);

    } catch (e) {
      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType  : SyncType.modifiedFile,
          index     : index,
          status    : SyncStatus.failed,
          message   : 'File is current opened'
      );
      continue;
    }

    ApiResponse apiResponse = await apiService(
        serviceMethod: ServiceMethod.post,
        path: '/api/getChanges'
    );

    if(apiResponse.statusCode != 200){
      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType  : SyncType.modifiedFile,
          index     : index,
          status    : SyncStatus.failed,
          message   : 'Fail to call api getChanges'
      );
      continue;
    }

    Change change = changeFromJson(jsonEncode(apiResponse.data));

    FileElement? remoteFileInfo = change.files.firstWhereOrNull((element) => element.remotefileId == file.remoteId);

    if(remoteFileInfo == null){
      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
        syncType: SyncType.modifiedFile,
        index: index,
        status: SyncStatus.failed,
        message: 'Remote file not found'
      );
      continue;
    }

    String watchedDir = await LocalStorage.getWatchedDirectory() ?? '';

    //replace all can make error if file name recursively same //todo
    String fileName = file.localPath.split('\\').last;
    String localPath = file.localPath.replaceLast('\\$fileName', '');
    String path = file.localPath.replaceFirst('$watchedDir\\', 'files/').replaceAll('\\', '/');
    print(fileName);
    print(localPath);
    print(path);
    print(remoteFileInfo.name);
    print(remoteFileInfo.path);

    if(remoteFileInfo.name != fileName){
      Log.verbose('File name different, Renaming');
      ApiResponse apiResponse = await apiService(
        serviceMethod: ServiceMethod.post,
        path: '/api/rename',
        data: {
          'path'   : remoteFileInfo.path.replaceFirst('files/', ''),
          'new_name'  : fileName
        }
      );

      if(apiResponse.statusCode != 200){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.modifiedFile,
          index: index,
          status: SyncStatus.failed,
          message: apiResponse.message ?? 'Fail to call api rename'
        );
        continue;
      }

      databaseService.updateRemoteByPath(
          localPath: file.localPath,
          type: FileType.file,
          localModified: 0
      );
    }

    apiResponse = await apiService(
        serviceMethod: ServiceMethod.post,
        path: '/api/getChanges'
    );

    if(apiResponse.statusCode != 200){
      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.modifiedFile,
          index: index,
          status: SyncStatus.failed,
          message: 'Fail to call api getChanges'
      );
      continue;
    } else {
      //if rename succeed, need to call api getChanges again
      apiResponse = await apiService(
          serviceMethod: ServiceMethod.post,
          path: '/api/getChanges'
      );

      if(apiResponse.statusCode != 200){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
            syncType  : SyncType.modifiedFile,
            index     : index,
            status    : SyncStatus.failed,
            message   : 'Fail to call api getChanges'
        );
        continue;
      }

      change = changeFromJson(jsonEncode(apiResponse.data));

      remoteFileInfo = null;

      remoteFileInfo = change.files.firstWhereOrNull((element) => element.remotefileId == file.remoteId);

      if(remoteFileInfo == null){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
            syncType: SyncType.modifiedFile,
            index: index,
            status: SyncStatus.failed,
            message: 'Remote file not found'
        );
        continue;
      }
    }

    change = changeFromJson(jsonEncode(apiResponse.data));

    remoteFileInfo = change.files.firstWhereOrNull((element) => element.remotefileId == file.remoteId);

    if(remoteFileInfo == null){
      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.modifiedFile,
          index: index,
          status: SyncStatus.failed,
          message: 'Remote file not found'
      );
      continue;
    }

    if(remoteFileInfo.path != path){

      Log.verbose('File path different, Moving');
      Log.verbose(path);
      Log.verbose(remoteFileInfo.path);

      int? destinationId = change.files.firstWhereOrNull((element) => element.path == path.replaceLast(fileName, '').removeTrailingSlash())?.remotefileId;

      destinationId ??= Provider.of<UserProvider>(context, listen: false).user?.rootParentId;

      if(destinationId == null){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
            syncType: SyncType.modifiedFile,
            index: index,
            status: SyncStatus.failed,
            message: 'Unknown move destination'
        );
        continue;
      }

      ApiResponse apiResponse = await apiService(
          serviceMethod: ServiceMethod.post,
          path: '/api/move',
          data: {
            'file_id'         : file.remoteId.toString(),
            'destination_id'  : destinationId
          }
      );

      if(apiResponse.statusCode != 200){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
            syncType    : SyncType.modifiedFile,
            index       : index,
            status      : SyncStatus.failed,
            message     : apiResponse.message ?? 'Fail to call api move'
        );
        continue;
      }

      databaseService.updateRemoteByPath(
          localPath     : file.localPath,
          type          : FileType.file,
          localModified : 0
      );
    }

    try{
      int fileSize = await File(file.localPath).length();

      print('localSize: $fileSize');
      print('remoteSize: ${remoteFileInfo.size}');

      if(fileSize != remoteFileInfo.size && remoteFileInfo.mtime == file.remoteTimestamp!){
        Log.verbose('File size different, try update');

        Map<String, dynamic>? result = await FileService.uploadChunk(
            filePath    : file.localPath,
            parentId    : remoteFileInfo.parent,
        );

        if(result == null){
          Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
            syncType    : SyncType.modifiedFile,
            index       : index,
            status      : SyncStatus.failed,
          );
          continue;
        }

        databaseService.updateRemoteByPath(
            localPath       : file.localPath,
            type            : FileType.file,
            localModified   : 0,
            remoteId        : result['id'],
            remoteTimeStamp : result['timestamp']
        );

      }

    } catch (e,s){
      Log.error(e.toString());
      Log.error(s.toString());
      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
        syncType    : SyncType.modifiedFile,
        index       : index,
        status      : SyncStatus.failed,
        message     : s.toString()
      );
      continue;
    }


    Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
      syncType      : SyncType.modifiedFile,
      index         : index,
      status        : SyncStatus.success,
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

    String watchedDir = await LocalStorage.getWatchedDirectory() ?? '';

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

      String localDirName = folder.localPath.split('\\').last;
      String localParent = folder.localPath.replaceLast(localDirName, '').removeTrailingSlash();

      String path = localParent
                      .replaceFirst(watchedDir, '')
                      .replaceBackSlashWithSlash()
                      .removeDuplicateSlash()
                      .removeLeadingSlash();

      print(localDirName);
      print(localParent);
      print(path);

      ApiResponse apiResponse = await apiService(
          serviceMethod: ServiceMethod.post,
          path: '/api/create',
          data: {
            'path': path,
            'name': folder.localPath.split('\\').last,
          }
      );

      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
        syncType: SyncType.newFolder,
        index: index,
        status: apiResponse.statusCode == 200 ? SyncStatus.success : SyncStatus.failed,
      );

      if(apiResponse.statusCode == 200) {
        
        final data = jsonDecode(jsonEncode(apiResponse.data));
        
        databaseService.updateRemoteByPath(
            localPath       : folder.localPath,
            type            : FileType.directory,
            localModified   : 0,
            remoteId        : HashIdService.instance.decode(data['data']['id']),
            //todo return timestamp
            remoteTimeStamp : 21323
        );
      }
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
      
      ApiResponse apiResponse = await apiService(
          serviceMethod: ServiceMethod.post,
          path: '/api/getChanges'
      );
      
      if(apiResponse.statusCode != 200){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.newFile,
          index: index,
          status: SyncStatus.failed,
          message: 'Fail to call api getChanges'
        );
        continue;
      }
      
      Change change = changeFromJson(jsonEncode(apiResponse.data));

      String fileName = file.localPath.split('\\').last;
      String localPath = file.localPath.replaceLast(fileName, '').removeTrailingSlash();
      String path = localPath.replaceFirst(watchedDir, 'files/').replaceBackSlashWithSlash().removeDuplicateSlash();
      print(fileName);
      print(localPath);
      print(path);

      int? parentId = change.files.firstWhereOrNull((element) => element.path == path)?.remotefileId;

      //if parent not found in first try, find where if eg path == files/eg . when we replace (files/) -> we left with (eg) only without any /. then the parents is root
      //fallback
      parentId ??= change.files.firstWhereOrNull((element) => !element.path.replaceFirst('files/', '').contains('/'))?.parent;

      parentId ??= Provider.of<UserProvider>(context, listen: false).user!.rootParentId;

      if(parentId == null){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.newFile,
          index: index,
          status: SyncStatus.failed,
          message: 'Parent Folder not found'
        );
        continue;
      }

      Map<String, dynamic>? result = await FileService.uploadChunk(
          filePath: file.localPath,
          parentId: parentId
      );

      print('result $result');

      if(result == null){
        Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
          syncType: SyncType.newFile,
          index: index,
          status: SyncStatus.failed,
          message: 'API error'
        );
        continue;
      }

      databaseService.updateRemoteByPath(
          localPath       : file.localPath,
          type            : FileType.file,
          localModified   : 0,
          remoteId        : result['id'],
          remoteTimeStamp : result['timestamp']
      );

      // final List<FileSystemEntity> chunks = await Directory('$tempDir$fileUuid')
      //     .list(recursive: false, followLinks: false)
      //     .toList();
      //
      // int currentChunk = 0;
      // double lastUpdatePercent = 0;
      //
      // for(var chunk in chunks){
      //
      //   await Future.delayed(Duration(milliseconds: 100));
      //
      //   double currentPercent = ((currentChunk/chunks.length)*100);
      //
      //   if(currentPercent - lastUpdatePercent > 5 || currentPercent == 100){
      //     Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
      //       syncType: SyncType.newFile,
      //       index: index,
      //       status: SyncStatus.syncing,
      //       progress: currentPercent
      //     );
      //     lastUpdatePercent = currentPercent;
      //   }
      //
      //   Log.verbose('Upload chunk ${currentPercent.toInt()}%');
      //
      //   currentChunk++;
      // }

      Provider.of<SyncProvider>(context, listen: false).updateSyncStatus(
        syncType: SyncType.newFile,
        index: index,
        status: SyncStatus.success,
      );

    }


  }

  static _deleteFoldersAndFiles(context) async {

    DatabaseService databaseService = DatabaseService();

    List<FileFolderInfo> filesToDelete    = await databaseService.queryDeletedFiles();
    List<FileFolderInfo> foldersToDelete  = await databaseService.queryDeletedFolders();

    String watchedDir = await LocalStorage.getWatchedDirectory() ?? '';

    for (var file in filesToDelete) {

      ApiResponse apiResponse = await apiService(
          serviceMethod: ServiceMethod.post,
          path: '/api/destroy',
          data: {
            'path': file.localPath.replaceFirst(watchedDir, 'files/').toString().replaceBackSlashWithSlash().toString().removeDuplicateSlash().removeTrailingSlash().removeLeadingSlash().replaceFirst('files/', '')
          }
      );

      if(![200,482].contains(apiResponse.statusCode)){
        Log.error(apiResponse.message.toString());
        continue;
      }

      Log.verbose('File ${file.localPath} successfully deleted in server');

      await databaseService.deleteFile(
          path: file.localPath,
          forceDelete: true
      );

    }

    for (var folder in foldersToDelete) {

      ApiResponse apiResponse = await apiService(
          serviceMethod: ServiceMethod.post,
          path: '/api/destroy',
          data: {
            'path': folder.localPath.replaceFirst(watchedDir, 'files/').toString().replaceBackSlashWithSlash().toString().removeDuplicateSlash().removeTrailingSlash().removeLeadingSlash().replaceFirst('files/', '')
          }
      );

      if(![200,482].contains(apiResponse.statusCode)){
        Log.error(apiResponse.message.toString());
        continue;
      }

      Log.verbose('File ${folder.localPath} successfully deleted in server');

      await databaseService.deleteFolder(
          path: folder.localPath,
          forceDelete: true
      );

    }
  }
}