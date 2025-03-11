import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:pdwatcher/widgets/wrapper_widget.dart';

void showInstanceWarningDialog() {
  runApp(
      wrapFluent(
        child: ContentDialog(
          title: const Text('Warning'),
          content: const Text(
            'Another instance of this application is already running.',
          ),
          actions: [
            FilledButton(
              child: const Text('EXIT'),
              onPressed: () {
                exit(0);
              },
            ),
          ],
        )
    )
  );
}