enum TaskAction {
  download,
  upload,
}

class CurrentTask {
  String filename;
  double progress;
  TaskAction action;

  CurrentTask({
    required this.filename,
    required this.progress,
    required this.action,
  });

  void displayTaskDetails() {
    print('File: $filename');
    print('Progress: $progress%');
    print('Action: ${action.toString().split('.').last}');
  }
}
