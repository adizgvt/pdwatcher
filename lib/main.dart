import 'package:fluent_ui/fluent_ui.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:pdwatcher/providers/file_provider.dart';
import 'package:pdwatcher/providers/sync_provider.dart';
import 'package:pdwatcher/providers/user_provider.dart';
import 'package:pdwatcher/screens/loading_screen.dart';
import 'package:pdwatcher/services/log_service.dart';
import 'package:pdwatcher/widgets/wrapper_widget.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

//import 'dart:ui' as ui;
//import 'dart:ffi' hide Size;

void main() async {

  if (!Platform.isWindows) {
    Log.error("This application only runs on Windows.");
    exit(1);
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

  //----------------------------------------------------------------------------

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

  runApp(MyApp());
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
        //ChangeNotifierProvider(create: (_) => ThemeProvider() ,lazy: false,),
      ],
      child: wrapFluent(child: const LoadingScreen())
    );
  }
}

