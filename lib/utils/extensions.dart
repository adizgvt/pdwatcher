import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdwatcher/services/local_storage_service.dart';

extension FileNameExtension on String {
  Future<String> renameWithTimestamp() async {

    DateTime now = DateTime.now();
    String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
    String hostName = await LocalStorage.getLocalHostname() ?? '';

    int dotIndex = lastIndexOf('.');
    if (dotIndex == -1) {
      // If no extension found, return the filename as is (without change)
      return this;
    }

    String baseName = this.substring(0, dotIndex);
    String extension = this.substring(dotIndex);

    return '${baseName}_${hostName}_$timestamp$extension';
  }

  String replaceLast(String oldSubstring, String newSubstring) {
    int lastIndex = lastIndexOf(oldSubstring);  // Find the last occurrence

    if (lastIndex == -1) {
      return this;  // If the substring is not found, return the original string
    }

    // Replace the last occurrence by slicing and concatenating
    String before = substring(0, lastIndex);  // Part before the last occurrence
    String after = substring(lastIndex + oldSubstring.length);  // Part after the last occurrence

    return before + newSubstring + after;  // Rebuild the string with the replacement
  }

  String removeTrailingSlash(){
    String result = endsWith('/') || endsWith('\\') ? substring(0, length - 1) : this;
    return result;
  }

  String removeLeadingSlash(){
    String result = startsWith('/') || startsWith('\\') ? substring(1, length) : this;
    return result;
  }

  String replaceBackSlashWithSlash(){
    return replaceAll('\\', '/');
  }

  String replaceSlashWithBackSlash(){
    return replaceAll('\\', '/');
  }

  String removeDuplicateSlash(){
    return replaceAll('//', '/');
  }
}
