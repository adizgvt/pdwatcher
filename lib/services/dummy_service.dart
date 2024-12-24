import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/rendering.dart';
import 'package:window_manager/window_manager.dart';
import 'database_service.dart';
import 'log_service.dart';

class DummyService {

  static test() async {


    await Future.delayed(Duration(seconds: 5));
    windowManager.show();
    windowManager.maximize();
    windowManager.setAlwaysOnTop(false);

    return;

    var filex = File("C:\\Users\\user\\Desktop\\watch\\New Microsoft Word Document.docx");

    var raf = filex.openSync(mode: FileMode.read);
    //lock file
    raf.lockSync(FileLock.exclusive);
    print('delay');
    await Future.delayed(Duration(seconds: 5));
    print('delay2');
    raf.unlockSync();
    return;

    var filePath = "C:\\Users\\user\\Downloads\\android-studio-2024.3.1.5-windows.exe";

    // Start measuring time
    DateTime startTime = DateTime.now();

    // Compute the hash of the file
    String fileHash = await calculateFileHash(filePath);

    // End measuring time
    DateTime endTime = DateTime.now();

    // Calculate time taken
    Duration timeTaken = endTime.difference(startTime);

    // Print the hash and the time taken
    print('File hash: $fileHash');
    print('Time taken: ${timeTaken.inMilliseconds} ms');
  }

  static Future<String> calculateFileHash(String filePath) async {
    var file = File(filePath);

    var byteList = await file.readAsBytes();

    // Create SHA-256 hash object
    var digest = sha256.convert(byteList);

    return digest.toString();  // Return hash as a hexadecimal string
  }
}