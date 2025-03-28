import 'dart:convert';
import 'dart:io';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:pdwatcher/services/database_service.dart';
import 'package:pdwatcher/widgets/notification.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';
import '../models/api_response.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../utils/enums.dart';

class UserProvider extends ChangeNotifier {

  User? user;

  autoLogin(context) async {
    String? username = await LocalStorage.getUsername();
    String? password = await LocalStorage.getPassword();

    if(username == null || password == null){
      Navigator.of(context).pushAndRemoveUntil(FluentPageRoute(builder: (context) => const LoginScreen(newLogin: true,)), (route) => true);
      return;
    }

    ApiResponse apiResponse = await apiService(
        data: {
          'user_email': username,
          'password': password,
        },
        serviceMethod: ServiceMethod.post,
        baseUrl: await LocalStorage.getServerUrl(),
        path: '/api/login'
    );

    if(apiResponse.statusCode == 200){

      user = userFromJson(jsonEncode(apiResponse.data));
      LocalStorage.setToken(user!.accessToken);
      Navigator.of(context).pushAndRemoveUntil(FluentPageRoute(builder: (context) => MyHomePage()), (route) => false);

    }
    else {
      Navigator.of(context).pushAndRemoveUntil(FluentPageRoute(builder: (context) => const LoginScreen(newLogin: false)), (route) => false);
    }
  }

  login({
    required BuildContext context,
    required String email,
    required String password,
    required String serverUrl,
    required String syncDirectory,
    bool deleteOldDirectory = false,
    String? oldDirectoryPath,
  }) async {

    if(context.mounted){
      context.loaderOverlay.show();
    }


    ApiResponse apiResponse = await apiService(
        data: {
          'user_email': email,
          'password': password,
        },
        serviceMethod: ServiceMethod.post,
        baseUrl: serverUrl,
        path: '/api/login'
    );

    if(context.mounted){
      context.loaderOverlay.hide();
    }

    if(apiResponse.statusCode == 200){

      LocalStorage.setUsername(email);
      LocalStorage.setPassword(password);
      LocalStorage.setServerUrl(serverUrl);
      LocalStorage.setWatchedDirectory(syncDirectory);
      LocalStorage.saveWatchDirectoriesList(email.toLowerCase().trim(), syncDirectory);

      if(deleteOldDirectory && oldDirectoryPath != null){
        DatabaseService databaseService = DatabaseService();
        databaseService.deleteAll();

        final oldDir = Directory(oldDirectoryPath);
        if (await oldDir.exists()) {
          await oldDir.delete(recursive: true);
          print("Directory deleted: $oldDirectoryPath");
        } else {
          print("Directory does not exist: $oldDirectoryPath");
        }
      }

      user = userFromJson(jsonEncode(apiResponse.data));
      await LocalStorage.setToken(user!.accessToken).then((val) {
        Navigator.of(context).pushAndRemoveUntil(FluentPageRoute(builder: (context) => MyHomePage()), (route) => false);
      });

    }
    else {
      await NotificationBar.error(context, message: '${apiResponse.message}');
      return;
    }
  }
}