
import 'package:pdwatcher/utils/enums.dart';

class FileFolderInfo {
  final int id;
  final String localPath;
  final int localTimestamp;
  final int localModified;
  final int? remoteId;
  final int? remoteTimestamp;
  SyncStatus? syncStatus;
  String? message;
  double? syncProgress;

  FileFolderInfo({
    required this.id,
    required this.localPath,
    required this.localTimestamp,
    required this.localModified,
    this.remoteId,
    this.remoteTimestamp,
    this.syncStatus,
  });

  // Factory method to create an instance of FileFolderInfo from a map
  factory FileFolderInfo.fromMap(Map<String, dynamic> map) {
    return FileFolderInfo(
      id: map['id'],
      localPath: map['local_path'],
      localTimestamp: map['local_timestamp'],
      localModified: map['local_modified'],
      remoteId: map['remote_id'],
      remoteTimestamp: map['remote_timestamp'],  // Default syncStatus if not provided
    );
  }

  // Method to convert the object back to a map (optional)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'local_path': localPath,
      'local_timestamp': localTimestamp,
      'local_timestamp': localModified,
      'remote_id': remoteId,
      'remote_timestamp': remoteTimestamp,
      'sync_status': syncStatus,  // Include syncStatus in the map
    };
  }

  @override
  String toString() {
    return 'FileFolderInfo{id: $id, localPath: $localPath, localTimestamp: $localTimestamp, remoteId: $remoteId, remoteTimestamp: $remoteTimestamp, syncStatus: $syncStatus}';
  }
}
