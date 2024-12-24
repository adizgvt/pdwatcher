import 'package:fluent_ui/fluent_ui.dart';
import 'package:pdwatcher/models/FileFolderInfo.dart';

import '../utils/enums.dart';
import '../utils/types.dart';


class SyncProvider extends ChangeNotifier {

  List<FileFolderInfo> newFolders      = [];
  List<FileFolderInfo> newFiles        = [];
  List<FileFolderInfo> modifiedFolders = [];
  List<FileFolderInfo> modifiedFiles   = [];

  bool isSyncPaused = false;

  bool isSyncing = false;

  bool isOffline = false;

  int? uploadProgress;

  List<dynamic> ignoreList = [];

  void setOffline() {
    isOffline = true;
    notifyListeners();
  }

  void setOnline() {
    isOffline = false;
    notifyListeners();
  }

  void setPause() {
    isSyncPaused = true;
    notifyListeners();
  }

  void setResume() {
    isSyncPaused = false;
    notifyListeners();
  }

  void setNewFolders(List<FileFolderInfo> folders) {
    newFolders = folders;
    notifyListeners();
  }

  void setNewFiles(List<FileFolderInfo> files) {
    newFiles = files;
    notifyListeners();
  }

  void setModifiedFolders(List<FileFolderInfo> folders) {
    modifiedFolders = folders;
    notifyListeners();
  }

  void setModifiedFiles(List<FileFolderInfo> files) {
    modifiedFiles = files;
    notifyListeners();
  }

  void updateUI(){
    notifyListeners();
  }

  void updateSyncStatus({
  required SyncType syncType,
  required int index,
  required SyncStatus status,
  String? message,
  double? progress}) {

    switch (syncType) {
      case SyncType.newFolder:
                              newFolders[index].syncStatus        = status;
        if(message != null)   newFolders[index].message           = message;
        if(progress != null)  newFolders[index].syncProgress      = progress;
        break;
      case SyncType.newFile:
                              newFiles[index].syncStatus          = status;
        if(message != null)   newFiles[index].message             = message;
        if(progress != null)  newFiles[index].syncProgress        = progress;
        break;
      case SyncType.modifiedFolder:
                              modifiedFolders[index].syncStatus   = status;
        if(message != null)   modifiedFolders[index].message      = message;
        if(progress != null)  modifiedFolders[index].syncProgress = progress;
        break;
      case SyncType.modifiedFile:
                              modifiedFiles[index].syncStatus     = status;
        if(message != null)   modifiedFiles[index].message        = message;
        if(progress != null)  modifiedFiles[index].syncProgress   = progress;
        break;
    }
    notifyListeners();
  }



}