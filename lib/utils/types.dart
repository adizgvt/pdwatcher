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

  static const String create = 'create';
  static const String delete = 'delete';
  static const String modify = 'modify';
  static const String move   = 'move';
  static const String rename = 'rename';

}

enum SyncType {
  newFile,
  newFolder,
  modifiedFile,
  modifiedFolder
}