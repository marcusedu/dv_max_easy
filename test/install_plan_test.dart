import 'package:dv_max_easy/features/settings/domain/install_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package plans are argv lists without a shell', () {
    final plans = [
      ...packageInstalls('macos'),
      ...packageInstalls('windows'),
      ...packageInstalls('linux'),
    ];
    expect(plans, isNotEmpty);
    for (final plan in plans) {
      expect(plan.commands, isNotEmpty);
      for (final command in plan.commands) {
        expect(command, isNotEmpty);
        for (final token in command) {
          expect(token.contains('&&'), isFalse);
          expect(token.contains('|'), isFalse);
          expect(token.contains(';'), isFalse);
          expect(token.contains(' '), isFalse);
        }
      }
    }
  });

  test('the first existing package manager wins', () {
    final localBrew = firstAvailableInstall(
      packageInstalls('macos'),
      exists: (path) => path == '/usr/local/bin/brew',
      pathDirectories: const [],
    );
    expect(localBrew!.commands.first.first, '/usr/local/bin/brew');

    final pathBrew = firstAvailableInstall(
      packageInstalls('macos'),
      exists: (path) => path == '/opt/bin/brew',
      pathDirectories: const ['/opt/bin'],
    );
    expect(pathBrew!.commands.first, ['brew', 'install', 'yt-dlp']);

    final winget = firstAvailableInstall(
      packageInstalls('windows'),
      exists: (path) =>
          path == r'C:\Tools/winget.exe' || path == r'C:\Tools/scoop.cmd',
      pathDirectories: const [r'C:\Tools'],
    );
    expect(winget!.tool, 'winget');
    expect(winget.commands.first, contains('yt-dlp.yt-dlp'));
    expect(winget.commands.last, contains('Gyan.FFmpeg'));

    final scoop = firstAvailableInstall(
      packageInstalls('windows'),
      exists: (path) => path == '/bin/scoop.cmd',
      pathDirectories: const ['/bin'],
    );
    expect(scoop!.tool, 'Scoop');

    final apt = firstAvailableInstall(
      packageInstalls('linux'),
      exists: (path) => path == '/usr/bin/pkexec' || path == '/usr/bin/apt-get',
      pathDirectories: const [],
    );
    expect(apt!.tool, 'apt');
    expect(apt.commands.single.first, '/usr/bin/pkexec');

    final dnf = firstAvailableInstall(
      packageInstalls('linux'),
      exists: (path) => path == '/usr/bin/pkexec' || path == '/usr/bin/dnf',
      pathDirectories: const [],
    );
    expect(dnf!.tool, 'dnf');

    final noPkexec = firstAvailableInstall(
      packageInstalls('linux'),
      exists: (path) => path == '/usr/bin/apt-get',
      pathDirectories: const [],
    );
    expect(noPkexec, isNull);
  });

  test('official files match the published assets', () {
    final mac = officialBinaries(operatingSystem: 'macos', arch: 'arm64');
    expect(
      mac[0].url,
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos',
    );
    expect(mac[0].archive, isFalse);
    expect(mac[1].url, 'https://evermeet.cx/ffmpeg/getrelease/zip');
    expect(mac[2].url, 'https://evermeet.cx/ffmpeg/getrelease/ffprobe/zip');

    final windows = officialBinaries(operatingSystem: 'windows', arch: 'x64');
    expect(windows[0].fileName, 'yt-dlp.exe');
    expect(windows[1].fileName, 'ffmpeg-master-latest-win64-gpl.zip');
    expect(windows[1].url, contains('yt-dlp/FFmpeg-Builds'));

    final windowsArm = officialBinaries(
      operatingSystem: 'windows',
      arch: 'arm64',
    );
    expect(windowsArm[0].fileName, 'yt-dlp_arm64.exe');
    expect(windowsArm[1].fileName, 'ffmpeg-master-latest-winarm64-gpl.zip');

    final linux = officialBinaries(operatingSystem: 'linux', arch: 'x64');
    expect(linux.map((file) => file.fileName), [
      'yt-dlp_linux',
      'ffmpeg-master-latest-linux64-gpl.tar.xz',
    ]);

    final linuxArm = officialBinaries(
      operatingSystem: 'linux',
      arch: 'aarch64',
    );
    expect(linuxArm.map((file) => file.fileName), [
      'yt-dlp_linux_aarch64',
      'ffmpeg-master-latest-linuxarm64-gpl.tar.xz',
    ]);
  });

  test('saved names keep ffprobe beside ffmpeg', () {
    expect(savedBinaryNames('windows'), [
      'yt-dlp.exe',
      'ffmpeg.exe',
      'ffprobe.exe',
    ]);
    expect(savedBinaryNames('linux'), ['yt-dlp', 'ffmpeg', 'ffprobe']);
  });
}
