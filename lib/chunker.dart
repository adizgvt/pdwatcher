import 'dart:io';
import 'dart:async';
import 'package:pdwatcher/hasher.dart';

class Chunker {
  static Future<void> chunkFile(String filePath, int chunkSize) async {

    print('ChunkStart:${DateTime.now()}');
    File file = File(filePath);
    int fileLength = await file.length();

    //print('fileLength=$fileLength');
    RandomAccessFile raf = await file.open();

    int offset = 0;

    while (offset < fileLength) {
      //print(filePath);
      int end = offset + chunkSize;
      if (end > fileLength) {
        end = fileLength;
      }

      // Read the chunk
      raf.setPositionSync(offset);
      List<int> chunk = raf.readSync(end - offset);

      // Process the chunk (e.g., upload it, save it, etc.)
      if(offset == 0){
        await processChunk(chunk);
      }
      

      // Update the offset
      offset = end;
    }

    await raf.close();
    print('ChunkEnd:${DateTime.now()}');

  }

  static Future<void> processChunk(List<int> chunk) async {
    for (int i = 0; i < 100; i++){
      print(i.toString() + ':' + chunk[i].toString());
    }
    
    //print(await Hasher.getChunkHash(chunk));
  }
}
