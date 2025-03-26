import 'dart:convert';
import 'dart:io';
import 'dart:core';
import 'package:background_downloader/background_downloader.dart';
import 'package:chunked_uploader/chunked_uploader.dart';
import 'package:custom_platform_device_id/platform_device_id.dart';
import 'package:dio/dio.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../models/current_task.dart';
import '../providers/task_provider.dart';
import '../utils/consts.dart';
import 'local_storage_service.dart';
import 'log_service.dart';

class FileService {

  static Future<bool?> download({
    required int fileId,
    required String tempName,
    required String cloudPath,
    required BuildContext context,
  }) async {
    String domain = await LocalStorage.getServerUrl() ?? '';
    String token = await LocalStorage.getToken() ?? '';

    final task = DownloadTask(
      url: Uri.encodeFull('$domain/api/download?file_id=$fileId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content': 'application/json',
        'Accept': 'application/octet-stream',
      },
      post: {
        'file_id': fileId.toString(),
        'hostname': await LocalStorage.getLocalHostname(),
        'uuid': await LocalStorage.getDeviceId(),
      },
      filename: tempName,
      directory: tempDir,
      updates: Updates.statusAndProgress,
      requiresWiFi: true,
      retries: 1,
      metaData: 'data for me',
    );

    Provider.of<TaskProvider>(context, listen: false).updateAction(TaskAction.download);
    Provider.of<TaskProvider>(context, listen: false).updateFilename(cloudPath);

    final result = await FileDownloader().download(
      task,
      onProgress: (progress) {
        Log.verbose('Progress: ${progress * 100}%');
        double percentageProgress = progress * 100;
        Provider.of<TaskProvider>(context, listen: false).updateProgress(percentageProgress);
      },
      onStatus: (status) {
        Log.verbose('Status: $status');
        if (status == TaskStatus.canceled || status == TaskStatus.paused) {
          Provider.of<TaskProvider>(context, listen: false).updateProgress(0);
        }
      },
      elapsedTimeInterval: const Duration(seconds: 10),
      onElapsedTime: (Duration duration) async {
        Log.verbose(duration.toString());
      },
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

        break;

      case TaskStatus.canceled:
        apiResponse.message = 'Download canceled';
        break;

      case TaskStatus.paused:
        print('Download was paused');
        apiResponse.message = 'Download paused';
        break;

      default:
        apiResponse.message = 'Download not successful';
        break;
    }

    Provider.of<TaskProvider>(context, listen: false).updateProgress(0);

    Log.verbose(apiResponse.message.toString());

    if (result.status == TaskStatus.complete) {
      return true;
    }

    return null;
  }

  static Future<Map<String, dynamic>?> upload({
    required String filePath,
    required int parentId,
    required context
  }) async {

    //return uploadSingleFile(filePath: filePath, parentId: parentId);
    return uploadChunk(filePath: filePath, parentId: parentId, context: context);
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
        'hostname'  : await LocalStorage.getLocalHostname(),
        'uuid'      : await LocalStorage.getDeviceId(),
      },
      fileName: fileName,
      filePath: filePath,
      maxChunkSize: 100000,
      path: '/api/upload',
      onUploadProgress: (progress) => Log.verbose('Upload Progress: $progress'),
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
    required BuildContext context,  // Pass the context to access the TaskProvider
  }) async {

    final domain    = await LocalStorage.getServerUrl() ?? '';
    final token     = await LocalStorage.getToken() ?? '';
    final fileName  = filePath.split('\\').last;

    const int chunkSize = 1024 * 1024 * 10; //10MB
    final String uuid = const Uuid().v1();

    final File file       = File(filePath);
    final int fileLength  = await file.length();
    final int totalChunks = (fileLength / chunkSize).ceil();

    Map<String, dynamic>? lastResponse;

    Provider.of<TaskProvider>(context, listen: false).updateAction(TaskAction.upload);
    Provider.of<TaskProvider>(context, listen: false).updateFilename(filePath);

    for (int i = 0; i < totalChunks; i++) {
      final int start = i * chunkSize;
      final int end = (start + chunkSize < fileLength) ? start + chunkSize : fileLength;
      final List<int> chunkData = await file.openRead(start, end).toList().then((chunks) => chunks.expand((x) => x).toList());

      final request = http.MultipartRequest('POST', Uri.parse('$domain/api/upload'))
        ..headers['Authorization']      = 'Bearer $token'
        ..headers['Accept']             = 'application/json'
        ..fields['hostname']            = await LocalStorage.getLocalHostname() ?? ''
        ..fields['uuid']                = await LocalStorage.getDeviceId() ?? ''
        ..fields['dzuuid']              = uuid
        ..fields['dzchunkindex']        = i.toString()
        ..fields['dztotalchunkcount']   = totalChunks.toString()
        ..fields['parent_id']           = parentId.toString()
        ..files.add(http.MultipartFile.fromBytes('file', chunkData, filename: fileName));

      final response      = await request.send();
      final responseBody  = await http.Response.fromStream(response);

      Log.verbose('Uploading chunk ${i + 1}/$totalChunks');
      print('Response Status Code : ${responseBody.statusCode}');
      print('Response Body        : ${responseBody.body}');

      if (![200, 201].contains(responseBody.statusCode)) {
        print('Upload failed for chunk $i with status code: ${responseBody.statusCode}');
        return null;
      }

      // Update progress in the provider after each chunk upload
      double progress = ((i + 1) / totalChunks) * 100; // Calculate progress in percentage
      Provider.of<TaskProvider>(context, listen: false).updateProgress(progress);

      if (i == totalChunks - 1) {
        try {
          final uploadResponse = jsonDecode(responseBody.body) as Map<String, dynamic>;

          lastResponse = {
            'id'        : uploadResponse['fileid'],
            'timestamp' : uploadResponse['mtime'],
            'mimetype'  : uploadResponse['mimetype'],
          };
        } catch (e, s) {
          print('Failed to decode response: $e ${s}');
          return null;
        }
        finally {
          Provider.of<TaskProvider>(context, listen: false).updateProgress(0);
        }
      } else {
        lastResponse = null;
      }
    }

    return lastResponse; // Return the response of the last chunk
  }


static void moveFile(String sourcePath, String destinationPath) {

    try {
      File sourceFile = File(sourcePath);
      File destinationFile = File(destinationPath);

      // Open file streams and copy data directly
      var inputStream = sourceFile.openSync();
      var outputStream = destinationFile.openSync(mode: FileMode.write);

      List<int> buffer = List<int>.filled(1024 * 1024, 0); // 1MB buffer
      int bytesRead;
      while ((bytesRead = inputStream.readIntoSync(buffer)) > 0) {
        outputStream.writeFromSync(buffer, 0, bytesRead);
      }

      inputStream.closeSync();
      outputStream.closeSync();

    } catch (e) {
      print('Error moving file: $e');
    }
  }

}