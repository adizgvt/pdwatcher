import 'dart:async';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdwatcher/extensions.dart';
import 'package:pdwatcher/providers/package_info_provider.dart';
import 'package:pdwatcher/screens/login_screen.dart';
import 'package:pdwatcher/services/tray_service.dart';
import 'package:pdwatcher/utils/enums.dart';
import 'package:pdwatcher/services/database_service.dart';
import 'package:pdwatcher/services/event_service.dart';
import 'package:pdwatcher/services/local_storage_service.dart';
import 'package:pdwatcher/services/sync_service.dart';
import 'package:pdwatcher/utils/consts.dart';
import 'dart:io';
import 'package:pdwatcher/utils/types.dart';
import 'package:pdwatcher/widgets/change_list_template.dart';
import 'package:pdwatcher/widgets/current_task.dart';
import 'package:pdwatcher/widgets/list_template.dart';
import 'package:pdwatcher/widgets/log_history.dart';
import 'package:pdwatcher/widgets/spinning_icon.dart';
import 'package:pdwatcher/widgets/sync_list_template.dart';
import 'package:pdwatcher/widgets/wrapper_widget.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../models/usage.dart';
import '../providers/sync_provider.dart';
import '../providers/user_provider.dart';
import '../services/file_service.dart';
import '../services/log_service.dart';
import '../widgets/action_button.dart';
import '../widgets/notification.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TrayListener{

  int topIndex = 2;

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

  Timer? timer;

  Timer? syncTimer;

  TextEditingController adminPanelPasswordController = TextEditingController();


  @override
  void initState() {
    trayManager.addListener(this);
    _checkDirExist();
    _initSqlDB();
    _startWatcher();
    _queryFilesAndFolders();
    _getVersion();

    super.initState();
  }

  _getVersion(){
    Provider.of<PackageInfoProvider>(context, listen: false).getDetails();
  }

  _checkDirExist() async {
    final directory = Directory(await LocalStorage.getWatchedDirectory() ?? '');
    if (!directory.existsSync()) {
      Log.error(' Sync Dir ${directory.path} not found');
      Log.error(' Sync Dir ${directory.path} not found');
      exit(1);
    }
  }

  _initSqlDB() async {
    sqfliteFfiInit();
    databaseFactoryOrNull = databaseFactoryFfi;
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

    timer = Timer.periodic(const Duration(milliseconds: 1), (Timer timer) async {

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

        if(
          actionQueue.first['event']['action'] == QueueAction.delete &&
          actionQueue.length > 1 &&
          actionQueue[1]['event']['action'] == QueueAction.create &&
          actionQueue[0]['event']['path'].toString().split('\\').last == actionQueue[1]['event']['path'].split('\\').last //means same file
        ){

          //ignore first
          print('ignoring ${actionQueue.first}');

          //update next queue create -> move
          print('updating next queue');
          actionQueue[1]['event']['action'] = QueueAction.move;
          actionQueue[1]['event']['from']   = actionQueue[0]['event']['path'];
          actionQueue[1]['event']['to']     = actionQueue[1]['event']['path'];

        } else {
          databaseService.updateLocalDatabaseRecord(
            queue: actionQueue.first,
            db: databaseService,
          );
        }

        actionQueue.removeAt(0);
        files       = await databaseService.queryAllFiles();
        folders     = await databaseService.queryAllFolders();
        setState(() {});
      }

      runningQueue = false;

    });

    // syncTimer = Timer.periodic(const Duration(seconds: 10), (Timer timer) async {
    //
    //   await Provider.of<SyncProvider>(context, listen: false).getUsage();
    //
    //   if(Provider.of<SyncProvider>(context, listen: false).isSyncing){
    //     Log.verbose('--IS SYNCING--');
    //     return;
    //   }
    //
    //   Provider.of<SyncProvider>(context, listen: false).isSyncing = true;
    //   Provider.of<SyncProvider>(context, listen: false).updateUI();
    //
    //   await SyncService.syncRemoteToLocal(context);
    //   await SyncService.syncLocalToRemote(context);
    //
    //   Provider.of<SyncProvider>(context, listen: false).isSyncing = false;
    //   Provider.of<SyncProvider>(context, listen: false).updateUI();
    //
    // });
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
  void dispose() {

    trayManager.removeListener(this);

    if(timer != null){
      timer!.cancel();
      timer = null;
    }

    if(syncTimer != null){
      syncTimer!.cancel();
      syncTimer = null;
    }

    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    TrayService.onTrayIconMouseDown();
  }

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    TrayService.onTrayMenuItemClick(menuItem, context);
  }

  getPackageInfo(){

  }

  @override
  Widget build(BuildContext context) {

    return wrapFluent(
      child: NavigationView(
        appBar: NavigationAppBar(
          automaticallyImplyLeading: false,
          height: 60,
          title: Column(
            children: [
              Row(
                children: [
                  Image.asset('assets/pd.ico', height: 15,),
                  Text(''),
                  SizedBox(width: 10,),
                  Text('Pocket Data Sync Client (${Provider.of<PackageInfoProvider>(context).versionCode}+${Provider.of<PackageInfoProvider>(context).versionNumber})'),
                  Expanded(
                    child: GestureDetector(
                        child: Container(
                          color: Colors.grey[20],
                          height: 30,
                        ),
                        onPanStart: (details) {
                          windowManager.startDragging();
                        }
                    ),
                  ),
                  Tooltip(
                    message: 'Minimize',
                    child: IconButton(
                      icon: const Icon(FluentIcons.local_admin, size: 12.0),
                      onPressed: () async{
                        await showDialog<String>(
                          context: context,
                          builder: (context) => ContentDialog(
                            title: const Text('Admin Panel'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Please enter admin password to ${showAllMenu ? 'hide' : 'show'} admin panel',
                                ),
                                SizedBox(height: 10,),
                                PasswordBox(
                                  placeholder: 'Password',
                                  controller: adminPanelPasswordController,
                                  revealMode: PasswordRevealMode.peek,
                                )
                              ],
                            ),
                            actions: [
                              FilledButton(
                                child: const Text('SUBMIT'),
                                onPressed: () async {
                                  if(adminPanelPasswordController.text.trim() == adminPassword){
                                    Navigator.pop(context);
                                    adminPanelPasswordController.text = '';
                                    showAllMenu = !showAllMenu;
                                    setState(() {});
                                  } else {
                                    await NotificationBar.error(context, message: 'Incorrect password');
                                    adminPanelPasswordController.text = '';
                                  }
                                },
                              ),
                              Button(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10,),
                  Tooltip(
                    message: 'Log out',
                    child: IconButton(
                      icon: Icon(FluentIcons.close_pane, color: Colors.red,),
                      onPressed: () async {

                        await showDialog<String>(
                            context: context,
                            builder: (context) => ContentDialog(
                              title: const Text('End Sync'),
                              content: const Text(
                                'Logging out will stop file synchronization. Would you like to continue?',
                              ),
                              actions: [
                                Button(
                                  child: const Text('Logout'),
                                  onPressed: () async {
                                    await LocalStorage.clearData();

                                    if(timer != null){
                                      timer!.cancel();
                                      timer = null;
                                    }

                                    if(syncTimer != null){
                                      syncTimer!.cancel();
                                      syncTimer = null;
                                    }

                                    Provider.of<SyncProvider>(context, listen: false).isSyncing = false;
                                    Provider.of<SyncProvider>(context, listen: false).updateUI();

                                    Navigator.pushAndRemoveUntil(context, FluentPageRoute(builder: (_) => const LoginScreen(newLogin: true)), (route) => false);

                                    // Delete file here
                                  },
                                ),
                                FilledButton(
                                  child: const Text('Cancel'),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                      },
                    ),
                  ),
                  SizedBox(width: 10,),
                  Tooltip(
                    message: 'Minimize',
                    child: IconButton(
                      icon: const Icon(FluentIcons.chrome_minimize, size: 12.0),
                      onPressed: () {
                        windowManager.minimize();
                        //windowManager.hide();
                      },
                    ),
                  ),

                ],
              ),
              if(showAllMenu)
              Padding(
                padding: EdgeInsets.zero,
                child: CommandBar(
                  overflowBehavior: CommandBarOverflowBehavior.noWrap,
                  primaryItems: [
                    CommandBarButton(
                        icon: Icon(FluentIcons.sync, color: Colors.blue,),
                        label: Text('Sync Local Folder With Local Db' ,style: FluentTheme.of(context).typography.caption,),
                        onPressed: () async {

                          _gotoTab(0);

                          await SyncService.syncLocalFileFolderWithLocalDb().then((val){
                            _queryFilesAndFolders();
                          });


                        }
                    ),
                    CommandBarButton(
                        icon: const Icon(FluentIcons.delete, color: Colors.errorPrimaryColor,),
                        label: Text('Delete Data' ,style: FluentTheme.of(context).typography.caption,),
                        onPressed: (){

                          _gotoTab(0);

                          databaseService.deleteAll();
                          _queryFilesAndFolders();

                        }
                    ),
                    CommandBarButton(
                        icon: Icon(FluentIcons.cloud_upload, color: Colors.blue,),
                        label: Text('Sync Local To Remote' ,style: FluentTheme.of(context).typography.caption,),
                        onPressed: (){

                          _gotoTab(1);

                          SyncService.syncLocalToRemote(context);
                          _queryFilesAndFolders();

                        }
                    ),
                    CommandBarButton(
                        icon: const Icon(FluentIcons.cloud_download, color: Colors.successPrimaryColor,),
                        label: Text('Sync Remote To Local' ,style: FluentTheme.of(context).typography.caption,),
                        onPressed: (){

                          _gotoTab(2);

                          SyncService.syncRemoteToLocal(context);
                          _queryFilesAndFolders();

                        }
                    ),
                    CommandBarButton(
                        icon: const Icon(FluentIcons.play, color: Colors.successPrimaryColor,),
                        label: Text('Test Button' ,style: FluentTheme.of(context).typography.caption,),
                        onPressed: () async {

                          //DatabaseService databaseService = DatabaseService();

                          //databaseService.queryByRemoteId(remoteId: 1, mimetype: 2);

                          final result = await FileService.uploadChunk(
                            //filePath: 'C:\\Users\\user\\Desktop\\watch\\yo\\yi\\Screenshot 2024-11-26 134729.png',
                              filePath: 'C:\\Users\\user\\Downloads\\JetBrains.dotPeek.2024.3.3.web.exe',
                              parentId: 914,
                              context : context
                          );
                        }
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pane: NavigationPane(
          toggleable: false,
          selected: topIndex,
          onChanged: (index) {
            setState(() {
              print(index);
              topIndex = index;
            });
          },
          displayMode: PaneDisplayMode.compact,
          items: [
            if(showAllMenu)
            PaneItem(
                icon: Icon(FluentIcons.database),
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
                            child: Column(
                              children: [
                                // SizedBox(height: 10,),
                                // Row(
                                //   mainAxisAlignment: MainAxisAlignment.start,
                                //   children: [
                                //     SizedBox(width: 10,),
                                //     Text('LOCAL DATABASE RECORD', style: FluentTheme.of(context).typography.bodyStrong,),
                                //   ],
                                // ),
                                // SizedBox(height: 5,),
                                // Divider(),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white, // White background
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        // BoxShadow(
                                        //   color: Colors.black.withOpacity(0.1),
                                        //   blurRadius: 5,
                                        //   spreadRadius: 2,
                                        // ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(FluentIcons.document, size: 16, color: Colors.blue),
                                            const SizedBox(width: 8),
                                            Text(
                                              'FILES',
                                              style: FluentTheme.of(context).typography.caption?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Expanded(
                                          child: CustomScrollView(
                                            slivers: [
                                              SliverList(
                                                delegate: SliverChildBuilderDelegate(
                                                      (context, index) {
                                                    final displayTitle = index == 0;
                                                    return listTemplate(
                                                      context: context,
                                                      id: files[index]['id'].toString(),
                                                      localPath: files[index]['local_path'].toString(),
                                                      localTimestamp: files[index]['local_timestamp'].toString(),
                                                      localModified: files[index]['local_modified'].toString(),
                                                      remoteId: files[index]['remote_id'].toString(),
                                                      remoteTimestamp: files[index]['remote_timestamp'].toString(),
                                                      toDelete: files[index]['to_delete'].toString(),
                                                      showTitle: displayTitle,
                                                    );
                                                  },
                                                  childCount: files.length, // Number of items in the list
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10,),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        // BoxShadow(
                                        //   color: Colors.black.withOpacity(0.1),
                                        //   blurRadius: 5,
                                        //   spreadRadius: 2,
                                        // ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(FluentIcons.folder, size: 16, color: Colors.orange),
                                            const SizedBox(width: 8),
                                            Text(
                                              'FOLDERS',
                                              style: FluentTheme.of(context).typography.caption?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5), // Space below title
                                        Expanded(
                                          child: CustomScrollView(
                                            slivers: [
                                              SliverList(
                                                delegate: SliverChildBuilderDelegate(
                                                      (context, index) {
                                                    final displayTitle = index == 0;
                                                    return listTemplate(
                                                      context: context,
                                                      id: folders[index]['id'].toString(),
                                                      localPath: folders[index]['local_path'].toString(),
                                                      localTimestamp: folders[index]['local_timestamp'].toString(),
                                                      localModified: folders[index]['local_modified'].toString(),
                                                      remoteId: folders[index]['remote_id'].toString(),
                                                      remoteTimestamp: folders[index]['remote_timestamp'].toString(),
                                                      toDelete: folders[index]['to_delete'].toString(),
                                                      showTitle: displayTitle,
                                                    );
                                                  },
                                                  childCount: folders.length,
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      )
                  ),
                ],
                                )
            ),
            PaneItem(
                icon: const Icon(FluentIcons.cloud_upload),
                body: Container(
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                          child: Container(
                            padding: const EdgeInsets.only(left: 20, right: 10, top: 20, bottom: 30),
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
                            padding: const EdgeInsets.only(left: 10, right: 20, top: 20, bottom: 30),
                            child: Column(
                              children: [
                                syncListTemplate(context: context, syncType: SyncType.modifiedFolder),
                                syncListTemplate(context: context, syncType: SyncType.modifiedFile),
                              ],
                            ),
                          )
                      ),
                    ],
                  ),
                )
            ),
            PaneItem(
                icon: Icon(FluentIcons.cloud_download),
                body: Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(FluentIcons.cloud, size: 20, color: Colors.blue), // Cloud Icon
                                  SizedBox(width: 8),
                                  Text(
                                    "Cloud Files",
                                    style: FluentTheme.of(context).typography.caption?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Expanded(child: changeListTemplate(context, changeType: FileChangeEnum.files))
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 10), // Add space between columns
                      // Expanded(
                      //   child: Container(
                      //     padding: EdgeInsets.all(8),
                      //     child: Column(
                      //       children: [
                      //         Row(
                      //           children: [
                      //             Icon(FluentIcons.delete, size: 20, color: Colors.red), // Cloud Icon
                      //             SizedBox(width: 8),
                      //             Text(
                      //               "Deleted Files",
                      //               style: FluentTheme.of(context).typography.caption?.copyWith(fontWeight: FontWeight.bold),
                      //             ),
                      //           ],
                      //         ),
                      //         SizedBox(height: 8),
                      //         Expanded(child: changeListTemplate(context, changeType: FileChangeEnum.filesDeleted))
                      //       ],
                      //     ),
                      //   ),
                      // ),
                      // Uncomment for the third column
                      // SizedBox(width: 10),
                      // Expanded(
                      //   child: Container(
                      //     padding: EdgeInsets.all(8),
                      //     decoration: BoxDecoration(
                      //       color: Colors.green[50],
                      //       borderRadius: BorderRadius.circular(10),
                      //     ),
                      //     child: changeListTemplate(context, changeType: FileChangeEnum.shareFiles),
                      //   ),
                      // ),
                    ],
                  ),
                )

            ),
            PaneItem(
            icon: Icon(FluentIcons.view_dashboard),
            title: const Text('Dashboard'),
            body: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20,),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child:  Container(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundImage: NetworkImage(Provider.of<UserProvider>(context, listen: false).user!.userPicture),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  Provider.of<UserProvider>(context, listen: false).user!.userName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  Provider.of<UserProvider>(context, listen: false).user!.userEmail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),

                              ]
                          ),
                        ),
                      ),
                      SizedBox(width: 10,),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Button(
                                  style: ButtonStyle(
                                    backgroundColor: ButtonState.all(Provider.of<SyncProvider>(context).isOffline ? Colors.orange : Colors.green),
                                  ),
                                  onPressed: (){},
                                  child: Row(
                                    children: [Text(Provider.of<SyncProvider>(context).isOffline ? 'Offline' : 'Online', style: TextStyle(color: Colors.white, fontSize: 10),)
                                    ],
                                  ),
                                ),
                                if(Provider.of<SyncProvider>(context).isSyncingUp)
                                  SpinningIcon(icon: FontAwesomeIcons.arrowsRotate, color: Colors.blue),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.all(20),
                              height: 160,
                              child: ListView.builder(
                                  itemCount: 3,
                                  itemBuilder: (context, index) {

                                    Usage? usage = Provider.of<SyncProvider>(context, listen: true).usage;

                                    List<dynamic> data = [
                                      {
                                        'icon': FluentIcons.info,
                                        'title' : 'Folder ID',
                                        'value': usage == null ? '-' : usage.rootParentId.toString()
                                      },
                                      {
                                        'icon': FluentIcons.folder_fill,
                                        'title' : 'Folder Path',
                                        'value': watchedDirectory
                                      },
                                      {
                                        'icon': FluentIcons.globe,
                                        'title' : 'Usage',
                                        'value':  usage == null ? '-' : '${usage.usage.getSize()} / ${usage.quota} GB'
                                      }
                                    ];

                                    return Container(
                                      color: Provider.of<SyncProvider>(context).isSyncPaused ? Colors.transparent : index%2 == 0 ? Colors.grey[30] : Colors.grey[20] ,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            children: [
                                              Icon(data[index]['icon']),
                                              SizedBox(width: 10,),
                                              Text(data[index]['title'], style: FluentTheme.of(context).typography.caption,),
                                            ],
                                          ),
                                          Text(data[index]['value'], style: FluentTheme.of(context).typography.caption,),
                                        ],
                                      ),
                                    );
                                  }
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // actionButton(
                                //     icon: FontAwesomeIcons.trash,
                                //     label: 'DELETE ALL',
                                //     onPressed: () async {
                                //       databaseService.deleteAll();
                                //       _queryFilesAndFolders();
                                //     }
                                // ),
                                // actionButton(
                                //     icon: FontAwesomeIcons.trash,
                                //     label: 'RESTART',
                                //     onPressed: () async {
                                //       RestartFromOS.restartApp(appName: 'build\\windows\\x64\\runner\\Debug\\pdwatcher');
                                //     }
                                // ),
                                // if(Provider.of<SyncProvider>(context).isSyncPaused)
                                //   actionButton(
                                //       icon: FontAwesomeIcons.play,
                                //       label: 'RESUME',
                                //       onPressed: (){
                                //         Provider.of<SyncProvider>(context, listen: false).setResume();
                                //       }
                                //   ),
                                // if(!Provider.of<SyncProvider>(context).isSyncPaused)
                                //   actionButton
                                //       icon: FontAwesomeIcons.pause,
                                //       label: 'PAUSE',
                                //       onPressed: (){
                                //         Provider.of<SyncProvider>(context, listen: false).setPause();
                                //       }
                                //   )
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 20,),
                  if(showAllMenu)
                  Container(
                    height: 200,
                    child: logHistory(context),
                  ),
                  if(!showAllMenu)
                  CurrentTaskWidget()
                ],
              )
            ),
          ),
            if(showAllMenu)
            PaneItem(
                icon: Icon(FluentIcons.list),
                body: logHistory(context)
            ),
          ],
        ),
      ),
    );
  }
}







//-------------------------------------------------------------------------------------
