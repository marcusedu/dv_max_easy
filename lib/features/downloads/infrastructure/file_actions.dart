import 'dart:io';

import 'package:flutter/services.dart';

const fileActionChannel = MethodChannel('dvmax.files');

List<String> revealArguments(String path, {required String operatingSystem}) {
  return switch (operatingSystem) {
    'macos' => ['open', '-R', path],
    'windows' => ['explorer', '/select,$path'],
    _ => ['xdg-open', parentDirectory(path)],
  };
}

List<String> openArguments(String path, {required String operatingSystem}) {
  return switch (operatingSystem) {
    'macos' => ['open', path],
    'windows' => ['cmd', '/c', 'start', '', path],
    _ => ['xdg-open', path],
  };
}

List<String> browserArguments(String url, {required String operatingSystem}) {
  return openArguments(url, operatingSystem: operatingSystem);
}

List<String> macCopyArguments(String path) {
  return [
    'osascript',
    '-e',
    'on run argv',
    '-e',
    'set the clipboard to POSIX file (item 1 of argv)',
    '-e',
    'end run',
    path,
  ];
}

String parentDirectory(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final index = normalized.lastIndexOf('/');
  if (index <= 0) {
    return path;
  }
  return path.substring(0, index);
}

String fileTitle(String? outputPath, String url) {
  if (outputPath == null || outputPath.isEmpty) {
    return url;
  }
  final normalized = outputPath.replaceAll(r'\', '/');
  final index = normalized.lastIndexOf('/');
  if (index == -1 || index == normalized.length - 1) {
    return outputPath;
  }
  return normalized.substring(index + 1);
}

/// File URI a desktop drop target reads as public.file-url, CF_HDROP, or text/uri-list.
Uri fileDragUri(String path, {required bool windows}) {
  return Uri.file(path, windows: windows);
}

/// The drag plugin registers with the desktop embedder on first build.
bool get fileDragOutEnabled =>
    !Platform.environment.containsKey('FLUTTER_TEST');

final class FileActions {
  const FileActions({this.channel = fileActionChannel});

  final MethodChannel channel;

  Future<void> open(String path) {
    final args = openArguments(path, operatingSystem: Platform.operatingSystem);
    return Process.run(args.first, args.sublist(1));
  }

  Future<void> openUrl(String url) {
    final args = browserArguments(
      url,
      operatingSystem: Platform.operatingSystem,
    );
    return Process.run(args.first, args.sublist(1));
  }

  Future<void> reveal(String path) {
    final args = revealArguments(
      path,
      operatingSystem: Platform.operatingSystem,
    );
    return Process.run(args.first, args.sublist(1));
  }

  Future<void> copy(String path) async {
    if (Platform.isMacOS) {
      final args = macCopyArguments(path);
      final result = await Process.run(args.first, args.sublist(1));
      if (result.exitCode != 0) {
        throw ProcessException(
          args.first,
          args.sublist(1),
          '${result.stderr}',
          result.exitCode,
        );
      }
      return;
    }
    if (Platform.isWindows) {
      await Process.run(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          'Set-Clipboard -LiteralPath \$env:DVMAX_FILE',
        ],
        environment: {'DVMAX_FILE': path},
      );
      return;
    }
    final process = await Process.start('xclip', [
      '-selection',
      'clipboard',
      '-t',
      'text/uri-list',
    ]);
    process.stdin.writeln(Uri.file(path));
    await process.stdin.close();
    final code = await process.exitCode;
    if (code != 0) {
      throw ProcessException(
        'xclip',
        const [],
        'não foi possível copiar',
        code,
      );
    }
  }

  Future<void> share(String path) async {
    if (Platform.isMacOS) {
      try {
        await channel.invokeMethod<void>('share', path);
        return;
      } on MissingPluginException {
        await reveal(path);
        return;
      }
    }
    await reveal(path);
  }
}
