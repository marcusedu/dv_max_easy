import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/json_file.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown schemaVersion is renamed and the next read is empty', () async {
    final directory = await Directory.systemTemp.createTemp('dv-max-json');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/settings.json');
    await file.writeAsString('{"schemaVersion": 99, "ytDlpPath": "/tmp/yt-dlp"}');
    final clock = FixedClock(DateTime.utc(2026, 10, 10));
    final json = JsonFile(file: file, clock: clock, log: MemoryLog());

    final read = await json.read(schemaVersion: 1);

    expect(read.document, isNull);
    expect(read.backupPath, endsWith('.bak-${clock.instant.millisecondsSinceEpoch}'));
    expect(await file.exists(), isFalse);
    expect(await File(read.backupPath!).exists(), isTrue);
  });

  test('atomic write replaces the previous document', () async {
    final directory = await Directory.systemTemp.createTemp('dv-max-json');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/settings.json');
    final json = JsonFile(
      file: file,
      clock: FixedClock(DateTime.utc(2026, 10, 10)),
      log: MemoryLog(),
    );

    await json.write({'schemaVersion': 1, 'uiLanguage': 'pt-BR'});
    await json.write({'schemaVersion': 1, 'uiLanguage': 'pt-BR', 'maxConcurrentDownloads': 2});

    final read = await json.read(schemaVersion: 1);
    expect(read.document?['maxConcurrentDownloads'], 2);
    expect(await File('${file.path}.tmp').exists(), isFalse);
  });
}