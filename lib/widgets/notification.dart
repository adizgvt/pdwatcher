import 'package:fluent_ui/fluent_ui.dart';

abstract class NotificationBar {

  static warning(context, {required String message}) async {
    return await displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: Text(message),
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
        severity: InfoBarSeverity.warning,
      );
    });
  }

  static error(context, {required String message}) async {
    return await displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: Text(message),
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
        severity: InfoBarSeverity.error,
      );
    });
  }

  static success(context, {required String message}) async {
    return await displayInfoBar(context, builder: (context, close) {
      return InfoBar(
        title: Text(message),
        action: IconButton(
          icon: const Icon(FluentIcons.clear),
          onPressed: close,
        ),
        severity: InfoBarSeverity.success,
      );
    });
  }

}