import 'package:flutter/services.dart';
import 'package:pdwatcher/utils/consts.dart';

import 'log_service.dart';

abstract class DriveInfo {
  static const platform = MethodChannel('com.example.driveinfo');

  static Future<bool> getDriveName() async {
    try {
      final String driveName = await platform.invokeMethod('getDriveName');

      baseDir = '${driveName}/pdwatcher/';

      return true;


    } on PlatformException catch (e) {
      Log.error("Failed to get drive name: '${e.message}'.");
      return false;

    }
  }
}
