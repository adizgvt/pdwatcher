import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

appBarTemplate() {
  return NavigationAppBar(
    height: 30,
    automaticallyImplyLeading: false,
    title: Row(
      children: [
        Expanded(
          child: GestureDetector(
              child: Container(
                color: Colors.grey[20],
                height: 30,
              ),
              onPanStart: (details) {
                windowManager.startDragging();
              }),
        ),
        Tooltip(
          message: 'Minimize',
          child: IconButton(
            icon: const Icon(FluentIcons.chrome_minimize, size: 12.0),
            onPressed: () {
              windowManager.minimize();
              //windowManager.hide();
            },
          ),
        ),
      ],
    ),
  );
}
