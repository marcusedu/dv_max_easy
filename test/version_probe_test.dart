import 'dart:io';

import 'package:dv_max_easy/features/settings/infrastructure/process_version_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ffmpeg-style -version is used when --version exits with an error', () async {
    final directory = await Directory.systemTemp.createTemp('dv-max-version');
    addTearDown(() => directory.delete(recursive: true));
    final script = File('${directory.path}/ffmpeg');
    await script.writeAsString('''
#!/bin/sh
if [ "\$1" = "--version" ]; then
  echo "Unrecognized option '--version'." >&2
  exit 8
fi
if [ "\$1" = "-version" ]; then
  echo "ffmpeg version 9.0.2"
  exit 0
fi
exit 1
''');
    await Process.run('chmod', ['+x', script.path]);

    final version = await ProcessVersionProbe().readVersion(script.path);

    expect(version, 'ffmpeg version 9.0.2');
  });

  test('yt-dlp-style --version is enough', () async {
    final directory = await Directory.systemTemp.createTemp('dv-max-version');
    addTearDown(() => directory.delete(recursive: true));
    final script = File('${directory.path}/yt-dlp');
    await script.writeAsString('''
#!/bin/sh
if [ "\$1" = "--version" ]; then
  echo "2026.08.19"
  exit 0
fi
echo "should-not-run"
exit 1
''');
    await Process.run('chmod', ['+x', script.path]);

    final version = await ProcessVersionProbe().readVersion(script.path);

    expect(version, '2026.08.19');
  });
}
