import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/current_task.dart';
import '../providers/task_provider.dart';
import '../utils/icon_list.dart';

class CurrentTaskWidget extends StatelessWidget {

  Icon _getActionIcon(TaskAction action) {
    switch (action) {
      case TaskAction.download:
        return Icon(FontAwesomeIcons.download, color: Colors.blue);
      case TaskAction.upload:
        return Icon(FontAwesomeIcons.upload, color: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = Provider.of<TaskProvider>(context).task;
    final theme = FluentTheme.of(context);

    // if (task.progress == 0) {
    //   return SizedBox.shrink();
    // }

    return Container(
      margin: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.all(Radius.circular(8))
              ),
              child: Text(
                'Current Task',
                style: TextStyle(color: Colors.white)
              ),
            ),
            SizedBox(height: 16.0),

            Row(
              children: [
                getFileIcon(task.filename),
                SizedBox(width: 10),
                Text(
                  'File: ${task.filename}',
                  style: theme.typography.bodyStrong,
                ),
              ],
            ),
            SizedBox(height: 8.0),

            Text(
              'Progress: ${task.progress.toStringAsFixed(2)}%',
              style: theme.typography.body,
            ),
            SizedBox(height: 8.0),

            Row(
              children: [
                Text(
                  'Action: ${task.action.toString().split('.').last}',
                  style: theme.typography.body,
                ),
                SizedBox(width: 10,),
                _getActionIcon(task.action),
              ],
            ),
            SizedBox(height: 16.0),

            // if (task.progress != 0)
            //   ProgressBar(
            //     value: task.progress / 100,
            //     backgroundColor: Colors.grey[300]!,
            //   ),
          ],
        ),
      ),
    );
  }
}
