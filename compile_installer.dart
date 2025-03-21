import 'dart:io';

import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

void main() async {

  ///PLEASE BUILD FIRST BEFORE CREATING INSTALLER
  ///build must not showAllMenu in const & use chunk upload
  ///flutter build windows --release
  ///ensure sqlite3.dll is in release folder
  ///

  String version = '1.0.0';
  String shortVersion = '1';

  bool useBuildDir = true;

  final buildSetup = InnoSetup(
    name            : InnoSetupName('pdsetup_v$version+$shortVersion'),

    app             : InnoSetupApp(
                        name        : 'PocketDataClient',
                        version     : Version.parse(version),
                        publisher   : 'POCKET DATA (M) SDN BHD',
                        urls        : InnoSetupAppUrls(
                                        homeUrl       : Uri.parse('https://example.com/home'),
                                      ),
                      ),

    files           : InnoSetupFiles(
                        executable    : File(useBuildDir ? 'build\\windows\\x64\\runner\\Release\\pdwatcher.exe' :'dist\\$shortVersion\\$version+$shortVersion-windows\\pdwatcher.exe'),
                        location      : Directory(useBuildDir ? 'build\\windows\\x64\\runner\\Release' : 'dist\\$shortVersion\\$version+$shortVersion-windows'),
                      ),

    location        : InnoSetupInstallerDirectory(Directory('build\\windows')),
    icon            : InnoSetupIcon(File('assets\\pd.ico')),
    runAfterInstall : true,
    compression     : InnoSetupCompressions().lzma2(InnoSetupCompressionLevel.ultra64,),
    languages       : [InnoSetupLanguages().english],
  );

  final iss = StringBuffer('''
[Setup]
${buildSetup.app}
${buildSetup.compression}
${buildSetup.icon}
${buildSetup.name}
${buildSetup.location}
${buildSetup.license ?? ''}

${InnoSetupLanguagesBuilder(buildSetup.languages)}

${buildSetup.files}

${InnoSetupIconsBuilder(buildSetup.app)}

${buildSetup.runAfterInstall ? InnoSetupRunBuilder(buildSetup.app) : ''}
''');

  final buildDirectory = Directory("build");

  if (!await buildDirectory.exists()) {
    await buildDirectory.create();
  }

  File('build/innosetup.iss').writeAsStringSync('$iss');

  String filePath = "build/innosetup.iss";
//----------------------------------------------------------------------------
  String content = await File(filePath).readAsString();
  String updatedContent = content.replaceAllMapped(
      RegExp(r'(Filename:\s*"\{app\}\\)PocketDataClient'),
          (match) => '${match.group(1)}pdwatcher.exe'
  );
  await File(filePath).writeAsString(updatedContent);
  //----------------------------------------------------------------------------
  String content2 = await File(filePath).readAsString();
  String updatedContent2 = content2.replaceAllMapped(
    RegExp(r'(DefaultDirName="\{)autopf(\}\\PocketDataClient")'),
        (match) => '${match.group(1)}localappdata${match.group(2)}\nPrivilegesRequired=lowest',
  );
  await File(filePath).writeAsString(updatedContent2);
  //----------------------------------------------------------------------------
  String content3 = await File(filePath).readAsString();
  String updatedContent3 = content3.replaceAllMapped(
    RegExp(r'Name: "\{(auto(programs|desktop))\}'),
        (match) => 'Name: "{user${match.group(2)}}',
  );
  await File(filePath).writeAsString(updatedContent3);
  //----------------------------------------------------------------------------
  print("File updated successfully!");


  await Process.start(
    'C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe',
    ['build/innosetup.iss'],
    mode: ProcessStartMode.inheritStdio,
  );
}