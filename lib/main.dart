import 'package:flutter/material.dart';
import 'package:watcher/watcher.dart';
import 'package:pdwatcher/chunker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pdwatcher/cdc_chunker.dart';
import './screens/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {

  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;
  
  runApp(MyApp());

  return;
  
  String path = 'C:\\Users\\pd\\Desktop\\watch';
  int chunkSize = 1024 * 4 * 1024; //4MB

  var filex = File(path + '\\contoh.docx');
  var raf = filex.openSync(mode: FileMode.read);

  // Lock the file asynchronously with an exclusive lock
  raf.lockSync(FileLock.exclusive);
  
  await Future.delayed(Duration(seconds: 300));

  return;



   await Chunker.chunkFile('C:\\Users\\pd\\Desktop\\watch\\largedocumentcopy.docx', chunkSize);
   print('----');
  // await Chunker.chunkFile('C:\\Users\\pd\\Desktop\\watch\\largedocumentcopy.docx', chunkSize);

  return;

  String filePath = 'C:\\Users\\pd\\Desktop\\watch\\SaleData.xlsx';
  String filePath2 = 'C:\\Users\\pd\\Desktop\\watch\\SaleDataMod.xlsx';

  // Read the file as bytes
  File file = File(filePath);
  File file2 = File(filePath2);
  Uint8List fileData = await file.readAsBytes();
  Uint8List fileData2 = await file2.readAsBytes();

  // Initialize chunker
  ContentDefinedChunker chunker = ContentDefinedChunker();

  // Get chunks
  List<Uint8List> chunks = chunker.chunkData(fileData);
  List<Uint8List> chunks2 = chunker.chunkData(fileData2);

  // Calculate MD5 for each chunk
  for (int i = 0; i < chunks.length; i++) {
    Digest md5Hash = md5.convert(chunks[i]);
    Digest md5Hash2 = md5.convert(chunks2[i]);
    print('$md5Hash : $md5Hash2');
  }

  //return;

  //DIRECTORY WATCHER
  // Watcher watcher = DirectoryWatcher(path);
  // watcher.events.listen((event){
  //  print(DateTime.now());
  //  print(event.type);
  //  print(event.path);
  // });

  //CHUNKER

  //HASHER

  //MERGER

  //QUEUER

  //SYNCER

  //LOCKER


}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}
