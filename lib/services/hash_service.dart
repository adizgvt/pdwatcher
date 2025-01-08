import 'package:hashids2/hashids2.dart';
import 'package:pdwatcher/utils/consts.dart';

class HashIdService {

  HashIdService._privateConstructor();

  static final HashIdService instance = HashIdService._privateConstructor();

  final HashIds _hashIds = HashIds(
    salt            : hashConfig['salt'],
    minHashLength   : hashConfig['minHashLength'],
    alphabet        : hashConfig['alphabet'],
  );

  String encode(String data) {
    return _hashIds.encode(data);
  }
}
