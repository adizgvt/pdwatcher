import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../models/current_task.dart';

class TaskProvider extends ChangeNotifier {

  CurrentTask _task = CurrentTask(
    filename: 'vlc-213213.exe',
    progress: 0.0,
    action: TaskAction.download,
  );

  CurrentTask get task => _task;

  void updateProgress(double newProgress) {
    _task.progress = newProgress;
    notifyListeners();
  }

  void updateAction(TaskAction newAction) {
    _task.action = newAction;
    notifyListeners();
  }

  void updateFilename(String newFilename) {
    _task.filename = newFilename;
    notifyListeners();
  }
}