import 'package:fluent_ui/fluent_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdwatcher/models/change.dart';
import 'package:pdwatcher/providers/sync_provider.dart';
import 'package:pdwatcher/utils/enums.dart';
import 'package:provider/provider.dart';

changeListTemplate(context, {required FileChangeEnum changeType}){

  List<dynamic> data = [];

  var syncProvider = Provider.of<SyncProvider>(context, listen: false);
  if(changeType == FileChangeEnum.files){
    data = syncProvider.change?.files ?? [];
  }
  if(changeType == FileChangeEnum.filesDeleted){
    data = syncProvider.change?.filesDeleted ?? [];
  }
  if(changeType == FileChangeEnum.shareFiles){
    data = syncProvider.change?.shareFile ?? [];
  }

  return CustomScrollView(
    slivers: [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {

          if (changeType == FileChangeEnum.filesDeleted){

            return Container(
              margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: Card(
                child: Text('''
              id      : ${data[index].id}
              fileid : ${data[index].fileid}
              storage : ${data[index].storage}
              '''.replaceAll(' ', '')
                  ,style: FluentTheme.of(context).typography.caption,
                ),
              ),
            );
          }

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
            child: Card(
              child: ListTile(
                leading: _getMimeTypeIcon(data[index].mimetype),
                title: Text(data[index].path,style: FluentTheme.of(context).typography.caption,),
                subtitle: Table(
                  columnWidths: {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
                  children: [
                    TableRow(
                      children: [
                        Text('file_id', style: TextStyle(fontSize: 10)),
                        Text(': ${data[index].remotefileId}', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    TableRow(
                      children: [
                        Text('Storage_id', style: TextStyle(fontSize: 10)),
                        Text(': ${data[index].storage}', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    TableRow(
                      children: [
                        Text('Size', style: TextStyle(fontSize: 10)),
                        Text(': ${data[index].size}', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    TableRow(
                      children: [
                        Text('mtime', style: TextStyle(fontSize: 10)),
                        Text(': ${DateTime.fromMillisecondsSinceEpoch(data[index].mtime*1000).toLocal().toString().substring(0,19)}', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    if(data[index].mimetype != 2 && data[index].syncStatus != null)
                    TableRow(
                      children: [
                        Text('Status', style: TextStyle(fontSize: 10)),
                        Text(
                            ': ${data[index].syncStatus.toString()}',
                            style: TextStyle(
                                fontSize: 10,
                                color: data[index].syncStatus == SyncStatus.pending ? Colors.grey :
                                       data[index].syncStatus == SyncStatus.syncing ? Colors.orange :
                                       data[index].syncStatus == SyncStatus.success ? Colors.green :
                                       data[index].syncStatus == SyncStatus.failed ? Colors.red : Colors.black,
                            )
                        ),
                      ],
                    ),
                    if(data[index].errorMessage != null)
                      TableRow(
                        children: [
                          Text('Error', style: TextStyle(fontSize: 10)),
                          Text(': ${data[index].errorMessage}', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        }, childCount: data.length),
      ),
    ],
  );
}

_getMimeTypeIcon(int id) {
  var icon;
  switch (id) {
    case 1:
      icon = Icon(FontAwesomeIcons.globe, color: Colors.blue); // httpd
      break;
    case 2:
      icon = Icon(FontAwesomeIcons.solidFolder, color: Colors.orange); // httpd/unix-directory
      break;
    case 3:
      icon = Icon(FontAwesomeIcons.solidFile, color: Colors.grey); // application
      break;
    case 4:
      icon = Icon(FontAwesomeIcons.solidFile, color: Colors.grey); // application/vnd.oasis.opendocument.text
      break;
    case 5:
      icon = Icon(FontAwesomeIcons.solidFilePdf, color: Colors.red); // application/pdf
      break;
    case 6:
      icon = Icon(FontAwesomeIcons.solidImage, color: Colors.purple); // image
      break;
    case 7:
      icon = Icon(FontAwesomeIcons.solidImage, color: Colors.purple); // image/jpeg
      break;
    case 8:
      icon = Icon(FontAwesomeIcons.download, color: Colors.grey); // application/octet-stream
      break;
    case 9:
      icon = Icon(FontAwesomeIcons.video, color: Colors.orange); // video
      break;
    case 10:
      icon = Icon(FontAwesomeIcons.video, color: Colors.orange); // video/mp4
      break;
    case 11:
      icon = Icon(FontAwesomeIcons.solidImage, color: Colors.purple); // image/png
      break;
    case 12:
      icon = Icon(FontAwesomeIcons.download, color: Colors.grey); // application/x-ms-dos-executable
      break;
    case 14:
      icon = Icon(FontAwesomeIcons.solidFileWord, color: Colors.blue); // application/vnd.openxmlformats-officedocument.wordprocessingml.document
      break;
    case 15:
      icon = Icon(FontAwesomeIcons.code, color: Colors.blue); // text/x-php
      break;
    case 16:
      icon = Icon(FontAwesomeIcons.solidFileAlt, color: Colors.orange); // text
      break;
    case 17:
      icon = Icon(FontAwesomeIcons.solidFileExcel, color: Colors.green); // application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      break;
    case 18:
      icon = Icon(FontAwesomeIcons.solidFileAlt, color: Colors.grey[100]); // text/plain
      break;
    case 19:
      icon = Icon(FontAwesomeIcons.solidFolderOpen, color: Colors.green); // inode/x-empty
      break;
    case 20:
      icon = Icon(FontAwesomeIcons.solidFolder, color: Colors.green); // inode
      break;
    case 22:
      icon = Icon(FontAwesomeIcons.solidFileWord, color: Colors.blue); // application/msword
      break;
    case 23:
      icon = Icon(FontAwesomeIcons.solidFilePowerpoint, color: Colors.green); // application/vnd.openxmlformats-officedocument.presentationml.presentation
      break;
    case 24:
      icon = Icon(FontAwesomeIcons.solidFileExcel, color: Colors.green); // application/vnd.ms-excel
      break;
    case 25:
      icon = Icon(FontAwesomeIcons.solidFileArchive, color: Colors.grey); // application/x-zip
      break;
    case 26:
      icon = Icon(FontAwesomeIcons.code, color: Colors.blue); // application/x-httpd-php
      break;
    case 27:
      icon = Icon(FontAwesomeIcons.video, color: Colors.orange); // video/3gpp
      break;
    case 28:
      icon = Icon(FontAwesomeIcons.solidImage, color: Colors.purple); // image/gif
      break;
    case 29:
      icon = Icon(FontAwesomeIcons.code, color: Colors.blue); // text/x-c++
      break;
    case 30:
      icon = Icon(FontAwesomeIcons.html5, color: Colors.blue); // text/html
      break;
    case 31:
      icon = Icon(FontAwesomeIcons.solidFileArchive, color: Colors.grey); // application/zip
      break;
    case 32:
      icon = Icon(FontAwesomeIcons.solidFilePowerpoint, color: Colors.green); // application/vnd.oasis.opendocument.presentation
      break;
    case 33:
      icon = Icon(FontAwesomeIcons.solidFile, color: Colors.orange); // application/vnd.ms-office
      break;
    default:
      icon = Icon(FontAwesomeIcons.solidQuestionCircle, color: Colors.grey); // unknown
      break;
  }
  return icon;
}