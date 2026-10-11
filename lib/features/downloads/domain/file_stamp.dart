final class FileStamp {
  const FileStamp({required this.exists, this.modified, this.bytes = 0});

  final bool exists;
  final DateTime? modified;
  final int bytes;
}
