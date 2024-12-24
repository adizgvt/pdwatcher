import 'dart:io';

import '../utils/consts.dart';

class Log {

  static void info(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[32mINFO: $message at $now\x1B[0m');
    _writeToFile('INFO: $message at $now');
  }
  static void warning(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[33mWARNING: $message at $now\x1B[0m');
    _writeToFile('WARNING: $message at $now');
  }
  static void error(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[31mERROR: $message at $now\x1B[0m');
    _writeToFile('ERROR: $message at $now');
  }
  static void verbose(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[34mVERBOSE: $message at $now\x1B[0m');
    _writeToFile('VERBOSE: $message at $now');
  }

  static void _writeToFile(String message) {
    final DateTime now = DateTime.now();
    final String fileName = '${logDir}log_${now.toIso8601String().split('T')[0]}.txt';
    final file = File(fileName);
    file.writeAsStringSync('$message\n', mode: FileMode.append);
  }
}



