import 'dart:io';

import 'package:innosetup/innosetup.dart';
import 'package:version/version.dart';

void main(){
  InnoSetup(
    name            : const InnoSetupName('windows_installer'),

    app             : InnoSetupApp(
                        name        : 'POCKET DATA DESKTOP CLIENT',
                        version     : Version.parse('0.1.0'),
                        publisher   : 'POCKET DATA (M) SDN BHD',
                        urls        : InnoSetupAppUrls(
                                        homeUrl       : Uri.parse('https://example.com/home'),
                                        publisherUrl  : Uri.parse('https://example.com/author'),
                                        supportUrl    : Uri.parse('https://example.com/support'),
                                        updatesUrl    : Uri.parse('https://example.com/updates'),
                                      ),
                      ),

    files           : InnoSetupFiles(
                        executable    : File('build\\windows\\x64\\runner\\Release\\pdwatcher.exe'),
                        location      : Directory('build\\windows\\x64\\runner\\Release'),
                      ),

    location        : InnoSetupInstallerDirectory(Directory('build\\windows')),
    icon            : InnoSetupIcon(File('assets\\logo.ico')),
    runAfterInstall : false,
    compression     : InnoSetupCompressions().lzma2(InnoSetupCompressionLevel.ultra64,),
    languages       : InnoSetupLanguages().all,
  ).make();
}