import 'dart:async';
import 'package:pdwatcher/services/database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  bool runningQueue = false;

  String watchedDirectory = 'C:\\Users\\pd\\Desktop\\watch';

  List<dynamic> eventList = [];

  //WHEN MOVING FOLDER, EVENTS ARE RECORDED AS 2 SEPARATE EVENTS, DELETE AND CREATE
  //THIS BUFFER IS USED TO DIFFERENTIATE MOVING FOLDER AND CREATING NEW FOLDER
  dynamic lastDeleteEventBuffer;

  List<dynamic> actionQueue = [];

  List<dynamic> files = [];

  List<dynamic> folders = [];

  DatabaseService databaseService = DatabaseService();

  @override
  void initState() {

    Directory directory = Directory(watchedDirectory);

    StreamSubscription<FileSystemEvent> eventStream = directory
                                                      .watch(
                                                        events: FileSystemEvent.all,
                                                        recursive: true
                                                      )
                                                      .listen((event) async {
                                                        
                                                        print(event);                                                      
                                                        eventList.add(event);

                                                        if(event.type == EventType.delete){
                                                          lastDeleteEventBuffer = {
                                                            'event': event,
                                                            'timestamp': DateTime.now().millisecondsSinceEpoch
                                                          };
                                                        }

                                                        setState((){});
                                                        
                                                        dynamic action = await processEvent(event);

                                                        //SOME EVENT WONT TRIGGER ANY ACTION
                                                        //EG: DOCX TMP FILE
                                                        if(action == null){
                                                          return;
                                                        }

                                                        //WHEN QUEUE IS EMPTY JUST SIMPLY ADD TO QUEUE WITHOUT FURTHER CHECKING
                                                        if(actionQueue.isEmpty){
                                                          (action is List) ? actionQueue.addAll(action) : actionQueue.add(action);
                                                          setState(() {});
                                                          return;
                                                        }

                                                        //CREATE FOLDER EVENT CAN RETURN MULTIPLE ACTIONS
                                                        if(action is List){
                                                          actionQueue.addAll(action);
                                                          setState(() {});
                                                          return;
                                                        }

                                                        //OTHER EVENTS RETURN SINGLE ACTION
                                                        //if duplicate with previous event, replace timestamp
                                                        if(actionQueue.last['event'].toString() == action['event'].toString()){
                                                          actionQueue.last['timestamp'] = action['timestamp'];
                                                          setState(() {});
                                                          return;
                                                        }

                                                        actionQueue.add(action);
                                                        setState(() {});
                                                      });

    Timer timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) async {

      setState(() {});

      if(runningQueue){
        return;
      }

      if(actionQueue.isEmpty){
        return;
      }

      runningQueue = true;

      while(actionQueue.isNotEmpty){
        print('Running Queue : ${actionQueue.first}');
        updateLocalDatabaseRecord(
          queue: actionQueue.first,
          db: databaseService,
        );
        // copyToTempAndChunk(
        //   filePath: actionQueue.first['event']['path'],
        //   tempDir: 'C:\\Users\\pd\\Desktop\\tempchunk\\'
        // );
        actionQueue.removeAt(0);
        files       = await databaseService.queryAllFiles();
        folders     = await databaseService.queryAllFolders();
        setState(() {});
      }

      runningQueue = false;

    });

    queryFilesAndFolders();

    super.initState();
  }q

  queryFilesAndFolders() async {
    files   = await databaseService.queryAllFiles();
    folders = await databaseService.queryAllFolders();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter App'),
      ),
      body: Row(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey.shade100,              
              child: Column(
                children: [
                  Text('recorded events'),
                  Expanded(
                    child: ListView.builder(
                      itemCount: eventList.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          //title: Text(eventList[eventList.length - 1 -index].path),
                          subtitle: Text(eventList[eventList.length - 1 -index].toString()),
                          trailing: IconButton(
                            onPressed: () async {
                                
                                //if not the first event in the list, dont do anything
                                // if(eventList.length - 1 - index != 0) return;

                                // dynamic action = await processEvent();

                                // if(action != null){
                                //   actionQueue.add(action);
                                //   setState(() {});
                                // }
                            }, 
                            icon: (eventList.length - 1 - index) == 0 ? Icon(Icons.play_arrow) : Icon(Icons.crop_square_sharp)
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            )
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: Column(
                children: [
                  Text('processed events'),
                  Expanded(
                    child: ListView.builder(
                      itemCount: actionQueue.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          subtitle: Text(
                            actionQueue[actionQueue.length - 1 -index].toString()
                            ),
                          trailing: IconButton(
                            onPressed: () async {
                                
                                //if not the first event in the list, dont do anything
                                if(actionQueue.length - 1 - index != 0) return;

                                updateLocalDatabaseRecord(
                                  queue: actionQueue[actionQueue.length - 1 - index],
                                  db: databaseService
                                );

                                queryFilesAndFolders();

                            }, 
                            icon: (actionQueue.length - 1 - index) == 0 ? Icon(Icons.play_arrow) : Icon(Icons.crop_square_sharp)
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            )
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.green.shade100,
                    child: Column(
                      children: [
                        Text('files'),
                        Expanded(
                          child: ListView.builder(
                            itemCount: files.length, // Number of items in the list
                            itemBuilder: (context, index) {
                              // Build each item
                              return listTemplate(
                                id: files[index]['id'].toString(), 
                                localPath: files[index]['local_path'].toString(), 
                                localTimestamp: files[index]['local_timestamp'].toString(), 
                                remoteId: files[index]['remote_id'].toString(), 
                                remoteTimestamp: files[index]['remote_timestamp'].toString()
                              );
                            },
                          ),
                        )
                      ],
                    )
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.green.shade50,
                    child: Column(
                      children: [
                        Text('folders'),
                        Expanded(
                          child: ListView.builder(
                            itemCount: folders.length, // Number of items in the list
                            itemBuilder: (context, index) {
                              // Build each item
                              return listTemplate(
                                id: folders[index]['id'].toString(), 
                                localPath: folders[index]['local_path'].toString(), 
                                localTimestamp: folders[index]['local_timestamp'].toString(), 
                                remoteId: folders[index]['remote_id'].toString(), 
                                remoteTimestamp: folders[index]['remote_timestamp'].toString()
                              );
                            },
                          ),
                        )
                      ],
                    )
                  ),
                ),
              ],
            )
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () async {
        databaseService.deleteAll();
        queryFilesAndFolders();
      }),
    );

    
  }

  listTemplate({
    required String id,
    required String localPath,
    required String localTimestamp,
    required String remoteId,
    required String remoteTimestamp,
  }){
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(id)),
          Expanded(child: Text(localPath)),
          Expanded(child: Text(localTimestamp)),
          Expanded(child: Text(remoteId)),
          Expanded(child: Text(remoteTimestamp)),
        ],
      );
  }

  copyToTempAndChunk({
    required String filePath,
    required String tempDir
  }){
    var filex = File(filePath);
        var raf = filex.openSync(mode: FileMode.read);
        raf.lockSync(FileLock.exclusive);

        var uuid = const Uuid();

        //-------------------------------------------------
        int offset = 0;
        int fileLength = raf.lengthSync();
        int chunkSize = 1024 * 4;
        String tempName = uuid.v1();

        while (offset < fileLength) {

          int end = offset + chunkSize;
          if (end > fileLength) {
            end = fileLength;
          }

          raf.setPositionSync(offset);
          List<int> chunk = raf.readSync(end - offset);

          final directory = Directory('$tempDir$tempName');

          directory.create();

          String chunkPath = '$tempDir$tempName\\$offset#$end#$tempName';

          var output = File(chunkPath).openWrite();
          output.add(chunk);
          output.close();
          
          offset = end;
        }

        raf.unlockSync();
        raf.closeSync();
        //-------------------------------------------------

        
  }

  processEvent(event) async {

    //dynamic event = eventList.first;

    //remove event HEAD
    //eventList.removeAt(0);

    if(event.isDirectory){

      if(event.type == EventType.delete){
        return {
                  'event': {
                    'action': QueueAction.delete,
                    'path'  : event.path,
                    'type'  : FileType.directory
                  },
                  'timestamp': DateTime.now().millisecondsSinceEpoch
                };
      }

      //IF USER CREATE NEW DIRECTORY OR MOVES A FOLDER FROM OUTSIDE WATCHED DIRECTORY INTO THE WATCHED DIRECTORY
      if(event.type == EventType.create){

        String eventFolder = event.path.split('\\').last;

        bool isMoveFolderEvent = false;

        //IF LAST BUFFER EVENT IS DELETE AND THE FOLDER NAME IS SAME AS CURRENT EVENT, IT IS ACTUALLY A MOVE EVENT
        if(
            lastDeleteEventBuffer != null && 
            lastDeleteEventBuffer['event'].type == EventType.delete && 
            lastDeleteEventBuffer['event'].path.split('\\').last == eventFolder &&
            //LAST DELETE EVENT AND CREATE EVENT MUST NOT BE 100 MILLISECONDS APART
            (DateTime.fromMillisecondsSinceEpoch(lastDeleteEventBuffer['timestamp']).difference(DateTime.now()).inMilliseconds).abs() <= 100
          ){
          isMoveFolderEvent = true;
        }

        //CHECK IF FOLDER CONTAINS OTHER FILE
        //IF CONTAIN, ADD EVENTS
        List<dynamic> children = [];

        final List<FileSystemEntity> entities = await Directory(event.path).list(recursive: true, followLinks: false).toList();

        for(int i = 0; i < entities.length; i++){
          children.add(
            {
              'event': {
                'action'                                    : isMoveFolderEvent ? QueueAction.move : QueueAction.create,
                'from'                                      : isMoveFolderEvent ? '${lastDeleteEventBuffer['event'].path}${entities[i].path.replaceAll(event.path, '')}' : null,
                isMoveFolderEvent ? 'to' : 'path'           : entities[i].path,
                'type'                                      : entities[i].toString().startsWith('File') ? FileType.file : FileType.directory
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch
            }
          );
        }

        //PUT PARENT EVENT INFRONT
        children.insert(
          0, 
          {
              'event': {
                'action': isMoveFolderEvent ? QueueAction.move  : QueueAction.create,
                'from'                                          : isMoveFolderEvent ? '${lastDeleteEventBuffer['event'].path}' : null,
                isMoveFolderEvent ? 'to' : 'path'               : event.path,
                'type'  : FileType.directory
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch
            }
        );

        if(isMoveFolderEvent){
          lastDeleteEventBuffer = null;
        }

        return children;
 
      
      }

      if(event.type == EventType.move){
        String originalFolderName = event.path.split('\\').last;
        String originalDirectory = event.path.replaceAll('\\$originalFolderName', '');

        String destinationFolderName = event.destination.split('\\').last;
        String destinationDirectory = event.destination.replaceAll('\\$destinationFolderName', '');
        
        //----------------------------------------------------------------------
        List<dynamic> children = [];

        final List<FileSystemEntity> entities = await Directory(event.destination).list(recursive: true, followLinks: false).toList();

        for(int i = 0; i < entities.length; i++){
          print('''
            new path : ${entities[i].path}
            old path : ${event.path + entities[i].path.replaceAll(event.destination, '')}
          ''');
          children.add(
            {
              'event': {
                'action': originalDirectory == destinationDirectory ? QueueAction.rename : QueueAction.move,
                'from'  : event.path + entities[i].path.replaceAll(event.destination, ''),
                'to'    : entities[i].path,
                'type'  : entities[i].toString().startsWith('File') ? FileType.file : FileType.directory
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch
            }
          );
        }

        //PUT PARENT EVENT INFRONT
        children.insert(
          0,
          {
            'event': {
              'action': originalDirectory == destinationDirectory ? QueueAction.rename : QueueAction.move,
              'from'  : event.path,
              'to'    : event.destination,
              'type'  : FileType.directory
            },
            'timestamp': DateTime.now().millisecondsSinceEpoch
          }
        );

        return children;        
        //----------------------------------------------------------------------
        // if(originalDirectory == destinationDirectory){

        //   return  {
        //           'event': {
        //             'action': QueueAction.rename,
        //             'from'  : event.path,
        //             'to'    : event.destination,
        //             'type'  : FileType.directory
        //           },
        //           'timestamp': DateTime.now().millisecondsSinceEpoch
        //         };

        // } else {

        //   return  {
        //           'event': {
        //             'action': QueueAction.move,
        //             'from'  : event.path,
        //             'to'    : event.destination,
        //             'type'  : FileType.directory
        //           },
        //           'timestamp': DateTime.now().millisecondsSinceEpoch
        //         };

        // }
      }
      
    }else{

      //GET ORIGINAL PATH INFO
      String originalFileName = event.path.split('\\').last;
      String originalDirectory = event.path.replaceAll('\\$originalFileName', '');

      //CREATE
      if(event.type == EventType.create){
        //IGNORE ~$XX.docx && ~$XX.pptx
        //$~ is a lock file, it means that the original file is currently opened by an application
        if(originalFileName.startsWith('~\$') && ['.docx', '.pptx'].any(originalFileName.endsWith)){
          return null;
        }

        //IGNORE CTREATED TEMP FILE
        if(event.path.endsWith('.tmp')){
          print('event type: ${event.type}');
          return null;
        }

        return  {
                  'event': {
                    'action': QueueAction.create,
                    'path'  : event.path,
                    'type'  : FileType.file
                  },
                  'timestamp': DateTime.now().millisecondsSinceEpoch
                };

      }

      //MODIFY
      if(event.type == EventType.modify){

        if(event.path.endsWith('.tmp')){
          return null;
        }

        if(originalFileName.startsWith('~\$')){
          return null;
        }

        return  {
                  'event': {
                    'action': QueueAction.modify,
                    'path'  : event.path,
                    'type'  : FileType.file
                  },
                  'timestamp': DateTime.now().millisecondsSinceEpoch
                };
      }

      //DELETE
      if(event.type == EventType.delete){
        //moving file from watched dir to unwatched dir also considered as delete

        if(event.path.endsWith('.tmp')){
          return null;
        }

        if(originalFileName.startsWith('~\$')){
          return null;
        }

        return  {
                  'event': {
                    'action': QueueAction.delete,
                    'path'  : event.path,
                    'type'  : FileType.file
                  },
                  'timestamp': DateTime.now().millisecondsSinceEpoch
                };
      }

      //MOVE AND RENAME
      if(event.type == EventType.move){

        String destinationFileName = event.destination.split('\\').last;
        String destinationDirectory = event.destination.replaceAll('\\$destinationFileName','');

        // print('Original     FileName: $originalFileName');
        // print('Original     Directory: $originalDirectory');
        // print('Destination  FileName : $destinationFileName');
        // print('Destination  Directory: $destinationDirectory');

        //RENAME
        if(originalDirectory == destinationDirectory){

          //IGNORE WHEN MOVING TMP FILE
          if(['.docx', '.xlsx', '.xls', '.pptx'].any(originalFileName.endsWith) && destinationFileName.endsWith('.tmp')){

            return null;

          }

          //RECORD WHEN USER SAVE OFFICE FILES
          if(originalFileName.endsWith('.tmp') && ['.docx', '.xlsx', '.xls', '.pptx'].any(destinationFileName.endsWith)){
            
            return  {
                    'event': {
                      'action': QueueAction.modify,
                      'path'  : event.destination,
                      'type'  : FileType.file
                    },
                    'timestamp': DateTime.now().millisecondsSinceEpoch
                  };

          }

          return  {
                  'event': {
                    'action': QueueAction.rename,
                    'from'  : event.path,
                    'to'    : event.destination,
                    'type'  : FileType.file
                  },
                  'timestamp': DateTime.now().millisecondsSinceEpoch
                  };
        }

        else{

            //IF FILE MOVED to path outside watched directory, do nothing
            if(!destinationDirectory.contains(watchedDirectory)){
              print('File moved outside of watched directory');
              return null;
            }

            return  {
                  'event': {
                    'action': QueueAction.move,
                    'from'  : event.path,
                    'to'    : event.destination,
                    'type'  : FileType.file
                  },
                  'timestamp': DateTime.now().millisecondsSinceEpoch
                };

        }
    }
    }
  }
}

updateLocalDatabaseRecord({
  required queue,
  required DatabaseService db
  }){


  if(queue['event']['type'] == FileType.file){

    if(queue['event']['action'] == QueueAction.create){
      db.createFile(
        path        : queue['event']['path'], 
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.modify){
      db.modifyFile(
        path        : queue['event']['path'], 
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.rename){
      db.renameFile(
        path        : queue['event']['from'], 
        destination : queue['event']['to'],
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.move){
      db.moveFile(
        path        : queue['event']['from'], 
        destination : queue['event']['to'],
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.delete){
      db.deleteFile(
        path        : queue['event']['path'], 
      );
    }
    
  }else{

    if(queue['event']['action'] == QueueAction.create){
      db.createFolder(
        path        : queue['event']['path'], 
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.rename){
      db.renameFolder(
        path        : queue['event']['from'], 
        destination : queue['event']['to'],
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.move){
      db.moveFolder(
        path        : queue['event']['from'], 
        destination : queue['event']['to'],
        timestamp   : queue['timestamp']
      );
    }

    if(queue['event']['action'] == QueueAction.delete){
      db.deleteFolder(
        path        : queue['event']['path'], 
      );
    }

  }
}

abstract class EventType{

  static int create = 1;
  static int modify = 2;
  static int delete = 4;
  static int move   = 8;

}

abstract class FileType{
  static String file       = 'file';
  static String directory  = 'directory';
}

abstract class QueueAction{
  static String create = 'create';
  static String delete = 'delete';
  static String modify = 'modify';
  static String move   = 'move';
  static String rename = 'rename';
}

//-------------------------------------------------------------------------------------