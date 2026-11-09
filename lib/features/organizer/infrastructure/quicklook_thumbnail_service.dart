import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class QuicklookThumbnailService {
  const QuicklookThumbnailService();

  static final String _cacheDir = p.join(
    Directory.systemTemp.path,
    'dvmax_document_previews',
  );

  Future<String?> generateThumbnail(String filePath) async {
    if (!Platform.isMacOS || Platform.environment.containsKey('FLUTTER_TEST')) {
      return null;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final cacheDirectory = Directory(_cacheDir);
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }

    final fileName = p.basename(filePath);
    final expectedThumbPath = p.join(_cacheDir, '$fileName.png');

    // Se já estiver em cache e for mais recente que o arquivo, reaproveita
    final thumbFile = File(expectedThumbPath);
    if (await thumbFile.exists()) {
      final fileStat = await file.stat();
      final thumbStat = await thumbFile.stat();
      if (thumbStat.modified.isAfter(fileStat.modified)) {
        return expectedThumbPath;
      }
    }

    try {
      final process = await Process.run(
        'qlmanage',
        [
          '-t',
          '-s',
          '900',
          '-o',
          _cacheDir,
          filePath,
        ],
      );

      if (process.exitCode == 0 && await thumbFile.exists()) {
        return expectedThumbPath;
      }
    } catch (e) {
      debugPrint('Falha ao gerar thumbnail do QuickLook: $e');
    }

    return null;
  }
}
