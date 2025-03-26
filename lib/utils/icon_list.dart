import 'package:fluent_ui/fluent_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

Icon getFileIcon(String path) {

  String ext = path.split('.').last;

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
    case 'msi':
      return Icon(FontAwesomeIcons.solidFileCode, color: Colors.teal);
    default:
      return Icon(FontAwesomeIcons.solidFile, color: Colors.yellow);
  }
}