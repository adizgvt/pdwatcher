import 'dart:convert';
import 'dart:io';
import 'dart:core';
import 'package:background_downloader/background_downloader.dart';
import 'package:chunked_uploader/chunked_uploader.dart';
import 'package:custom_platform_device_id/platform_device_id.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../utils/consts.dart';
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

  static Future<Map<String, dynamic>?> upload({
    required String filePath,
    required int parentId,
  }) async {

    return uploadSingleFile(filePath: filePath, parentId: parentId);
    //return uploadChunk(filePath: filePath, parentId: parentId);
  }

  static Future<Map<String, dynamic>?> uploadSingleFile({
    required String filePath,
    required int parentId,
  }) async {
    Log.verbose('uploading file');
    String domain = await LocalStorage.getServerUrl() ?? '';
    String token = await LocalStorage.getToken() ?? '';

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
      data: {
        'parent_id': parentId.toString(),
        'hostname': Platform.localHostname,
        'uuid': await PlatformDeviceId.getDeviceId,
      },
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

  //-------------------------
  //-------------------------
  //-------------------------
  //-------------------------
  //-------------------------

  static Future<Map<String, dynamic>?> uploadChunk({
    required String filePath,
    required int parentId,
  }) async {

    final domain    = await LocalStorage.getServerUrl() ?? '';
    final token     = await LocalStorage.getToken() ?? '';
    final fileName  = filePath.split('\\').last;

    const int chunkSize = 1024 * 1024;
    final String uuid = const Uuid().v1();

    final File file       = File(filePath);
    final int fileLength  = await file.length();
    final int totalChunks = (fileLength / chunkSize).ceil();

    Map<String, dynamic>? lastResponse;

    for (int i = 0; i < totalChunks; i++) {
      final int start = i * chunkSize;
      final int end = (start + chunkSize < fileLength) ? start + chunkSize : fileLength;
      final List<int> chunkData = await file.openRead(start, end).toList().then((chunks) => chunks.expand((x) => x).toList());

      final request = http.MultipartRequest('POST', Uri.parse('$domain/api/upload'))
        ..headers['Authorization']      = 'Bearer $token'
        ..headers['Accept']             = 'application/json'
        ..fields['hostname']            = Platform.localHostname
        ..fields['uuid']                = await PlatformDeviceId.getDeviceId ?? ''
        ..fields['dzuuid']              = uuid
        ..fields['dzchunkindex']        = i.toString()
        ..fields['dztotalchunkcount']   = totalChunks.toString()
        ..fields['parent_id']           = parentId.toString()
        ..files.add(http.MultipartFile.fromBytes('file', chunkData, filename: fileName));

      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      print('chunk ${i+1}/$totalChunks');
      print('Response Status Code: ${responseBody.statusCode}');
      print('Response Body : ${responseBody.body}');

      if (![200, 201].contains(responseBody.statusCode)) {
        print('Upload failed for chunk $i with status code: ${responseBody.statusCode}');
        return null;
      }

      if (i == totalChunks - 1) {
        try {
          final uploadResponse = jsonDecode(responseBody.body) as Map<String, dynamic>;

          lastResponse = {
            'id'        : uploadResponse['data']['fileid'],
            'timestamp' : uploadResponse['data']['mtime'],
            'mimetype'  : uploadResponse['data']['mimetype'],
          };
        } catch (e) {
          print('Failed to decode response: $e');
          return null;
        }
      } else {
        lastResponse = null;
      }
    }

    return lastResponse; // Return the response of the last chunk
  }

}