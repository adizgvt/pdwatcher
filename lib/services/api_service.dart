import 'dart:convert';
import 'package:chunked_uploader/chunked_uploader.dart';
import 'package:custom_platform_device_id/platform_device_id.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pdwatcher/services/local_storage_service.dart';
import '../models/api_response.dart';
import '../utils/consts.dart';
import '../utils/enums.dart';
import 'dart:io' show Platform;

import 'log_service.dart';

Future<ApiResponse> apiService({
  Map<String, dynamic>? data,
  required ServiceMethod serviceMethod,
  required String path,
  String? baseUrl,
  String tempName = ''
}) async {

  if(data != null){
    data.addAll({
      //todo flashes CMD change
      'hostname'  : await LocalStorage.getLocalHostname(),
      'uuid'      : await LocalStorage.getDeviceId(),
    });
  }else{
    data = {
      'hostname'  : await LocalStorage.getLocalHostname(),
      'uuid'      : await LocalStorage.getDeviceId(),
    };
  }

  ApiResponse apiResponse = ApiResponse(); //output response
  Response? response; //Dio response

  String serverUrl = baseUrl ?? await LocalStorage.getServerUrl() ?? '';

  final baseOptions = BaseOptions(
    baseUrl: serverUrl,
    contentType: Headers.jsonContentType,
    headers: {
      Headers.acceptHeader: 'application/json',
      'Authorization': 'Bearer ${await LocalStorage.getToken()}',
    },
    validateStatus: (int? status) => true,
  );

  // final options =  CacheOptions(
  //     store: kIsWeb ? MemCacheStore() : HiveCacheStore(AppPathProvider.path),
  //     policy: CachePolicy.refreshForceCache,
  //     hitCacheOnErrorExcept: [],
  //     maxStale: const Duration(days: 7),
  //     priority: CachePriority.high
  // );
  //
   final dio = Dio(baseOptions);
  //   ..interceptors.add(DioCacheInterceptor(options: options));

  try {

    switch (serviceMethod) {
      case ServiceMethod.post:
        response = await dio.post(path, data: data);
        break;

      case ServiceMethod.put:
        response = await dio.put(path, data: data);
        break;

      case ServiceMethod.delete:
        response = await dio.delete(path, data: data);
        break;

      case ServiceMethod.download:
        response = await dio.download(
            path,
            '$tempDir$tempName',
            data: data,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                Log.verbose(((received / total) * 100).toString());
              }
            },
          options: Options(
            method: 'POST',
            responseType: ResponseType.bytes
          )
        );
        break;

      case ServiceMethod.upload:
        break;

      default:
        response = await dio.get(path, queryParameters: data);
    }
    //PRINT LOGS
    if(kDebugMode/* && path != '/api/getChanges'*/) {

      print(serverUrl + path);
      print('------------------------REQUEST DATA--------------------------------');
      print(const JsonEncoder.withIndent('  ').convert(data));

      print('--------------------RESPONSE STATUS ${response?.statusCode}-----------------------------');
      if(response != null && response.data != null){
        print(const JsonEncoder.withIndent('  ').convert(response?.data));
      }

    }
    apiResponse.statusCode = response?.statusCode;
    apiResponse.data = response?.data;
    apiResponse.message = response?.data['message'] ?? response?.data['error'] ?? 'Unknown error';

  } catch (e, stacktrace) {

    if (e is DioException) {
      print('----------------');
      print(e.error.toString());
      print(e.response?.data);
      print(e.response?.statusMessage);
      print(e.response?.statusCode);
      print(e.stackTrace);
      print('----------------');
      apiResponse.message = e.response?.data['message'] ?? e.error.toString();
      apiResponse.errors = e.response?.data['errors'] == null ? null : Errors.fromJson(e.response?.data['errors']);
    }
  }
  return apiResponse;
}