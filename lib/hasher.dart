import 'package:crypto/crypto.dart';

class Hasher {
  static String getChunkHash(chunk){
    Digest md5Hash = md5.convert(chunk);
    return md5Hash.toString();
  }
}