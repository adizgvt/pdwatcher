import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:custom_platform_device_id/platform_device_id.dart';
import 'package:desktop_updater/updater_controller.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:pdwatcher/providers/package_info_provider.dart';
import 'package:pdwatcher/services/drive_service.dart';
import 'package:pdwatcher/services/log_service.dart';
import 'package:pdwatcher/widgets/appbar_template.dart';
import 'package:pdwatcher/widgets/wrapper_widget.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';

import '../providers/user_provider.dart';
import '../services/local_storage_service.dart';
import '../services/tray_service.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TrayListener{

  bool isOffline = false;

  late DesktopUpdaterController _desktopUpdaterController;

  @override
  void initState() {

    trayManager.addListener(this);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {

      Provider.of<PackageInfoProvider>(context,listen: false).getDetails();

      final result = await DriveInfo.getDriveName();

      String localHostName = Platform.localHostname;
      LocalStorage.setLocalHostname(localHostName);

      String deviceId = await PlatformDeviceId.getDeviceId ?? '';
      LocalStorage.setDeviceId(deviceId);

      if(!result){
        showDialog<String>(
          context: context,
          builder: (context) => const ContentDialog(
            title: Text('Error'),
            content: Text(
              'Fail to get Windows drive name',
            ),
          ),
        );
        return;
      }

      //check internet connection
      final connectivityResult = await (Connectivity().checkConnectivity());

      switch (connectivityResult) {
        case ConnectivityResult.none:
          isOffline = true;
          setState(() {});
          return;
        case ConnectivityResult.ethernet:
        case ConnectivityResult.wifi:
        case ConnectivityResult.vpn:
          Log.info('Internet OK');
        default:
          Log.error('Unknown connection status');
      }

      Provider.of<UserProvider>(context, listen: false).autoLogin(context);
    });
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
          content: Center(
              child: isOffline ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/no-wifi.png', height: 200,),
                  const SizedBox(height: 20,),
                  FilledButton(
                      child: const Text('Retry'),
                      onPressed: () async {

                        //check internet connection
                        final connectivityResult = await (Connectivity().checkConnectivity());

                        switch (connectivityResult) {
                          case ConnectivityResult.none:
                            isOffline = true;
                            setState(() {});
                            return;
                          case ConnectivityResult.ethernet:
                          case ConnectivityResult.wifi:
                          case ConnectivityResult.vpn:
                            Log.info('Internet OK');
                          default:
                            Log.error('Unknown connection status');
                        }

                        Provider.of<UserProvider>(context, listen: false).autoLogin(context);
                      }
                  )
                ],
              ) : const ProgressRing()
          ),
        )
    );
  }
}
