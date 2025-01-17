import 'dart:io';

import '../utils/consts.dart';

class Log {

  static final List<String> _logMessages = [];

  static List<String> get logMessages => _logMessages;


  static void info(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[32m${now.toLocal().toString().substring(0,19)} INFO: $message\x1B[0m'.toLowerCase());
    _writeToFile('${now.toLocal().toString().substring(0,19)} INFO: $message');
  }
  static void warning(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[33m${now.toLocal().toString().substring(0,19)} WARNING: $message\x1B[0m'.toLowerCase());
    _writeToFile('${now.toLocal().toString().substring(0,19)} WARNING: $message');
  }
  static void error(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[31m${now.toLocal().toString().substring(0,19)} ERROR: $message\x1B[0m'.toLowerCase());
    _writeToFile('${now.toLocal().toString().substring(0,19)} ERROR: $message');
  }
  static void verbose(String message) {
    final DateTime now = DateTime.now();
    print('\x1B[34m${now.toLocal().toString().substring(0,19)} VERBOSE: $message\x1B[0m'.toLowerCase());
    _writeToFile('${now.toLocal().toString().substring(0,19)} VERBOSE: $message');
  }

  static void _writeToFile(String message) {
    _logMessages.add(message); // Add the message to the log list
    return;
    final DateTime now = DateTime.now();
    final String fileName = '${logDir}log_${now.toIso8601String().split('T')[0]}.txt';
    final file = File(fileName);
    file.writeAsStringSync('$message\n', mode: FileMode.append);
  }
}



