abstract class Log {
  static void info(String message) {
    print('\x1B[32mINFO: $message\x1B[0m');
  }
  static void warning(String message) {
    print('\x1B[33mWARNING: $message\x1B[0m');
  }
  static void error(String message) {
    print('\x1B[31mERROR: $message\x1B[0m');
  }
  static void verbose(String message) {
    print('\x1B[34mVERBOSE: $message\x1B[0m');
  }
}



