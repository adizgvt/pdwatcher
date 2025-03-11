import 'dart:convert';

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
  static const String _WATCHED_DIRECTORIES   = 'watch_directories';

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

  static Future<void> setUserWatchDirHistory({required String username, required String directory}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        username,
        directory
    );
  }

  static Future<bool> isWatchDirAvailable({required String email, watchedDir}) async {
    final prefs = await SharedPreferences.getInstance();

    for (String key in prefs.getKeys()) {

      if(key == _WATCHED_DIRECTORY_KEY){//skip this
        break;
      }

      var value = prefs.get(key);

      if (value == watchedDir) { //stored watched directory = chosen watchedDirectory
        if(key != email){
          //stored email != current email
          return false;
        }
      }
    }
    return true;
  }

  static Future<bool> isDirectoryUsed(String email, String watchDirectory) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString(_WATCHED_DIRECTORIES);

    if (storedData != null) {

      print(storedData);

      List<Map<String, dynamic>> watchList = List<Map<String, dynamic>>.from(json.decode(storedData));

      for (var entry in watchList) {
        if (entry['directory'] == watchDirectory && entry['email'] != email) {
          return true;
        }
      }
    }
    return false;
  }

  static Future<void> saveWatchDirectoriesList(String email, String watchDirectory) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString(_WATCHED_DIRECTORIES);

    List<Map<String, dynamic>> watchList = [];

    if (storedData != null) {
      watchList = List<Map<String, dynamic>>.from(json.decode(storedData));
    }

    watchList.removeWhere((entry) => entry['email'] == email);
    watchList.add({'email': email, 'directory': watchDirectory});

    await prefs.setString('watch_directories', json.encode(watchList));
  }

  static Future<bool> isDirectoryChanged(String email, String newDirectory) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString(_WATCHED_DIRECTORIES);

    if (storedData != null) {
      List<Map<String, dynamic>> watchList = List<Map<String, dynamic>>.from(json.decode(storedData));

      for (var entry in watchList) {
        if (entry['email'] == email) {
          return entry['directory'] != newDirectory;
        }
      }
    }

    return false;
  }

  static Future<String?> getPreviousSyncDirectory(String email) async {
    final prefs = await SharedPreferences.getInstance();
    String? storedData = prefs.getString(_WATCHED_DIRECTORIES);

    if (storedData != null) {
      List<Map<String, dynamic>> watchList = List<Map<String, dynamic>>.from(json.decode(storedData));

      for (var entry in watchList) {
        if (entry['email'] == email) {
          return entry['directory'];
        }
      }
    }

    return null;
  }



  static Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys();

    List<String> keysToKeep = [_WATCHED_DIRECTORIES];

    for (String key in allKeys) {
      if (!keysToKeep.contains(key)) {
        await prefs.remove(key);
      }
    }
  }
}


