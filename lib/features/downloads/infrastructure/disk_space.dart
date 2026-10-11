import 'dart:async';
import 'dart:io';

import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

abstract interface class DiskSpaceReader {
  Future<int?> freeBytes(String path);
}

final diskSpaceReaderProvider = Provider<DiskSpaceReader>(
  (ref) => const SystemDiskSpace(),
);

final diskFreeProvider = AsyncNotifierProvider<DiskFreeController, int?>(
  DiskFreeController.new,
);

final class DiskFreeController extends AsyncNotifier<int?> {
  @override
  Future<int?> build() async {
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      final timer = Timer(const Duration(seconds: 5), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
    }
    final folder = ref
        .watch(settingsControllerProvider)
        .asData
        ?.value
        .settings
        .defaultDownloadFolder;
    if (folder == null || folder.isEmpty) {
      return null;
    }
    return ref.read(diskSpaceReaderProvider).freeBytes(folder);
  }
}

final class SystemDiskSpace implements DiskSpaceReader {
  const SystemDiskSpace();

  @override
  Future<int?> freeBytes(String path) async {
    try {
      if (Platform.isWindows) {
        final letter = p.rootPrefix(path).replaceAll(RegExp(r'[^A-Za-z]'), '');
        if (letter.isEmpty) {
          return null;
        }
        final result = await Process.run(
          'powershell',
          [
            '-NoProfile',
            '-Command',
            '(Get-PSDrive -Name \$env:DVMAX_DRIVE).Free',
          ],
          environment: {'DVMAX_DRIVE': letter},
        );
        return int.tryParse('${result.stdout}'.trim());
      }
      final result = await Process.run('df', ['-kP', path]);
      return parseDfAvailableBytes('${result.stdout}');
    } on Object {
      return null;
    }
  }
}

int? parseDfAvailableBytes(String stdout) {
  final lines = [
    for (final line in stdout.split('\n'))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  if (lines.length < 2) {
    return null;
  }
  final parts = lines.last.split(RegExp(r'\s+'));
  if (parts.length < 4) {
    return null;
  }
  final blocks = int.tryParse(parts[3]);
  if (blocks == null) {
    return null;
  }
  return blocks * 1024;
}
