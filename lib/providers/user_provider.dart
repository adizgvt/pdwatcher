import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
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

      Provider.of<UserProvider>(context, listen: false).user = userFromJson(jsonEncode(apiResponse.data));
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
  }) async {
    ApiResponse apiResponse = await apiService(
        data: {
          'user_email': email,
          'password': password,
        },
        serviceMethod: ServiceMethod.post,
        baseUrl: serverUrl,
        path: '/api/login'
    );

    if(apiResponse.statusCode == 200){

      LocalStorage.setUsername(email);
      LocalStorage.setPassword(password);
      LocalStorage.setServerUrl(serverUrl);
      LocalStorage.setWatchedDirectory(syncDirectory);

      Provider.of<UserProvider>(context, listen: false).user = userFromJson(jsonEncode(apiResponse.data));
      LocalStorage.setToken(user!.accessToken);
      Navigator.of(context).pushAndRemoveUntil(FluentPageRoute(builder: (context) => MyHomePage()), (route) => false);

    }
    else {
      await NotificationBar.error(context, message: '${apiResponse.message}');
      return;
    }
  }
}