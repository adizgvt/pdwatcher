import 'dart:io';

import '../utils/consts.dart';

class Log {

  static final List<String> _logMessages = [];

  static List<String> get logMessages => _logMessages;


  static void info(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[32m${now.toLocal().toString().substring(0,19)} INF0: <barrier> $message\x1B[0m'.toLowerCase());
    _writeToLog('${now.toLocal().toString().substring(0,19)} INFO: <barrier> $message');
  }
  static void warning(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[33m${now.toLocal().toString().substring(0,19)} WARNING: <barrier> $message\x1B[0m'.toLowerCase());
    _writeToLog('${now.toLocal().toString().substring(0,19)} WARNING: <barrier> $message');
  }
  static void error(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[31m${now.toLocal().toString().substring(0,19)} ERROR: <barrier> $message\x1B[0m'.toLowerCase());
    _writeToLog('${now.toLocal().toString().substring(0,19)} ERROR: <barrier> $message');
  }
  static void verbose(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[34m${now.toLocal().toString().substring(0,19)} VERBOSE: <barrier> $message\x1B[0m'.toLowerCase());
    _writeToLog('${now.toLocal().toString().substring(0,19)} VERBOSE: <barrier> $message');
  }

  static void _writeToLog(String message) {

    _logMessages.add(message);

    if (_logMessages.length > 1000) {
      _logMessages.removeRange(0, _logMessages.length - 1000);
    }

    //return;

    final DateTime now = DateTime.now();
    final String fileName = '${logDir}log_${now.toIso8601String().split('T')[0]}.txt';
    final file = File(fileName);
    file.writeAsStringSync('$message\n', mode: FileMode.append);
  }
}



