import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdwatcher/utils//enums.dart';
import 'package:pdwatcher/services/database_service.dart';
import 'package:pdwatcher/services/event_service.dart';
import 'package:pdwatcher/services/local_storage_service.dart';
import 'package:pdwatcher/services/sync_service.dart';
import 'package:pdwatcher/utils/consts.dart';
import 'dart:io';
import 'package:pdwatcher/utils/types.dart';
import 'package:pdwatcher/widgets/list_template.dart';
import 'package:pdwatcher/widgets/spinning_icon.dart';
import 'package:pdwatcher/widgets/sync_list_template.dart';
import 'package:provider/provider.dart';

import '../providers/sync_provider.dart';
import '../services/dummy_service.dart';
import '../widgets/action_button.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int topIndex = 0;

  PaneDisplayMode displayMode = PaneDisplayMode.open;

  bool runningQueue = false;


  List<dynamic> eventList = [];

  //WHEN MOVING FOLDER, EVENTS ARE RECORDED AS 2 SEPARATE EVENTS, DELETE AND CREATE
  //THIS BUFFER IS USED TO DIFFERENTIATE MOVING FOLDER AND CREATING NEW FOLDER
  dynamic lastDeleteEventBuffer;

  List<dynamic> actionQueue = [];

  List<dynamic> files = [];

  List<dynamic> folders = [];

  DatabaseService databaseService = DatabaseService();

  String watchedDirectory = '';

  @override
  void initState() {

    _startWatcher();
    _queryFilesAndFolders();

    super.initState();
  }

  _startWatcher() async {

    watchedDirectory = await LocalStorage.getWatchedDirectory() ?? '';

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

      dynamic action = await EventService.processEvent(
          event,
          lastDeleteEventBuffer: lastDeleteEventBuffer,
          context: context
      );

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
        databaseService.updateLocalDatabaseRecord(
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
  }

  _queryFilesAndFolders() async {
    files   = await databaseService.queryAllFiles();
    folders = await databaseService.queryAllFolders();
    setState(() {});
  }

  _gotoTab(index){
    topIndex = index;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        actions: Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if(Provider.of<SyncProvider>(context).isSyncing)
              SpinningIcon(icon: FontAwesomeIcons.arrowsRotate, color: Colors.blue),
              SizedBox(width: 20,),
              Button(
                style: ButtonStyle(
                  backgroundColor: ButtonState.all(Provider.of<SyncProvider>(context).isOffline ? Colors.orange : Colors.green),
                ),
                onPressed: (){},
                child: Row(
                  children: [Text(Provider.of<SyncProvider>(context).isOffline ? 'Offline' : 'Online', style: TextStyle(color: Colors.white),)
                  ],
                ),
              ),
            ],
          ),
        ),
        title: Padding(
          padding: EdgeInsets.all(10),
          child: CommandBar(
            overflowBehavior: CommandBarOverflowBehavior.noWrap,
            primaryItems: [
              CommandBarButton(
                  icon: Icon(FluentIcons.sync, color: Colors.blue,),
                  label: const Text('Sync Local Folder With Local Db'),
                  onPressed: () async {

                    _gotoTab(0);

                    await SyncService.syncLocalFileFolderWithLocalDb().then((val){
                      _queryFilesAndFolders();
                    });


                  }
              ),
              CommandBarButton(
                  icon: const Icon(FluentIcons.delete, color: Colors.errorPrimaryColor,),
                  label: const Text('Delete Data'),
                  onPressed: (){

                    _gotoTab(0);

                    databaseService.deleteAll();
                    _queryFilesAndFolders();

                  }
              ),
              CommandBarButton(
                  icon: Icon(FluentIcons.cloud_upload, color: Colors.blue,),
                  label: const Text('Sync Local To Remote'),
                  onPressed: (){

                    _gotoTab(1);

                    SyncService.syncLocalToRemote(context);
                    _queryFilesAndFolders();

                  }
              ),
              CommandBarButton(
                  icon: const Icon(FluentIcons.cloud_download, color: Colors.successPrimaryColor,),
                  label: const Text('Sync Remote To Local'),
                  onPressed: (){

                    _gotoTab(1);

                    SyncService.syncRemoteToLocal(context);
                    _queryFilesAndFolders();

                  }
              ),
              CommandBarButton(
                  icon: const Icon(FluentIcons.play, color: Colors.successPrimaryColor,),
                  label: const Text('Test Button'),
                  onPressed: (){

                    DummyService.test();

                  }
              ),
            ],
          ),
        ),
      ),
      pane: NavigationPane(
        toggleable: false,
        selected: topIndex,
        onChanged: (index) => setState(() => topIndex = index),
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
              icon: Icon(FluentIcons.home), 
              title: Text('Home'),
              body: Row(
              children: [
                // Expanded(
                //     child: Container(
                //       child: Column(
                //         children: [
                //           Text('recorded events'),
                //           Expanded(
                //             child: ListView.builder(
                //               itemCount: eventList.length,
                //               itemBuilder: (context, index) {
                //                 return ListTile(
                //                   //title: Text(eventList[eventList.length - 1 -index].path),
                //                   title: Text(
                //                       eventList[eventList.length - 1 - index]
                //                           .toString()),
                //                   trailing: IconButton(
                //                       onPressed: () async {
                //                         //if not the first event in the list, dont do anything
                //                         // if(eventList.length - 1 - index != 0) return;
                //
                //                         // dynamic action = await processEvent();
                //
                //                         // if(action != null){
                //                         //   actionQueue.add(action);
                //                         //   setState(() {});
                //                         // }
                //                       },
                //                       icon: (eventList.length - 1 - index) == 0
                //                           ? Icon(FluentIcons.play)
                //                           : Icon(FluentIcons.square_shape)
                //                   ),
                //                 );
                //               },
                //             ),
                //           )
                //         ],
                //       ),
                //     )
                // ),
                // Expanded(
                //     child: Container(
                //       child: Column(
                //         children: [
                //           Text('processed events'),
                //           Expanded(
                //             child: ListView.builder(
                //               itemCount: actionQueue.length,
                //               itemBuilder: (context, index) {
                //                 return ListTile(
                //                   subtitle: Text(
                //                       actionQueue[actionQueue.length - 1 - index]
                //                           .toString()
                //                   ),
                //                   trailing: IconButton(
                //                       onPressed: () async {
                //                         //if not the first event in the list, dont do anything
                //                         if (actionQueue.length - 1 - index != 0)
                //                           return;
                //
                //                         databaseService.updateLocalDatabaseRecord(
                //                             queue: actionQueue[actionQueue.length -
                //                                 1 - index],
                //                             db: databaseService
                //                         );
                //
                //                         queryFilesAndFolders();
                //                       },
                //                       icon: (actionQueue.length - 1 - index) == 0
                //                           ? Icon(FluentIcons.play)
                //                           : Icon(FluentIcons.pause)
                //                   ),
                //                 );
                //               },
                //             ),
                //           )
                //         ],
                //       ),
                //     )
                // ),
                Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                              child: Column(
                                children: [
                                  Text('files'),
                                  Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text('id', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('local_path', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('local_timestamp', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('local_modified', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('remote_id', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('remote_timestamp', style: FluentTheme.of(context).typography.bodyStrong),),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: files.length,
                                      // Number of items in the list
                                      itemBuilder: (context, index) {
                                        // Build each item
                                        return listTemplate(
                                            context: context,
                                            id: files[index]['id'].toString(),
                                            localPath: files[index]['local_path']
                                                .toString(),
                                            localTimestamp: files[index]['local_timestamp']
                                                .toString(),
                                            localModified: files[index]['local_modified']
                                                .toString(),
                                            remoteId: files[index]['remote_id']
                                                .toString(),
                                            remoteTimestamp: files[index]['remote_timestamp']
                                                .toString()
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
                              child: Column(
                                children: [
                                  Text('Folders', style: FluentTheme.of(context).typography.subtitle,),
                                  Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text('id', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('local_path', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('local_timestamp', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('local_modified', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('remote_id', style: FluentTheme.of(context).typography.bodyStrong),),
                                        Expanded(child: Text('remote_timestamp', style: FluentTheme.of(context).typography.bodyStrong),),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: folders.length,
                                      // Number of items in the list
                                      itemBuilder: (context, index) {
                                        // Build each item
                                        return listTemplate(
                                            context: context,
                                            id: folders[index]['id'].toString(),
                                            localPath: folders[index]['local_path']
                                                .toString(),
                                            localTimestamp: folders[index]['local_timestamp']
                                                .toString(),
                                            localModified: folders[index]['local_modified']
                                                .toString(),
                                            remoteId: folders[index]['remote_id']
                                                .toString(),
                                            remoteTimestamp: folders[index]['remote_timestamp']
                                                .toString()
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
                              )
          ),
          PaneItem(
              icon: const Icon(FluentIcons.graph_symbol),
              body: Row(
                children: [
                  Expanded(
                      child: Container(
                        padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 30),
                        child: Column(
                          children: [
                            syncListTemplate(context: context, syncType: SyncType.newFolder),
                            syncListTemplate(context: context, syncType: SyncType.newFile),
                          ],
                        ),
                      )
                  ),
                  Expanded(
                      child: Container(
                        child: Column(
                          children: [
                            syncListTemplate(context: context, syncType: SyncType.modifiedFolder),
                            syncListTemplate(context: context, syncType: SyncType.modifiedFile),
                          ],
                        ),
                      )
                  ),
                ],
              )
          ),
          PaneItem(
          icon: Icon(FluentIcons.user_event),
          title: const Text('Login'),
          body: Container(
            padding: EdgeInsets.symmetric(vertical: 200, horizontal: 100),
            child: Column(
              children: [
                InfoLabel(
                  label: '',
                  child: const TextBox(
                    placeholder: 'Username',
                    expands: false,
                  ),
                ),
                SizedBox(height: 10),
                InfoLabel(
                  label: '',
                  child: const TextBox(
                    placeholder: 'Password',
                    expands: false,
                  ),
                ),
                SizedBox(height: 20),
                FilledButton(
                  child: const Text('Login'),
                  onPressed: () {
                    // Add login logic here
                  },
                ),
              ],
            ),
          ),
        ),
          PaneItem(
          icon: Icon(FluentIcons.view_dashboard),
          title: const Text('Dashboard'),
          body: Container(
            padding: EdgeInsets.symmetric(vertical: 50, horizontal: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20,),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: InfoBar(
                        title: Container(
                          height: 290,
                          width: MediaQuery.of(context).size.width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=4'),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'MUHAMMAD AIMAN BIN KHALIK',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            ]
                          ),
                        ),
                        isIconVisible: false,
                      ),
                    ),
                    SizedBox(width: 10,),
                    Expanded(
                      flex: 2,
                      child: InfoBar(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(FontAwesomeIcons.solidFolder, size: 40,),
                            SizedBox(height: 10,),
                            Text(
                              'FOLDER PATH : $tempDir',
                              style: TextStyle(fontSize: 12),
                            ),
                            Container(
                              padding: EdgeInsets.all(20),
                              height: 200,
                              child: ListView.builder(
                                  itemCount: 4,
                                  itemBuilder: (context, index) {

                                    List<dynamic> data = [
                                      {
                                        'icon': FluentIcons.info,
                                        'title' : 'Folder ID',
                                        'value': '21313'
                                      },
                                      {
                                        'icon': FluentIcons.folder_fill,
                                        'title' : 'Folder Path',
                                        'value': watchedDirectory
                                      },
                                      {
                                        'icon': FluentIcons.globe,
                                        'title' : 'Size',
                                        'value': '21313 MB'
                                      },
                                      {
                                        'icon': FluentIcons.sync,
                                        'title' : 'Last Scan',
                                        'value': '2 Minutes ago'
                                      },
                                    ];

                                    return Container(
                                      color: Provider.of<SyncProvider>(context).isSyncPaused ? Colors.transparent : index%2 == 0 ? Colors.grey[150] : Colors.grey[160] ,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Icon(data[index]['icon']),
                                              SizedBox(width: 10,),
                                              Text(data[index]['title'], style: FluentTheme.of(context).typography.body,),
                                            ],
                                          ),
                                          Text(data[index]['value'], style: FluentTheme.of(context).typography.body,),
                                        ],
                                      ),
                                    );
                                  }
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                actionButton(
                                    icon: FontAwesomeIcons.arrowsRotate,
                                    label: 'SYNC',
                                    onPressed: (){
                                      //SyncService.syncLocalFileFolderWithLocalDb();
                                    }
                                ),
                                if(Provider.of<SyncProvider>(context).isSyncPaused)
                                  actionButton(
                                      icon: FontAwesomeIcons.play,
                                      label: 'RESUME',
                                      onPressed: (){
                                        Provider.of<SyncProvider>(context, listen: false).setResume();
                                      }
                                  ),
                                if(!Provider.of<SyncProvider>(context).isSyncPaused)
                                  actionButton(
                                      icon: FontAwesomeIcons.pause,
                                      label: 'PAUSE',
                                      onPressed: (){
                                        Provider.of<SyncProvider>(context, listen: false).setPause();
                                      }
                                  )
                              ],
                            )
                          ],
                        ),
                        isIconVisible: false,
                        severity: Provider.of<SyncProvider>(context).isSyncPaused ? InfoBarSeverity.warning : InfoBarSeverity.info,
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20,),
                Expanded(
                  child: Container(
                    child: Row(
                      children: [
                        syncListTemplate(context: context, syncType: SyncType.newFolder),
                        syncListTemplate(context: context, syncType: SyncType.newFile),
                        syncListTemplate(context: context, syncType: SyncType.modifiedFolder),
                        syncListTemplate(context: context, syncType: SyncType.modifiedFile),
                      ],
                    ),
                  ),
                )
              ],
            )
          ),
        ),
        ],
        // footerItems: [
        //   PaneItem(
        //     icon: const Icon(FluentIcons.settings),
        //     title: const Text('Settings'),
        //     body: Container(),
        //   ),
        // ],
      ),
    );
    return NavigationView(
      //header: Text('Fluent UI Stateful Example'),
      content: Row(
        children: [
          Expanded(
              child: Container(
                child: Column(
                  children: [
                    Text('recorded events'),
                    Expanded(
                      child: ListView.builder(
                        itemCount: eventList.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            //title: Text(eventList[eventList.length - 1 -index].path),
                            title: Text(
                                eventList[eventList.length - 1 - index]
                                    .toString()),
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
                                icon: (eventList.length - 1 - index) == 0
                                    ? Icon(FluentIcons.play)
                                    : Icon(FluentIcons.square_shape)
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
                child: Column(
                  children: [
                    Text('processed events'),
                    Expanded(
                      child: ListView.builder(
                        itemCount: actionQueue.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            subtitle: Text(
                                actionQueue[actionQueue.length - 1 - index]
                                    .toString()
                            ),
                            trailing: IconButton(
                                onPressed: () async {
                                  //if not the first event in the list, dont do anything
                                  if (actionQueue.length - 1 - index != 0)
                                    return;

                                  databaseService.updateLocalDatabaseRecord(
                                      queue: actionQueue[actionQueue.length -
                                          1 - index],
                                      db: databaseService
                                  );

                                  _queryFilesAndFolders();
                                },
                                icon: (actionQueue.length - 1 - index) == 0
                                    ? Icon(FluentIcons.play)
                                    : Icon(FluentIcons.pause)
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
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                        child: Column(
                          children: [
                            Text('files'),
                            const Row(
                              children: [
                                Expanded(child: Text('id', style: TextStyle(
                                    fontWeight: FontWeight.bold)),),
                                Expanded(child: Text('local_path',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),),
                                Expanded(child: Text('local_timestamp',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),),
                                Expanded(child: Text('remote_id',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),),
                                Expanded(child: Text('remote_timestamp',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),),
                              ],
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: files.length,
                                // Number of items in the list
                                itemBuilder: (context, index) {
                                  // Build each item
                                  return listTemplate(
                                      context: context,
                                      id: files[index]['id'].toString(),
                                      localPath: files[index]['local_path']
                                          .toString(),
                                      localTimestamp: files[index]['local_timestamp']
                                          .toString(),
                                      localModified: folders[index]['local_modified']
                                          .toString(),
                                      remoteId: files[index]['remote_id']
                                          .toString(),
                                      remoteTimestamp: files[index]['remote_timestamp']
                                          .toString()
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
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Expanded(child: Text('id', style: TextStyle(
                                    fontWeight: FontWeight.bold)),),
                                Expanded(child: Text('local_path',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),),
                                Expanded(child: Text('local_timestamp',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),),
                                Expanded(child: Text('remote_id',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),),
                                Expanded(child: Text('remote_timestamp',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),),
                              ],
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: folders.length,
                                // Number of items in the list
                                itemBuilder: (context, index) {
                                  // Build each item
                                  return listTemplate(
                                      context: context,
                                      id: folders[index]['id'].toString(),
                                      localPath: folders[index]['local_path']
                                          .toString(),
                                      localTimestamp: folders[index]['local_timestamp']
                                          .toString(),
                                      localModified: folders[index]['local_modified']
                                          .toString(),
                                      remoteId: folders[index]['remote_id']
                                          .toString(),
                                      remoteTimestamp: folders[index]['remote_timestamp']
                                          .toString()
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
      // floatingActionButton: Row(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: <Widget>[
      //     FloatingActionButton(
      //       onPressed: () async {
      //         databaseService.deleteAll();
      //         queryFilesAndFolders();
      //       },
      //       child: Icon(Icons.delete),
      //     ),
      //     SizedBox(width: 20),
      //     FloatingActionButton(
      //       onPressed: () async {
      //         SyncService.syncLocalFolderWithDb(
      //             watchedDirectory: watchedDirectory);
      //       },
      //       child: Icon(Icons.sync),
      //     ),
      //   ],
      // ),
    );
  }
}







//-------------------------------------------------------------------------------------
