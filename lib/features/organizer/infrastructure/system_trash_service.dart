import 'dart:io';

import 'package:dv_max_easy/features/organizer/infrastructure/io_file_mover.dart';

List<String> trashArguments(String path, {required String operatingSystem}) {
  return switch (operatingSystem) {
    'macos' => [
      'osascript',
      '-e',
      'on run argv',
      '-e',
      'set filePath to POSIX file (item 1 of argv)',
      '-e',
      'tell application "Finder" to delete filePath',
      '-e',
      'end run',
      path,
    ],
    'windows' => [
      'powershell',
      '-NoProfile',
      '-Command',
      'Add-Type -AssemblyName Microsoft.VisualBasic; [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(\$env:DVMAX_FILE, "OnlyErrorDialogs", "SendToRecycleBin")',
    ],
    _ => ['gio', 'trash', path],
  };
}

Map<String, String>? trashEnvironment(
  String path, {
  required String operatingSystem,
}) {
  if (operatingSystem == 'windows') {
    return {'DVMAX_FILE': path};
  }
  return null;
}

final class SystemTrashService {
  const SystemTrashService();

  Future<void> moveToTrash(
    String path, {
    String? operatingSystem,
  }) async {
    final os = operatingSystem ?? Platform.operatingSystem;
    final args = trashArguments(path, operatingSystem: os);
    final env = trashEnvironment(path, operatingSystem: os);

    try {
      final result = await Process.run(
        args.first,
        args.sublist(1),
        environment: env,
      );

      if (result.exitCode == 0) {
        return;
      }
    } catch (_) {
      // Tenta fallback abaixo
    }

    // Fallback de segurança para macOS: move diretamente para ~/.Trash se o Finder/AppleScript falhar
    if (os == 'macos') {
      final home = Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        final trashDir = Directory('$home/.Trash');
        if (trashDir.existsSync()) {
          const mover = IoFileMover();
          await mover.moveFile(
            sourcePath: path,
            targetDirectory: trashDir.path,
          );
          return;
        }
      }
    }

    if (File(path).existsSync()) {
      throw ProcessException(
        args.first,
        args.sublist(1),
        'Não foi possível mover o arquivo para a lixeira.',
        1,
      );
    }
  }
}
