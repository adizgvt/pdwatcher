import 'dart:io';
import 'dart:core';
import 'package:uuid/uuid.dart';

import '../utils/consts.dart';
import 'log_service.dart';

class FileService {

  static String? copyToTempAndChunk({
    required String filePath,
  }){

    try {

      //open file
      var filex = File(filePath);
      var raf = filex.openSync(mode: FileMode.read);

      //lock file
      raf.lockSync(FileLock.shared);
      Log.warning('!!! Locked   file $filePath');

      var uuid = const Uuid();

      //-------------------------------------------------
      int offset = 0;
      int fileLength = raf.lengthSync();
      int chunkSize = 1024 * 4 * 100;
      String tempName = uuid.v1();

      while (offset < fileLength) {
        int end = offset + chunkSize;
        if (end > fileLength) {
          end = fileLength;
        }

        raf.setPositionSync(offset);
        List<int> chunk = raf.readSync(end - offset);

        //create new temp dir for the file
        final directory = Directory('$tempDir$tempName');
        if (!directory.existsSync()) {
          directory.createSync(recursive: true);
        }

        String chunkPath = '$tempDir$tempName\\$offset#$end#$tempName';

        File file = File(chunkPath);
        if (!file.existsSync()) {
          file.createSync(recursive: false);
        }
        file.writeAsBytesSync(chunk);
        Log.verbose('Wrote chunk for $filePath at $chunkPath');

        offset = end;
      }

      raf.unlockSync();
      raf.closeSync();
      Log.warning('!!! Unlocked file $filePath');
      Log.info('!!! -----------------------------------------------------------');

      return tempName;

    } catch (e,s){
      Log.error(e.toString());
      Log.error(s.toString());
      return null;
    }

  }

}