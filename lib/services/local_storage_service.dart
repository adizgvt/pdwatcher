import 'package:pdwatcher/services/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorage {

  static const String _WATCHED_DIRECTORY_KEY = 'watchedDirectory';
  static const String _USERNAME_KEY          = 'username';
  static const String _PASSWORD_KEY          = 'password';
  static const String _SERVER_URL_KEY        = 'serverUrl';
  static const String _TOKEN_KEY             = 'token';
  static const String _LAST_DELETE           = 'last+delete';
  static const String _LOCAL_HOSTNAME        = 'localHostname';
  static const String _DEVICE_ID             = 'deviceId';

  static Future<void> setWatchedDirectory(String directory) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_WATCHED_DIRECTORY_KEY, directory);
  }

  static Future<String?> getWatchedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_WATCHED_DIRECTORY_KEY);
  }


  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_USERNAME_KEY, username);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_USERNAME_KEY);
  }

  static Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PASSWORD_KEY, password);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_PASSWORD_KEY);
  }

  static Future<void> setServerUrl(String serverUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_SERVER_URL_KEY, serverUrl);
  }

  static Future<String?> getServerUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_SERVER_URL_KEY);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_TOKEN_KEY, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_TOKEN_KEY);
  }

  static Future<void> setLastDelete(int timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_LAST_DELETE, timestamp);
  }

  static Future<int?> getLastDelete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_LAST_DELETE);
  }

  static Future<void> setLocalHostname(String hostname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_LOCAL_HOSTNAME, hostname);
  }

  static Future<String?> getLocalHostname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_LOCAL_HOSTNAME);
  }

  static Future<void> setDeviceId(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _DEVICE_ID,
        deviceId
            .replaceAll('\n', '')
            .replaceAll('\r', '')
            .replaceAll(' ', '')
    );
  }

  static Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_DEVICE_ID);
  }

  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}


