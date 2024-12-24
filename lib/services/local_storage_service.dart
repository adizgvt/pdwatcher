import 'package:pdwatcher/services/log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorage {

  static const String WATCHED_DIRECTORY_KEY = 'watchedDirectory';

  static Future<void> setWatchedDirectory(String directory) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(WATCHED_DIRECTORY_KEY, directory);
  }

  static Future<String?> getWatchedDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(WATCHED_DIRECTORY_KEY);
  }
}


