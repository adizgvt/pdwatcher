import 'dart:io';

import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:pdwatcher/services/local_storage_service.dart';
import 'package:pdwatcher/utils/consts.dart';
import 'package:pdwatcher/widgets/appbar_template.dart';
import 'package:pdwatcher/widgets/wrapper_widget.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/package_info_provider.dart';
import '../providers/user_provider.dart';
import '../services/log_service.dart';
import '../services/tray_service.dart';
import '../widgets/notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.newLogin});

  final bool newLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TrayListener{

  TextEditingController emailController     = TextEditingController(text: '');
  TextEditingController passwordController  = TextEditingController(text: '');
  TextEditingController serverUrlController = TextEditingController(text: '');
  TextEditingController syncDirectory       = TextEditingController(text: '');

  bool absorb = false;

  @override
  void initState() {
    trayManager.addListener(this);
    _setLoginData();
    super.initState();
  }

  _setLoginData() async {

    //new full  => full detail
    if(widget.newLogin){

      //Provider.of<UserProvider>(context, listen: false).user = null;

      emailController.text      = initialUsername;
      passwordController.text   = initialPassword;
      serverUrlController.text  = initialServerurl;
      syncDirectory.text        = initialSyncDirectory;
    }
    //else just username password
    else {
      emailController.text      = await LocalStorage.getUsername()          ?? '';
      passwordController.text   = await LocalStorage.getPassword()          ?? '';
      serverUrlController.text  = await LocalStorage.getServerUrl()         ?? '';
      syncDirectory.text        = await LocalStorage.getWatchedDirectory()  ?? '';
    }
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
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
  
  @override
  Widget build(BuildContext context) {
    return wrapFluent(
      child: LoaderOverlay(
        child: NavigationView(
          appBar: appBarTemplate(),
          content: IgnorePointer(
            ignoring: absorb,
            child: Card(
              margin: const EdgeInsets.symmetric(vertical: 15),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Container(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(appLogo, height: 20,),
                      ],
                    ),
                    SizedBox(height: 20,),
                    Text(
                        'Hi, Welcome Back!',
                        style: FluentTheme.of(context).typography.subtitle
                    ),
                    SizedBox(height: 20,),
                    Text(
                        'Enter your details to get sign in to your account',
                        style: FluentTheme.of(context).typography.caption
                    ),
                    SizedBox(height: 20,),
                    Icon(FluentIcons.reminder_person),
                    const SizedBox(height: 10,),
                    PasswordBox(
                      placeholder: 'Username',
                      controller: emailController,
                      revealMode: PasswordRevealMode.visible,
                      enabled: widget.newLogin,
                    ),
                    SizedBox(height: 20,),
                    Icon(FluentIcons.password_field),
                    SizedBox(height: 10,),
                    PasswordBox(
                      placeholder: 'Password',
                      controller: passwordController,
                      revealMode: PasswordRevealMode.peek,
                    ),
                    SizedBox(height: 20,),
                    Icon(FluentIcons.link),
                    SizedBox(height: 10,),
                    PasswordBox(
                      placeholder: 'Server URL',
                      controller: serverUrlController,
                      revealMode: PasswordRevealMode.visible,
                      enabled: widget.newLogin,
                    ),
                    SizedBox(height: 20,),
                    Icon(FluentIcons.sync_folder),
                    SizedBox(height: 10,),
                    Row(
                      children: [
                        Expanded(
                          child: PasswordBox(
                            enabled: false,
                            placeholder: 'Sync Directory',
                            controller: syncDirectory,
                            revealMode: PasswordRevealMode.visible,
                          ),
                        ),
                        SizedBox(width: 20,),
                        if(widget.newLogin)
                        FilledButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) => Colors.black),
                          ),
                          child: Row(
                            children: [
                              Icon(FluentIcons.hard_drive),
                              SizedBox(width: 10,),
                              Text('SYNC DIRECTORY', style: TextStyle(fontSize: 12),)
                            ],
                          ),
                          onPressed: () async {

                            final file = DirectoryPicker()
                              ..title = 'Select a directory';

                            final result = file.getDirectory();


                            if (result == null) {
                              await NotificationBar.error(context, message: 'No directory selected');
                              return;
                            }

                            Log.info('Selected directory: ${result.path}');
                            syncDirectory.text = result.path;
                            setState(() {});




                          },
                        )
                      ],
                    ),
                    SizedBox(height: 20,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton(
                            child: Text('LOGIN'),
                            onPressed: () async {

                              if(emailController.text.isEmpty || passwordController.text.isEmpty){
                                await NotificationBar.error(context, message: 'Username and password cannot be empty');
                                return;
                              }

                            if(serverUrlController.text.isEmpty){
                              await NotificationBar.error(context, message: 'Server URL is not set');
                              return;
                            }

                            final directory = Directory(syncDirectory.text.trim());
                            if (!directory.existsSync()) {
                              await NotificationBar.error(context, message: 'Watched directory does not exist');
                              return;
                            }

                            bool isUsed = await LocalStorage.isDirectoryUsed(emailController.text.toLowerCase().trim(), syncDirectory.text.trim());

                            if (isUsed) {
                              NotificationBar.error(context, message: "⚠️ Directory already in use by another account.");
                              return;
                            }

                            bool directoryChanged = await LocalStorage.isDirectoryChanged(emailController.text.toLowerCase().trim(), syncDirectory.text.trim());

                            if (directoryChanged) {

                              String? previousDirectory = await LocalStorage.getPreviousSyncDirectory(emailController.text.toLowerCase().trim());

                              await showDialog<String>(
                                context: context,
                                builder: (context) => ContentDialog(
                                  title: const Text('Warning'),
                                  content: Text(
                                    'You have changed your sync directory. Previously it is $previousDirectory. If you continue, the old sync directory will be deleted and the application will re-sync all files in the new directory.',
                                  ),
                                  actions: [
                                    Button(
                                      child: const Text('Confirm'),
                                      onPressed: () async {
                                        Navigator.pop(context,'login');
                                      },
                                    ),
                                    FilledButton(
                                      child: const Text('Use Old Directory'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        syncDirectory.text = previousDirectory!;
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ).then((val){
                                if(val == 'login'){
                                  Provider.of<UserProvider>(context, listen: false).login(
                                    context             : context,
                                    email               : emailController.text.toLowerCase().trim(),
                                    password            : passwordController.text.trim(),
                                    serverUrl           : serverUrlController.text.trim(),
                                    syncDirectory       : syncDirectory.text.trim(),
                                    deleteOldDirectory  : true,
                                    oldDirectoryPath    : previousDirectory,
                                  );
                                }
                              });
                            }else {
                              Provider.of<UserProvider>(context, listen: false).login(
                                context       : context,
                                email         : emailController.text.toLowerCase().trim(),
                                password      : passwordController.text.trim(),
                                serverUrl     : serverUrlController.text.trim(),
                                syncDirectory : syncDirectory.text.trim(),
                              );
                            }



                            }
                        )
                      ],
                    ),
                    SizedBox(height: 10,),
                    Text(
                        '(${Provider.of<PackageInfoProvider>(context).versionCode}+${Provider.of<PackageInfoProvider>(context).versionNumber})',
                      style: TextStyle(fontSize: 10),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      )
    );
  }
}
