import 'dart:convert';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:pdwatcher/screens/home_screen.dart';
import 'package:pdwatcher/services/drive_service.dart';
import 'package:pdwatcher/services/log_service.dart';
import 'package:pdwatcher/widgets/wrapper_widget.dart';
import 'package:provider/provider.dart';

import '../models/User.dart';
import '../models/api_response.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../utils/enums.dart';
import '../widgets/notification.dart';
import 'login_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {


      final result = await DriveInfo.getDriveName();

      if(!result){
        showDialog<String>(
          context: context,
          builder: (context) => const ContentDialog(
            title: Text('Error'),
            content: Text(
              'Fail to get Windows drive name',
            ),
          ),
        );
        return;
      }

      Provider.of<UserProvider>(context, listen: false).autoLogin(context);
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return wrapFluent(child: Center(child: ProgressRing()));
  }
}
