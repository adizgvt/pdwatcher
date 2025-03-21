import 'package:desktop_updater/updater_controller.dart';
import 'package:desktop_updater/widget/update_widget.dart';
import 'package:tray_manager/tray_manager.dart';

import '../services/log_service.dart';
import '../services/tray_service.dart';
import '../widgets/appbar_template.dart';
import '../widgets/wrapper_widget.dart';
import 'package:fluent_ui/fluent_ui.dart';

class UpdateApp extends StatelessWidget {
  final DesktopUpdaterController desktopUpdaterController;

  const UpdateApp({super.key, required this.desktopUpdaterController});

  @override
  Widget build(BuildContext context) {
    return wrapFluent(child: UpdateScreen(desktopUpdaterController: desktopUpdaterController));
  }
}


class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key, required this.desktopUpdaterController});

  final DesktopUpdaterController desktopUpdaterController;

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> with TrayListener {

  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    TrayService.onTrayIconMouseDown();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    TrayService.onTrayMenuItemClick(menuItem, context);
  }

  @override
  Widget build(BuildContext context) {
    return wrapFluent(
        child: NavigationView(
          appBar: appBarTemplate(),
          content: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: DesktopUpdateWidget(
                controller: widget.desktopUpdaterController,
                child: Container(
                  height: 100,
                  child: Text(
                    'version : ${widget.desktopUpdaterController.appVersion}',
                    style: TextStyle(fontSize: 10),
                  )
                )
            ),
          ),
        )
    );
  }
}
