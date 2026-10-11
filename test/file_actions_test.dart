import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('file title is the last path piece', () {
    expect(
      fileTitle(r'/Users/me/Downloads/Biri.mkv', 'https://x.com/a'),
      'Biri.mkv',
    );
    expect(fileTitle(null, 'https://x.com/a'), 'https://x.com/a');
  });

  test(
    'file drag uri is a file url on posix and a windows path on windows',
    () {
      expect(
        fileDragUri('/Users/me/Downloads/Biri.mkv', windows: false).toString(),
        'file:///Users/me/Downloads/Biri.mkv',
      );
      expect(
        fileDragUri(
          r'C:\Users\me\Downloads\Biri.mkv',
          windows: true,
        ).toFilePath(windows: true),
        r'C:\Users\me\Downloads\Biri.mkv',
      );
    },
  );

  test('reveal and open stay off the shell', () {
    expect(revealArguments('/tmp/a.mkv', operatingSystem: 'macos'), [
      'open',
      '-R',
      '/tmp/a.mkv',
    ]);
    expect(openArguments(r'C:\a.mkv', operatingSystem: 'windows'), [
      'cmd',
      '/c',
      'start',
      '',
      r'C:\a.mkv',
    ]);
    expect(revealArguments('/tmp/a.mkv', operatingSystem: 'linux'), [
      'xdg-open',
      '/tmp',
    ]);
    expect(macCopyArguments('/tmp/a.mkv').first, 'osascript');
  });
}
