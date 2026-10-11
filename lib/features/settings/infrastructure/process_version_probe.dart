import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/features/settings/domain/settings_ports.dart';

final class ProcessVersionProbe implements VersionProbe {
  @override
  Future<String?> readVersion(String executable) async {
    Process? process;
    try {
      process = await Process.start(executable, const ['--version']);
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
