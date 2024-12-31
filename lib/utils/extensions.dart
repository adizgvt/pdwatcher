import 'package:intl/intl.dart';

extension FileNameExtension on String {
  String renameWithTimestamp() {
    // Get the current timestamp
    DateTime now = DateTime.now();
    String timestamp = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);  // Format the timestamp

    // Find the file extension and the base file name
    int dotIndex = this.lastIndexOf('.');  // Find the position of the last dot (.) in the file path
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
}
