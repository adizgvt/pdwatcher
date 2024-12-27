import 'dart:io';

import 'package:filepicker_windows/filepicker_windows.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:pdwatcher/models/User.dart';
import 'package:pdwatcher/models/api_response.dart';
import 'package:pdwatcher/screens/home_screen.dart';
import 'package:pdwatcher/services/local_storage_service.dart';
import 'package:pdwatcher/utils/consts.dart';
import 'package:pdwatcher/widgets/wrapper_widget.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/log_service.dart';
import '../utils/enums.dart';
import '../widgets/notification.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.newLogin});

  final bool newLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  TextEditingController emailController  = TextEditingController(text: '');
  TextEditingController passwordController  = TextEditingController(text: '');
  TextEditingController serverUrlController = TextEditingController(text: '');
  TextEditingController syncDirectory       = TextEditingController(text: '');

  bool absorb = false;

  @override
  void initState() {
    _setLoginData();
    super.initState();
  }

  _setLoginData() async {

    //new full  => full detail
    if(widget.newLogin){
      emailController.text   = initialUsername;
      passwordController.text   = initialPassword;
      serverUrlController.text  = initialServerurl;
      syncDirectory.text        = initialSyncDirectory;
    }
    //else just username password
    else {
      emailController.text   = await LocalStorage.getUsername() ?? '';
      passwordController.text   = await LocalStorage.getPassword() ?? '';
      serverUrlController.text  = await LocalStorage.getServerUrl() ?? '';
      syncDirectory.text        = await LocalStorage.getWatchedDirectory() ?? '';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return wrapFluent(
      child: LoaderOverlay(
        child: NavigationView(
          content: IgnorePointer(
            ignoring: absorb,
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 30),
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Container(
                width: 600,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(appLogo, height: 40,),
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
                          child: Text('Select'),
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
                    SizedBox(height: 50,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton(
                            child: Text('Login'),
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

                            Provider.of<UserProvider>(context, listen: false).login(
                              context: context,
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                              serverUrl: serverUrlController.text.trim(),
                              syncDirectory: syncDirectory.text.trim(),
                            );

                            }
                        )
                      ],
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
