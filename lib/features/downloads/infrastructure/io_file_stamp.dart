import 'dart:io';

import 'package:dv_max_easy/features/downloads/domain/file_stamp.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class FileStampReader {
  FileStamp stamp(String path);
}

final fileStampReaderProvider = Provider<FileStampReader>(
  (ref) => const IoFileStampReader(),
);

final class IoFileStampReader implements FileStampReader {
  const IoFileStampReader();

  @override
  FileStamp stamp(String path) {
    try {
      final type = FileSystemEntity.typeSync(path);
      if (type != FileSystemEntityType.file) {
        return const FileStamp(exists: false);
      }
      final stat = File(path).statSync();
      return FileStamp(exists: true, modified: stat.modified, bytes: stat.size);
    } on Object {
      return const FileStamp(exists: false);
    }
  }
}
