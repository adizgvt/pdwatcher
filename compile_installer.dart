import 'dart:io';

import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

void main() async {

  ///PLEASE BUILD FIRST BEFORE CREATING INSTALLER
  ///build must not showAllMenu in const & use chunk upload
  ///flutter build windows --release
  ///ensure sqlite3.dll is in release folder

  final buildSetup = InnoSetup(
    name            : const InnoSetupName('pdsetup'),

    app             : InnoSetupApp(
                        name        : 'PocketDataClient',
                        version     : Version.parse('0.1.0'),
                        publisher   : 'POCKET DATA (M) SDN BHD',
                        urls        : InnoSetupAppUrls(
                                        homeUrl       : Uri.parse('https://example.com/home'),
                                      ),
                      ),

    files           : InnoSetupFiles(
                        executable    : File('build\\windows\\x64\\runner\\Release\\pdwatcher.exe'),
                        location      : Directory('build\\windows\\x64\\runner\\Release'),
                      ),

    location        : InnoSetupInstallerDirectory(Directory('build\\windows')),
    icon            : InnoSetupIcon(File('assets\\pd.ico')),
    runAfterInstall : false,
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

  String content = await File(filePath).readAsString();

  // Regex pattern to replace 'PocketDataClient' only in Filename
  String updatedContent = content.replaceAllMapped(
      RegExp(r'(Filename:\s*"\{app\}\\)PocketDataClient'),
          (match) => '${match.group(1)}pdwatcher.exe'
  );

  await File(filePath).writeAsString(updatedContent);

  print("File updated successfully!");

  await Process.start(
    'C:\\Program Files (x86)\\Inno Setup 6\\ISCC.exe',
    ['build/innosetup.iss'],
    mode: ProcessStartMode.inheritStdio,
  );
}