extension Convert on int {
  getSize(){
    if(this == 0) return '0 B';

    const int KB = 1024;
    const int MB = 1024 * KB;
    const int GB = 1024 * MB;

    double size;
    String unit;

    if (this < KB) {
      size = this.toDouble();
      unit = 'bytes';
    } else if (this < MB) {
      size = this / KB;
      unit = 'KB';
    } else if (this < GB) {
      size = this / MB;
      unit = 'MB';
    } else {
      size = this / GB;
      unit = 'GB';
    }

    return '${size.toStringAsFixed(2)} $unit';
  }
}