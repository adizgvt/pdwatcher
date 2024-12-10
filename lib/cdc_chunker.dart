import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class ContentDefinedChunker {
  final int windowSize;
  final int chunkSizeMin;
  final int chunkSizeMax;
  final int divisor;

  ContentDefinedChunker({
    this.windowSize = 48,
    this.chunkSizeMin = 2048, // 2 KB
    this.chunkSizeMax = 8192, // 8 KB
    this.divisor = 4096, // Determines chunk boundary
  });

  List<Uint8List> chunkData(Uint8List data) {
    List<Uint8List> chunks = [];
    int start = 0;
    int length = data.length;
    int chunkStart = 0;

    while (start < length) {
      int end = start + windowSize;
      if (end > length) end = length;

      Uint8List window = data.sublist(start, end);
      int hash = _rollingHash(window);

      // Check if current chunk should end
      if ((hash % divisor == 0 && (start - chunkStart) >= chunkSizeMin) ||
          (start - chunkStart) >= chunkSizeMax) {
        chunks.add(data.sublist(chunkStart, start));
        chunkStart = start;
      }

      start++;
    }

    // Add the last chunk
    if (chunkStart < length) {
      chunks.add(data.sublist(chunkStart, length));
    }

    return chunks;
  }

  int _rollingHash(Uint8List data) {
    int hash = 0;
    for (int i = 0; i < data.length; i++) {
      hash = (hash << 1) + data[i];
    }
    return hash;
  }
}
