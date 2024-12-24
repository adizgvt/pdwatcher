import 'package:fluent_ui/fluent_ui.dart';
import 'package:pdwatcher/chunker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pdwatcher/cdc_chunker.dart';
import 'package:pdwatcher/providers/sync_provider.dart';
import 'package:pdwatcher/providers/theme_provider.dart';
import 'package:pdwatcher/services/local_storage_service.dart';
import 'package:pdwatcher/services/log_service.dart';
import 'package:pdwatcher/services/sync_service.dart';
import 'package:provider/provider.dart';
import './screens/home_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'dart:ui' as ui;

void main() async {

  if (!Platform.isWindows) {
    Log.error("This application only runs on Windows.");
    exit(1);
  }

  sqfliteFfiInit();

  databaseFactory = databaseFactoryFfi;

  LocalStorage.setWatchedDirectory('C:\\Users\\user\\Desktop\\watch');

  await WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  windowManager.setClosable(false);  //
  windowManager.setMinimumSize(Size(800, 600));

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SyncProvider()),
        //ChangeNotifierProvider(create: (_) => ThemeProvider() ,lazy: false,),
      ],
      child: FluentApp(
        debugShowCheckedModeBanner: false,
        home: FluentTheme(
          data: FluentThemeData(
            brightness: Brightness.dark
          ),
          child: MyHomePage(),
        ),
      ),
    );
  }
}
