import 'dart:io';

String uniqueDestinationPath(String targetDir, String fileName) {
  final file = File('$targetDir/$fileName');
  if (!file.existsSync()) {
    return file.path;
  }

  final dot = fileName.lastIndexOf('.');
  final name = dot == -1 ? fileName : fileName.substring(0, dot);
  final ext = dot == -1 ? '' : fileName.substring(dot);

  var index = 1;
  while (true) {
    final candidate = File('$targetDir/$name ($index)$ext');
    if (!candidate.existsSync()) {
      return candidate.path;
    }
    index++;
  }
}

final class IoFileMover {
  const IoFileMover();

  Future<String> moveFile({
    required String sourcePath,
    required String targetDirectory,
  }) async {
    final source = File(sourcePath);
    if (!source.existsSync()) {
      throw FileSystemException('Arquivo de origem não existe', sourcePath);
    }

    final targetDir = Directory(targetDirectory);
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }

    final fileName = source.uri.pathSegments.lastWhere(
      (s) => s.isNotEmpty,
      orElse: () => 'arquivo',
    );

    final destPath = uniqueDestinationPath(targetDirectory, fileName);

    try {
      await source.rename(destPath);
    } on FileSystemException {
      // Falha comum ao mover entre partições/discos diferentes (EXDEV: Cross-device link)
      await source.copy(destPath);
      await source.delete();
    }

    return destPath;
  }

  Future<void> restoreFile({
    required String currentPath,
    required String originalPath,
  }) async {
    final current = File(currentPath);
    if (!current.existsSync()) {
      return;
    }

    final originalParent = File(originalPath).parent;
    if (!originalParent.existsSync()) {
      originalParent.createSync(recursive: true);
    }

    try {
      await current.rename(originalPath);
    } on FileSystemException {
      await current.copy(originalPath);
      await current.delete();
    }
  }
}
