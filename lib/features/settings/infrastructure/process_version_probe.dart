import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/features/settings/domain/settings_ports.dart';

/// yt-dlp responde a `--version`. O ffmpeg e o ffprobe recusam esse
/// argumento (saem com erro) e só imprimem a versão com `-version`.
final class ProcessVersionProbe implements VersionProbe {
  @override
  Future<String?> readVersion(String executable) async {
    final gnu = await _once(executable, '--version');
    if (gnu != null) {
      return gnu;
    }
    return _once(executable, '-version');
  }

  Future<String?> _once(String executable, String flag) async {
    Process? process;
    try {
      process = await Process.start(executable, [flag]);
      final finished = process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process?.kill();
          return -1;
        },
      );
      final code = await finished;
      if (code != 0) {
        return null;
      }
      final text = await process.stdout.transform(utf8.decoder).join().timeout(
        const Duration(seconds: 1),
        onTimeout: () => '',
      );
      final line = text.split('\n').first.trim();
      return line.isEmpty ? null : line;
    } on Object {
      process?.kill();
      return null;
    }
  }
}
