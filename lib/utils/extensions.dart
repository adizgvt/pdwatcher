import 'package:intl/intl.dart';

extension FileNameExtension on String {
  String renameWithTimestamp() {
    // Get the current timestamp
    DateTime now = DateTime.now();
    String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);  // Format the timestamp

    // Find the file extension and the base file name
    int dotIndex = lastIndexOf('.');  // Find the position of the last dot (.) in the file path
    if (dotIndex == -1) {
      // If no extension found, return the filename as is (without change)
      return this;
    }

    // Extract file name and extension
    String baseName = this.substring(0, dotIndex);  // Extract the filename without the extension
    String extension = this.substring(dotIndex);  // Extract the file extension (including dot)

    // Construct the new file name with timestamp prepended
    return baseName + '_' + timestamp + extension;
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

  String removeDuplicateSlash(){
    return replaceAll('//', '/');
  }
}
