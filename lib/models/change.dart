// To parse this JSON data, do
//
//     final change = changeFromJson(jsonString);

import 'dart:convert';

import 'package:pdwatcher/utils/enums.dart';

Change changeFromJson(String str) => Change.fromJson(json.decode(str));

String changeToJson(Change data) => json.encode(data.toJson());

class Change {
  List<FileElement> files;
  List<FilesDeleted> filesDeleted;
  List<FileElement> shareFile;

  Change({
    required this.files,
    required this.filesDeleted,
    required this.shareFile,
  });

  factory Change.fromJson(Map<String, dynamic> json) => Change(
    files: List<FileElement>.from(json["files"].map((x) => FileElement.fromJson(x))),
    filesDeleted: List<FilesDeleted>.from(json["files_deleted"].map((x) => FilesDeleted.fromJson(x))),
    shareFile: List<FileElement>.from(json["share_file"].map((x) => FileElement.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "files": List<dynamic>.from(files.map((x) => x.toJson())),
    "files_deleted": List<dynamic>.from(filesDeleted.map((x) => x.toJson())),
    "share_file": List<dynamic>.from(shareFile.map((x) => x.toJson())),
  };
}

class FileElement {
  int remotefileId;
  int storage;
  String path;
  String pathHash;
  int parent;
  String name;
  int mimetype;
  int mimepart;
  int size;
  int mtime;
  int storageMtime;
  int encrypted;
  int unencryptedSize;
  String etag;
  int permissions;
  int createBy;
  int modifyBy;
  DateTime? updatedAt;
  DateTime? createdAt;
  SyncStatus? syncStatus;
  String? errorMessage;

  FileElement({
    required this.remotefileId,
    required this.storage,
    required this.path,
    required this.pathHash,
    required this.parent,
    required this.name,
    required this.mimetype,
    required this.mimepart,
    required this.size,
    required this.mtime,
    required this.storageMtime,
    required this.encrypted,
    required this.unencryptedSize,
    required this.etag,
    required this.permissions,
    required this.createBy,
    required this.modifyBy,
    required this.updatedAt,
    required this.createdAt,
    this.syncStatus,
    this.errorMessage,
  });

  factory FileElement.fromJson(Map<String, dynamic> json) => FileElement(
    remotefileId: json["fileid"],
    storage: json["storage"],
    path: json["path"],
    pathHash: json["path_hash"],
    parent: json["parent"],
    name: json["name"],
    mimetype: json["mimetype"],
    mimepart: json["mimepart"],
    size: json["size"],
    mtime: json["mtime"],
    storageMtime: json["storage_mtime"],
    encrypted: json["encrypted"],
    unencryptedSize: json["unencrypted_size"],
    etag: json["etag"],
    permissions: json["permissions"],
    createBy: json["create_by"],
    modifyBy: json["modify_by"],
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
  );

  Map<String, dynamic> toJson() => {
    "fileid": remotefileId,
    "storage": storage,
    "path": path,
    "path_hash": pathHash,
    "parent": parent,
    "name": name,
    "mimetype": mimetype,
    "mimepart": mimepart,
    "size": size,
    "mtime": mtime,
    "storage_mtime": storageMtime,
    "encrypted": encrypted,
    "unencrypted_size": unencryptedSize,
    "etag": etag,
    "permissions": permissions,
    "create_by": createBy,
    "modify_by": modifyBy,
    "updated_at": updatedAt?.toIso8601String(),
    "created_at": createdAt?.toIso8601String(),
    "sync_status": syncStatus.toString(),
    "error_message": errorMessage,
  };
}

class FilesDeleted {
  int id;
  int fileid;
  int storage;

  FilesDeleted({
    required this.id,
    required this.fileid,
    required this.storage,
  });

  factory FilesDeleted.fromJson(Map<String, dynamic> json) => FilesDeleted(
    id: json["id"],
    fileid: json["fileid"],
    storage: json["storage"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "fileid": fileid,
    "storage": storage,
  };
}
