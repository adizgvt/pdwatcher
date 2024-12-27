import 'package:pdwatcher/services/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorage {

  static const String WATCHED_DIRECTORY_KEY = 'watchedDirectory';
  static const String USERNAME_KEY          = 'username';
  static const String PASSWORD_KEY          = 'password';
  static const String SERVER_URL_KEY        = 'serverUrl';
  static const String TOKEN_KEY             = 'token';

  static Future<void> setWatchedDirectory(String directory) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(WATCHED_DIRECTORY_KEY, directory);
  }

  static Future<String?> getWatchedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(WATCHED_DIRECTORY_KEY);
  }


  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(USERNAME_KEY, username);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(USERNAME_KEY);
  }

  static Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PASSWORD_KEY, password);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PASSWORD_KEY);
  }

  static Future<void> setServerUrl(String serverUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SERVER_URL_KEY, serverUrl);
  }

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SERVER_URL_KEY);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN_KEY, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN_KEY);
  }

  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}


