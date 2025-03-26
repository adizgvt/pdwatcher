import 'dart:convert';
import 'package:desktop_updater/desktop_updater.dart';
import 'package:desktop_updater/updater_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_single_instance/flutter_single_instance.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:pdwatcher/providers/file_provider.dart';
import 'package:pdwatcher/providers/package_info_provider.dart';
import 'package:pdwatcher/providers/sync_provider.dart';
import 'package:pdwatcher/providers/task_provider.dart';
import 'package:pdwatcher/providers/user_provider.dart';
import 'package:pdwatcher/screens/loading_screen.dart';
import 'package:pdwatcher/screens/update_screen.dart';
import 'package:pdwatcher/services/log_service.dart';
import 'package:pdwatcher/utils/consts.dart';
import 'package:pdwatcher/widgets/another_instance_running_warning.dart';
import 'package:pdwatcher/widgets/unsupported_platform_warning_dialog.dart';
import 'package:pdwatcher/widgets/wrapper_widget.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

//import 'dart:ui' as ui;
//import 'dart:ffi' hide Size;

void main() async {

    if (!Platform.isWindows) {
      showUnsupportedPlatformWarningDialog();
      return;
    }

    await WidgetsFlutterBinding.ensureInitialized();
    await windowManager.ensureInitialized();
    //windowManager.setClosable(false);  //
    windowManager.setAsFrameless();
    windowManager.setTitle('POCKET DATA SYNC DESKTOP CLIENT');
    windowManager.setResizable(false);
    windowManager.setSize(const Size(800, 600));
    windowManager.setMinimumSize(const Size(800, 600));
    windowManager.setMaximumSize(const Size(800, 600));
    windowManager.setSkipTaskbar(true);

    //---------------------------------------------------------------------------

    await trayManager.setIcon('assets/pd.ico');

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show Window',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit App',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);

    //----------------------------------------------------------------------------

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    launchAtStartup.setup(
      appName: packageInfo.appName,
      appPath: Platform.resolvedExecutable,
      // Set packageName parameter to support MSIX.
      packageName: 'com.example.pdwatcher',
    );

    await launchAtStartup.enable();

    //----------------------------------------------------------------------------

    if(!await FlutterSingleInstance().isFirstInstance()){
      showInstanceWarningDialog();
      return;
    }

    //----------------------------------------------------------------------------

    DesktopUpdaterController _desktopUpdaterController = DesktopUpdaterController(
      appArchiveUrl: Uri.parse(
        updateUrl,
      ),
      localization: const DesktopUpdateLocalization(
        updateAvailableText: "Update available",
        newVersionAvailableText: "{} {} is available",
        newVersionLongText:
        "New version is ready to download, click the button below to start downloading. This will download {} MB of data.",
        restartText: "Restart to update",
        warningTitleText: "Are you sure?",
        restartWarningText:
        "A restart is required to complete the update installation.\nAny unsaved changes will be lost. Would you like to close the application now?",
        warningCancelText: "Not now",
        warningConfirmText: "Close",
      ),
    );

    _desktopUpdaterController.checkVersion().then((_) {

      Log.info(_desktopUpdaterController.downloadProgress.toString());

      if(_desktopUpdaterController.needUpdate){
        windowManager.setSize(const Size(800, 800));
        windowManager.setMinimumSize(const Size(800, 800));
        windowManager.setMaximumSize(const Size(800, 800));
        runApp(UpdateApp(desktopUpdaterController: _desktopUpdaterController));
      }else{
        runApp(MyApp());
      }
    }).catchError((err){
      print(err);
      runApp(MyApp());
    });

    //runApp(MyApp());





}

class Dummy extends StatelessWidget {
  const Dummy({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('dummy'));
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FileProvider()),
        ChangeNotifierProvider(create: (_) => PackageInfoProvider(), lazy: false,),
        ChangeNotifierProvider(create: (_) => TaskProvider(), lazy: false,),
        //ChangeNotifierProvider(create: (_) => ThemeProvider() ,lazy: false,),
      ],
      child: wrapFluent(child: const LoadingScreen())
    );
  }
}

