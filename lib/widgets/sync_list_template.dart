import 'package:fluent_ui/fluent_ui.dart';
import 'package:pdwatcher/models/file_folder_info.dart';
import 'package:pdwatcher/utils/enums.dart';
import 'package:pdwatcher/widgets/spinning_icon.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/sync_provider.dart';
import '../utils/types.dart';

syncListTemplate({
  required BuildContext context,
  required SyncType syncType,
}){

  int itemCount = 0;
  String title = '';

  switch (syncType) {
    case SyncType.newFile:
      title = 'New Files';
      itemCount = Provider.of<SyncProvider>(context, listen: true).newFiles.length;
      break;
    case SyncType.newFolder:
      title = 'New Folders';
      itemCount = Provider.of<SyncProvider>(context, listen: true).newFolders.length;
      break;
    case SyncType.modifiedFile:
      title = 'Modified Files';
      itemCount = Provider.of<SyncProvider>(context, listen: true).modifiedFiles.length;
      break;
    case SyncType.modifiedFolder:
      title = 'Modified Folders';
      itemCount = Provider.of<SyncProvider>(context, listen: true).modifiedFolders.length;
      break;
  }

  return Expanded(
      child: Container(
          padding: EdgeInsets.only(right: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: FluentTheme.of(context).typography.bodyStrong,),
              Expanded(
                child: ListView.builder(
                  itemCount: itemCount,
                  // Number of items in the list
                  itemBuilder: (context, index) {
                    // Build each item
                    return Container(
                      margin: EdgeInsets.all(5),
                      child: InfoBar(
                        title: Row(
                          children: [
                            switch (syncType) {
                              SyncType.newFile => _getFileIcon(Provider.of<SyncProvider>(context, listen: false).newFiles[index].localPath),
                              SyncType.newFolder => Icon(FontAwesomeIcons.solidFolder, color: Colors.orange,),
                              SyncType.modifiedFile => _getFileIcon(Provider.of<SyncProvider>(context, listen: false).modifiedFiles[index].localPath),
                              SyncType.modifiedFolder => Icon(FontAwesomeIcons.folder, color: Colors.orange,),
                            },
                            const SizedBox(width: 10,),
                            Expanded(
                              child: Text(switch (syncType) {
                                SyncType.newFile => Provider.of<SyncProvider>(context, listen: false).newFiles[index].localPath,
                                SyncType.newFolder => Provider.of<SyncProvider>(context, listen: false).newFolders[index].localPath,
                                SyncType.modifiedFile => Provider.of<SyncProvider>(context, listen: false).modifiedFiles[index].localPath,
                                SyncType.modifiedFolder => Provider.of<SyncProvider>(context, listen: false).modifiedFolders[index].localPath,
                              }, style: FluentTheme.of(context).typography.caption,),
                            ),
                            SizedBox(width: 20,),
                            //Icon(
                            switch (syncType) {
                              SyncType.newFile => _getIconData(Provider.of<SyncProvider>(context, listen: false).newFiles[index].syncStatus),
                              SyncType.newFolder => _getIconData(Provider.of<SyncProvider>(context, listen: false).newFolders[index].syncStatus),
                              SyncType.modifiedFile => _getIconData(Provider.of<SyncProvider>(context, listen: false).modifiedFiles[index].syncStatus),
                              SyncType.modifiedFolder => _getIconData(Provider.of<SyncProvider>(context, listen: false).modifiedFolders[index].syncStatus),
                            },
                            //  size: 15,
                            //)
                          ],
                        ),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10,),
                            Text('${syncType == SyncType.newFile || syncType == SyncType.newFolder ? 'Added' : 'Modified'}:', style: FluentTheme.of(context).typography.caption,),
                            Text(switch (syncType) {
                              SyncType.newFile => DateTime.fromMillisecondsSinceEpoch(Provider.of<SyncProvider>(context, listen: false).newFiles[index].localTimestamp).toString(),
                              SyncType.newFolder => DateTime.fromMillisecondsSinceEpoch(Provider.of<SyncProvider>(context, listen: false).newFolders[index].localTimestamp).toString(),
                              SyncType.modifiedFile => DateTime.fromMillisecondsSinceEpoch(Provider.of<SyncProvider>(context, listen: false).modifiedFiles[index].localTimestamp).toString(),
                              SyncType.modifiedFolder => DateTime.fromMillisecondsSinceEpoch(Provider.of<SyncProvider>(context, listen: false).modifiedFolders[index].localTimestamp).toString(),
                            }, style: FluentTheme.of(context).typography.caption,
                            ),
                            SizedBox(height: 10,),
                            switch (syncType) {
                                SyncType.newFile => _getProgress(Provider.of<SyncProvider>(context, listen: true).newFiles[index]),
                                SyncType.newFolder => _getProgress(Provider.of<SyncProvider>(context, listen: true).newFolders[index]),
                                SyncType.modifiedFile => _getProgress(Provider.of<SyncProvider>(context, listen: true).modifiedFiles[index]),
                                SyncType.modifiedFolder => _getProgress(Provider.of<SyncProvider>(context, listen: true).modifiedFolders[index]),
                            },
                            SizedBox(height: 10,),
                            switch (syncType) {
                              SyncType.newFile => _getErrorMessage(Provider.of<SyncProvider>(context, listen: false).newFiles[index].message, context),
                              SyncType.newFolder => _getErrorMessage(Provider.of<SyncProvider>(context, listen: false).newFolders[index].message, context),
                              SyncType.modifiedFile => _getErrorMessage(Provider.of<SyncProvider>(context, listen: false).modifiedFiles[index].message, context),
                              SyncType.modifiedFolder => _getErrorMessage(Provider.of<SyncProvider>(context, listen: false).modifiedFolders[index].message, context),
                            },

                          ],
                        ),
                        isIconVisible: false,

                      ),
                    );
                  },
                ),
              )
            ],
          )
      )
  );

}

Widget _getIconData(SyncStatus? status) {
  switch (status) {
    case null:
      return Container();
    case SyncStatus.pending:
      return Container();
    case SyncStatus.syncing:
      return SpinningIcon(icon: FontAwesomeIcons.arrowsRotate, color: Colors.blue);
    case SyncStatus.success:
      return const Icon(FontAwesomeIcons.arrowsRotate, color: Colors.successPrimaryColor);
    case SyncStatus.failed:
      return const Icon(FontAwesomeIcons.arrowsRotate, color: Colors.errorPrimaryColor);
    default:
      return const Icon(FontAwesomeIcons.arrowsRotate, color: Colors.warningPrimaryColor);
  }
  
}

Widget _getProgress(FileFolderInfo f) {

  if(f.syncStatus != SyncStatus.syncing || f.syncProgress == null){
    return Container();
  }
  else{
    return Row(
        children: [
          Expanded(
              child: ProgressBar(value: f.syncProgress)
          )
        ]
    );
  }


}

Icon _getFileIcon(String localPath) {

  String ext = localPath.split('.').last;

  switch (ext) {
    case 'docx':
      return Icon(FontAwesomeIcons.solidFileWord, color: Colors.blue);
    case 'xlsx':
      return Icon(FontAwesomeIcons.solidFileExcel, color: Colors.green);
    case 'pptx':
      return Icon(FontAwesomeIcons.solidFilePowerpoint, color: Colors.red);
    case 'pdf':
      return Icon(FontAwesomeIcons.solidFilePdf, color: Colors.orange);
    case 'txt':
      return Icon(FontAwesomeIcons.solidFileLines, color: Colors.yellow);
    case 'jpg':
    case 'jpeg':
    case 'png':
      return Icon(FontAwesomeIcons.solidFileImage, color: Colors.purple);
    case 'mp3':
    case 'wav':
      return Icon(FontAwesomeIcons.solidFileAudio, color: Colors.yellow);
    case 'mp4':
    case 'avi':
      return Icon(FontAwesomeIcons.solidFileVideo, color: Colors.teal);
    default:
      return Icon(FontAwesomeIcons.solidFile, color: Colors.yellow);
  }
}

Widget _getErrorMessage(String? message, context){

  return message == null ? Container() : Row(
    children: [
      Icon(FontAwesomeIcons.triangleExclamation, color: Colors.orange,),
      SizedBox(width: 10,),
      Flexible(child: Text(message, style: TextStyle(fontSize: 10, color: Colors.orange)),),
      SizedBox(width: 10,),
    ],
  );

}