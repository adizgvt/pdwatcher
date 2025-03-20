import 'dart:io';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:pdwatcher/widgets/wrapper_widget.dart';

void showUnsupportedPlatformWarningDialog() {
  runApp(
      wrapFluent(
          child: ContentDialog(
            title: const Text('ERROR'),
            content: const Text(
              'THIS PLATFORM IS NOT SUPPORTED.',
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