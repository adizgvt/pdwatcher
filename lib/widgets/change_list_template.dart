import 'package:fluent_ui/fluent_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdwatcher/extensions.dart';
import 'package:pdwatcher/models/change.dart';
import 'package:pdwatcher/providers/sync_provider.dart';
import 'package:pdwatcher/utils/enums.dart';
import 'package:provider/provider.dart';

TableRow createTableRow(String label1, value1, label2, value2) {
  return TableRow(
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label1,
            style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w300),
          ),
          Text(
            '${value1.data}',  // Adding colon before the value
            style: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      Padding(
        padding: EdgeInsets.only(top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label2,
              style: GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w300),
            ),
            Text(
              '${value2.data}',  // Adding colon before the value
              style: GoogleFonts.roboto(fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ],
  );
}


changeListTemplate(context, {required FileChangeEnum changeType}) {
  List<dynamic> data = [];

  var syncProvider = Provider.of<SyncProvider>(context, listen: false);
  if (changeType == FileChangeEnum.files) {
    data = syncProvider.change?.files ?? [];
  }
  if (changeType == FileChangeEnum.filesDeleted) {
    data = syncProvider.change?.filesDeleted ?? [];
  }
  if (changeType == FileChangeEnum.shareFiles) {
    data = syncProvider.change?.shareFile ?? [];
  }

  return CustomScrollView(
    slivers: [
      SliverList(
        delegate: SliverChildBuilderDelegate(
              (context, index) {
            if (changeType == FileChangeEnum.filesDeleted) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                child: Table(
                  columnWidths: {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
                  children: [
                    createTableRow('id', Text('${data[index].id}'), 'file_id', Text('${data[index].fileid}')),
                    createTableRow('storage', Text('${data[index].storage}'), '', Container()),
                  ],
                ),
              );
            }

            int size = data[index].size;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
              child: ListTile(
                title: Row(
                  children: [
                    _getMimeTypeIcon(data[index].mimetype, size: 30),
                    SizedBox(width: 10),
                    Text(
                      data[index].name,
                      style: GoogleFonts.roboto(fontSize: 13, color: Colors.black, fontWeight: FontWeight.w500),
                    ),
                    Expanded(child: Container()),
                    SizedBox(width: 10,),
                    _getSyncStatusIcon(data[index].syncStatus),

                  ],
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(left: 40),
                  child: Table(
                    columnWidths: {0: FlexColumnWidth(1), 1: FlexColumnWidth(1)},
                    children: [
                      const TableRow(
                        children: [
                          SizedBox(height: 5),
                          SizedBox(height: 5),
                        ],
                      ),
                      createTableRow(
                          'File ID',
                          Text('${data[index].remotefileId}'),
                          'Storage ID',
                          Text('${data[index].storage}')
                      ),
                      createTableRow(
                          'Path',
                          Text('${data[index].path}'),
                          'Size',
                          Text('${size.getSize()}')
                      ),
                      createTableRow(
                          'Modified Time',
                          Text('${DateTime.fromMillisecondsSinceEpoch(data[index].mtime * 1000).toLocal().toString().substring(0, 19)}'),
                          data[index].errorMessage == null ? '' : 'Error',
                          Text(data[index].errorMessage ?? '')
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          childCount: data.length,
        ),
      ),
    ],
  );
}

// Helper function to get sync status icon
Widget _getSyncStatusIcon(SyncStatus? syncStatus) {
  switch (syncStatus) {
    case SyncStatus.success:
      return Icon(FontAwesomeIcons.checkCircle, color: Colors.green, size: 20); // Sync complete icon
    case SyncStatus.syncing:
      return Icon(FontAwesomeIcons.syncAlt, color: Colors.blue, size: 20); // Sync in progress icon
    case SyncStatus.failed:
      return Icon(FontAwesomeIcons.timesCircle, color: Colors.red, size: 20); // Sync failed icon
  case null:
      return Icon(FontAwesomeIcons.questionCircle, color: Colors.grey, size: 20); // Unknown status icon
    default:
      return Icon(FontAwesomeIcons.questionCircle, color: Colors.grey, size: 20); // Unknown status icon
  }
}

_getMimeTypeIcon(int id, {double size = 24.0}) {
  var icon;
  switch (id) {
    case 1:
      icon = Icon(FontAwesomeIcons.globe, color: Colors.blue, size: size); // httpd
      break;
    case 2:
      icon = Icon(FontAwesomeIcons.solidFolder, color: Colors.orange, size: size); // httpd/unix-directory
      break;
    case 3:
      icon = Icon(FontAwesomeIcons.solidFile, color: Colors.grey, size: size); // application
      break;
    case 4:
      icon = Icon(FontAwesomeIcons.solidFile, color: Colors.grey, size: size); // application/vnd.oasis.opendocument.text
      break;
    case 5:
      icon = Icon(FontAwesomeIcons.solidFilePdf, color: Colors.red, size: size); // application/pdf
      break;
    case 6:
      icon = Icon(FontAwesomeIcons.solidImage, color: Colors.purple, size: size); // image
      break;
    case 7:
      icon = Icon(FontAwesomeIcons.solidImage, color: Colors.purple, size: size); // image/jpeg
      break;
    case 8:
      icon = Icon(FontAwesomeIcons.download, color: Colors.grey, size: size); // application/octet-stream
      break;
    case 9:
      icon = Icon(FontAwesomeIcons.video, color: Colors.orange, size: size); // video
      break;
    case 10:
      icon = Icon(FontAwesomeIcons.video, color: Colors.orange, size: size); // video/mp4
      break;
    case 11:
      icon = Icon(FontAwesomeIcons.solidImage, color: Colors.purple, size: size); // image/png
      break;
    case 12:
      icon = Icon(FontAwesomeIcons.download, color: Colors.grey, size: size); // application/x-ms-dos-executable
      break;
    case 14:
      icon = Icon(FontAwesomeIcons.solidFileWord, color: Colors.blue, size: size); // application/vnd.openxmlformats-officedocument.wordprocessingml.document
      break;
    case 15:
      icon = Icon(FontAwesomeIcons.code, color: Colors.blue, size: size); // text/x-php
      break;
    case 16:
      icon = Icon(FontAwesomeIcons.solidFileAlt, color: Colors.orange, size: size); // text
      break;
    case 17:
      icon = Icon(FontAwesomeIcons.solidFileExcel, color: Colors.green, size: size); // application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      break;
    case 18:
      icon = Icon(FontAwesomeIcons.solidFileAlt, color: Colors.grey[100], size: size); // text/plain
      break;
    case 19:
      icon = Icon(FontAwesomeIcons.solidFolderOpen, color: Colors.green, size: size); // inode/x-empty
      break;
    case 20:
      icon = Icon(FontAwesomeIcons.solidFolder, color: Colors.green, size: size); // inode
      break;
    case 22:
      icon = Icon(FontAwesomeIcons.solidFileWord, color: Colors.blue, size: size); // application/msword
      break;
    case 23:
      icon = Icon(FontAwesomeIcons.solidFilePowerpoint, color: Colors.green, size: size); // application/vnd.openxmlformats-officedocument.presentationml.presentation
      break;
    case 24:
      icon = Icon(FontAwesomeIcons.solidFileExcel, color: Colors.green, size: size); // application/vnd.ms-excel
      break;
    case 25:
      icon = Icon(FontAwesomeIcons.solidFileArchive, color: Colors.grey, size: size); // application/x-zip
      break;
    case 26:
      icon = Icon(FontAwesomeIcons.code, color: Colors.blue, size: size); // application/x-httpd-php
      break;
    case 27:
      icon = Icon(FontAwesomeIcons.video, color: Colors.orange, size: size); // video/3gpp
      break;
    case 28:
      icon = Icon(FontAwesomeIcons.solidImage, color: Colors.purple, size: size); // image/gif
      break;
    case 29:
      icon = Icon(FontAwesomeIcons.code, color: Colors.blue, size: size); // text/x-c++
      break;
    case 30:
      icon = Icon(FontAwesomeIcons.html5, color: Colors.blue, size: size); // text/html
      break;
    case 31:
      icon = Icon(FontAwesomeIcons.solidFileArchive, color: Colors.grey, size: size); // application/zip
      break;
    case 32:
      icon = Icon(FontAwesomeIcons.solidFilePowerpoint, color: Colors.green, size: size); // application/vnd.oasis.opendocument.presentation
      break;
    case 33:
      icon = Icon(FontAwesomeIcons.solidFile, color: Colors.orange, size: size); // application/vnd.ms-office
      break;
    default:
      icon = Icon(FontAwesomeIcons.solidQuestionCircle, color: Colors.grey, size: size); // unknown
      break;
  }
  return icon;
}
