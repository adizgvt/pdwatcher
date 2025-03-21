String baseDir              = '';

String tempDir              = '${baseDir}temp/';
String logDir               = '${baseDir}logs/';
String dbDir                = '${baseDir}data/';

const appPort             = 4809;

String initialUsername      = 'aws@local.my';
String initialPassword      = '1';
String initialServerurl     = 'https://kocek.pocketdata.com.my';
String initialSyncDirectory = 'C:\\Users\\user\\Desktop\\watchaws';

// String initialUsername      = '';
// String initialPassword      = '';
// String initialServerurl     = '';
// String initialSyncDirectory = '';

String appLogo              = 'assets/logo.png';
String updateUrl            = "http://192.168.68.114/app-archive.json";

bool showAllMenu           = false;
String adminPassword       = '4809';

Map<String, dynamic> hashConfig = {
  'salt'          : 'k0c3k',
  'minHashLength' : 7,
  'alphabet'      : 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890',
};

List<String> microsoftOfficeExtensions = [
  '.docx',
  '.doc',
  '.xlsx',
  '.xls',
  '.pptx'
];

abstract class ApiPath{

  static const getChanges = '/api/getChanges';

}

