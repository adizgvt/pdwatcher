import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:pdwatcher/services/local_storage_service.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

abstract class TrayService {

  static onTrayIconMouseDown(){
    trayManager.popUpContextMenu();
  }

  static onTrayMenuItemClick(MenuItem menuItem, context) async {

    print(menuItem);
    switch (menuItem.key) {
      case 'show_window':
        windowManager.show();
        break;
      case 'exit_app':
        windowManager.show();

        String? watchedDirectory = await LocalStorage.getWatchedDirectory();

        //not logged in
        if(watchedDirectory == null){
          exit(0);
        }

        await showDialog<String>(
          context: context,
          builder: (context) => ContentDialog(
            title: const Text('Are you sure you want to exit the app?'),
            content: const Text('Your file will stop syncing',),
            actions: [
              Button(
                  child: const Text('Yes'),
                  onPressed: () => exit(0)
              ),
              FilledButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, 'User canceled dialog'),
              ),
            ],
          ),
        );
        break;
      default:
        break;
    }
  }
}