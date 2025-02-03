String   baseDir = '';

String tempDir = '${baseDir}temp/';
String logDir  = '${baseDir}logs/';
String dbDir   = '${baseDir}data/';

String initialUsername      = 'admin@pocketdata.com.my';
String initialPassword      = '1';
String initialServerurl     = 'https://kocek.pocketdata.com.my';
String initialSyncDirectory = 'C:\\Users\\user\\Desktop\\watch';

String appLogo = 'assets/logo.png';

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

