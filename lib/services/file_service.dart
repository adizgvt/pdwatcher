import 'dart:convert';
import 'dart:io';
import 'dart:core';
import 'package:background_downloader/background_downloader.dart';
import 'package:chunked_uploader/chunked_uploader.dart';
import 'package:custom_platform_device_id/platform_device_id.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../models/api_response.dart';
import '../utils/consts.dart';
import '../utils/enums.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'log_service.dart';

class FileService {

  static Future<bool?> download({required fileId , required tempName}) async {

    String domain   = await LocalStorage.getServerUrl() ?? '';
    String token    = await LocalStorage.getToken() ?? '';

    // ApiResponse apiResponse = await apiService(
    //     serviceMethod: ServiceMethod.download,
    //     path: '/api/download',
    //     tempName: tempName,
    //     data: {
    //       'file_id': fileId.toString(),
    //     }
    // );
    //
    // if(apiResponse.statusCode != 200){
    //   return true;
    // }
    //
    // return null;

    final task = DownloadTask(
        url: Uri.encodeFull('$domain/api/download?file_id=$fileId'),
        headers: {
          'Authorization' : 'Bearer $token',
          'Content'       : 'application/json',
          'Accept': 'application/octet-stream',
        },
        post: {
          'file_id'   : fileId.toString(),
          'hostname'  : Platform.localHostname,
          'uuid'      : await PlatformDeviceId.getDeviceId,
        },
        filename: tempName,
        directory: tempDir,
        updates: Updates.statusAndProgress, // request status and progress updates
        requiresWiFi: true,
        retries: 1,
        metaData: 'data for me'
    );

    // Start download, and wait for result. Show progress and status changes
    // while downloadingf

    final result = await FileDownloader().download(task,
        onProgress: (progress) {
          Log.verbose('Progress: ${progress * 100}%');
        },
        onStatus: (status) => Log.verbose('Status: $status'),
        elapsedTimeInterval: const Duration(seconds: 10),
        onElapsedTime: (Duration duration) async {
          Log.verbose(duration.toString());
          // ApiResponse response = await apiService(serviceMethod: ServiceMethod.get, path: '/test');
          // if(response.statusCode != 200){
          //   ApiResponse apiResponse = ApiResponse(); //dummy response
          //   apiResponse.message = "Download fail. please check connection";
          //   FileDownloader().cancelTasksWithIds(await FileDownloader().allTaskIds());
          // }
        }
    );

    Log.verbose(const JsonEncoder.withIndent('  ').convert(task.toJson()));
    Log.verbose(const JsonEncoder.withIndent('  ').convert(result.toJson()));

    ApiResponse apiResponse = ApiResponse();
    // Act on the result
    switch (result.status) {
      case TaskStatus.complete:
        print('---------');
        print(task);
        print(await task.filePath());
        print('---------');
        apiResponse.message = 'File successfully downloaded';

      case TaskStatus.canceled:
        apiResponse.message = 'Download canceled';

      case TaskStatus.paused:
        print('Download was paused');

      default:
        apiResponse.message = 'Download not successful';
    }

    Log.verbose(apiResponse.message.toString());

    if(result.status == TaskStatus.complete) {
      return true;
    }
    return null;
  }
  
  static Future<Map<String, dynamic>?> upload({required String filePath, required Map<String,String> data}) async {

    String domain   = await LocalStorage.getServerUrl() ?? '';
    String token    = await LocalStorage.getToken() ?? '';

    String fileName = filePath.split('\\').last;

    final dio = Dio(BaseOptions(
      baseUrl: domain,
      headers: {
        'Authorization' : 'Bearer $token',
        'Accept'        : 'application/json'
      },
      validateStatus: ((int? status) => true)
    ));
    
    ChunkedUploader uploader = ChunkedUploader(dio);

    Response? response = await uploader.uploadUsingFilePath(
      data: data,
      fileName: fileName,
      filePath: filePath,
      maxChunkSize: 100000,
      path: '/api/upload',
      onUploadProgress: (progress) => print(progress),
    );

    if(response == null){
      return null;
    }

    Log.verbose(response.statusCode.toString());
    Log.verbose(response.toString());

    if(![200,201].contains(response.statusCode)){
      return null;
    }

    final uploadResponse = response.data;

    return {
      'id'        : uploadResponse['fileid'],
      'timestamp' : uploadResponse['mtime'],
      'mimetype'  : uploadResponse['mimetype'],
    };

  }

  static String? copyToTempAndChunk({
    required String filePath,
  }){

    try {

      //open file
      var filex = File(filePath);
      var raf = filex.openSync(mode: FileMode.read);

      //lock file
      raf.lockSync(FileLock.shared);
      Log.warning('!!! Locked   file $filePath');

      var uuid = const Uuid();

      //-------------------------------------------------
      int offset = 0;
      int fileLength = raf.lengthSync();
      int chunkSize = 1024 * 4 * 100;
      String tempName = uuid.v1();

      while (offset < fileLength) {
        int end = offset + chunkSize;
        if (end > fileLength) {
          end = fileLength;
        }

        raf.setPositionSync(offset);
        List<int> chunk = raf.readSync(end - offset);

        //create new temp dir for the file
        final directory = Directory('$tempDir$tempName');
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        String chunkPath = '$tempDir$tempName\\$offset#$end#$tempName';

        File file = File(chunkPath);
        if (!file.existsSync()) {
          file.createSync(recursive: false);
        }
        file.writeAsBytesSync(chunk);
        Log.verbose('Wrote chunk for $filePath at $chunkPath');

        offset = end;
      }

      raf.unlockSync();
      raf.closeSync();
      Log.warning('!!! Unlocked file $filePath');
      Log.info('!!! -----------------------------------------------------------');

      return tempName;

    } catch (e,s){
      Log.error(e.toString());
      Log.error(s.toString());
      return null;
    }

  }

}