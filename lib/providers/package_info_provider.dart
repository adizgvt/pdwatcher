import 'package:fluent_ui/fluent_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

class PackageInfoProvider extends ChangeNotifier{

  String versionNumber  = '';
  String versionCode    = '';

  getDetails() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    versionNumber  = packageInfo.buildNumber;
    versionCode    = packageInfo.version;

    notifyListeners();

  }




}