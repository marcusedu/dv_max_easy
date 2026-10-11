import 'dart:io';

import 'package:dv_max_easy/features/settings/domain/install_plan.dart';
import 'package:path/path.dart' as p;

final class OfficialInstaller {
  const OfficialInstaller();

  Future<String?> runPackage(PackageInstall plan) async {
    final environment = Map<String, String>.from(Platform.environment);
    environment['HOMEBREW_NO_AUTO_UPDATE'] = '1';
    environment['HOMEBREW_NO_ANALYTICS'] = '1';
    try {
      for (final command in plan.commands) {
        final result = await Process.run(
          command.first,
          command.sublist(1),
          environment: environment,
        );
        if (result.exitCode != 0) {
          return 'install_failed';
        }
      }
    } on Object {
      return 'install_failed';
    }
    return null;
  }

  Future<String?> download({
    required String operatingSystem,
    required String arch,
    required String directory,
  }) async {
    final bin = Directory(directory);
    final temp = await Directory.systemTemp.createTemp('dvmax-bin');
    try {
      await bin.create(recursive: true);
      final files = officialBinaries(
        operatingSystem: operatingSystem,
        arch: arch,
      );
      final tools = <String>{};
      for (final file in files) {
        final archive = File(p.join(temp.path, file.fileName));
        final saved = await _download(Uri.parse(file.url), archive);
        if (saved != null) {
          return saved;
        }
        if (!file.archive) {
          final target = p.join(
            bin.path,
            operatingSystem == 'windows' ? 'yt-dlp.exe' : 'yt-dlp',
          );
          await archive.copy(target);
          await _markExecutable(target, operatingSystem);
        } else {
          final extracted = Directory(p.join(temp.path, 'out'));
          if (extracted.existsSync()) {
            extracted.deleteSync(recursive: true);
          }
          await extracted.create();
          final tar = await Process.run('tar', [
            '-xf',
            archive.path,
            '-C',
            extracted.path,
          ]);
          if (tar.exitCode != 0) {
            return 'install_failed';
          }
          tools.addAll(await _copyTools(extracted, bin, operatingSystem));
        }
      }
      final wanted = operatingSystem == 'windows'
          ? {'ffmpeg.exe', 'ffprobe.exe'}
          : {'ffmpeg', 'ffprobe'};
      if (!tools.containsAll(wanted)) {
        return 'install_failed';
      }
      return null;
    } on Object {
      return 'install_failed';
    } finally {
      if (temp.existsSync()) {
        temp.deleteSync(recursive: true);
      }
    }
  }

  Future<String?> _download(Uri url, File dest) async {
    final client = HttpClient();
    IOSink? sink;
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.userAgentHeader, 'DV Max');
      final response = await request.close();
      if (response.statusCode != 200) {
        return 'install_failed';
      }
      sink = dest.openWrite();
      var received = 0;
      await for (final chunk in response) {
        received += chunk.length;
        if (received > 450000000) {
          return 'install_failed';
        }
        sink.add(chunk);
      }
      await sink.close();
      sink = null;
      return null;
    } on Object {
      return 'install_failed';
    } finally {
      final open = sink;
      if (open != null) {
        await open.close();
      }
      client.close(force: true);
    }
  }

  Future<Set<String>> _copyTools(
    Directory extracted,
    Directory bin,
    String operatingSystem,
  ) async {
    final wanted = operatingSystem == 'windows'
        ? {'ffmpeg.exe', 'ffprobe.exe'}
        : {'ffmpeg', 'ffprobe'};
    final found = <String>{};
    for (final entity in extracted.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path);
      if (!wanted.contains(name)) {
        continue;
      }
      final target = p.join(bin.path, name);
      entity.copySync(target);
      await _markExecutable(target, operatingSystem);
      found.add(name);
    }
    return found;
  }

  Future<void> _markExecutable(String path, String operatingSystem) async {
    if (operatingSystem == 'windows') {
      return;
    }
    await Process.run('chmod', ['755', path]);
  }
}
