final class PackageInstall {
  const PackageInstall({required this.tool, required this.commands});

  final String tool;
  final List<List<String>> commands;

  String get description => commands.map((command) => command.join(' ')).join('\n');
}

final class OfficialFile {
  const OfficialFile({
    required this.url,
    required this.fileName,
    required this.archive,
  });

  final String url;
  final String fileName;
  final bool archive;
}

const _release = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download';
const _ffmpeg = 'https://github.com/yt-dlp/FFmpeg-Builds/releases/latest/download';

List<PackageInstall> packageInstalls(String operatingSystem) {
  return switch (operatingSystem) {
    'macos' => const [
      PackageInstall(
        tool: 'Homebrew',
        commands: [
          ['/opt/homebrew/bin/brew', 'install', 'yt-dlp'],
          ['/opt/homebrew/bin/brew', 'install', 'ffmpeg'],
        ],
      ),
      PackageInstall(
        tool: 'Homebrew',
        commands: [
          ['/usr/local/bin/brew', 'install', 'yt-dlp'],
          ['/usr/local/bin/brew', 'install', 'ffmpeg'],
        ],
      ),
      PackageInstall(
        tool: 'Homebrew',
        commands: [
          ['brew', 'install', 'yt-dlp'],
          ['brew', 'install', 'ffmpeg'],
        ],
      ),
    ],
    'windows' => const [
      PackageInstall(
        tool: 'winget',
        commands: [
          [
            'winget',
            'install',
            '--id',
            'yt-dlp.yt-dlp',
            '-e',
            '--disable-interactivity',
            '--accept-package-agreements',
            '--accept-source-agreements',
          ],
          [
            'winget',
            'install',
            '--id',
            'Gyan.FFmpeg',
            '-e',
            '--disable-interactivity',
            '--accept-package-agreements',
            '--accept-source-agreements',
          ],
        ],
      ),
      PackageInstall(
        tool: 'Scoop',
        commands: [
          ['scoop', 'install', 'yt-dlp'],
          ['scoop', 'install', 'ffmpeg'],
        ],
      ),
    ],
    _ => const [
      PackageInstall(
        tool: 'apt',
        commands: [
          ['/usr/bin/pkexec', '/usr/bin/apt-get', 'install', '-y', 'yt-dlp', 'ffmpeg'],
        ],
      ),
      PackageInstall(
        tool: 'dnf',
        commands: [
          ['/usr/bin/pkexec', '/usr/bin/dnf', 'install', '-y', 'yt-dlp', 'ffmpeg'],
        ],
      ),
      PackageInstall(
        tool: 'pacman',
        commands: [
          [
            '/usr/bin/pkexec',
            '/usr/bin/pacman',
            '-S',
            '--noconfirm',
            'yt-dlp',
            'ffmpeg',
          ],
        ],
      ),
    ],
  };
}

PackageInstall? firstAvailableInstall(
  List<PackageInstall> plans, {
  required bool Function(String path) exists,
  required List<String> pathDirectories,
}) {
  for (final plan in plans) {
    if (_available(plan, exists: exists, pathDirectories: pathDirectories)) {
      return plan;
    }
  }
  return null;
}

bool _available(
  PackageInstall plan, {
  required bool Function(String path) exists,
  required List<String> pathDirectories,
}) {
  for (final command in plan.commands) {
    if (command.isEmpty) {
      return false;
    }
    final head = command.first;
    if (head.startsWith('/') || head.contains(r':\')) {
      if (!exists(head)) {
        return false;
      }
    } else if (!_onPath(head, exists: exists, pathDirectories: pathDirectories)) {
      return false;
    }
    for (final token in command.skip(1)) {
      if ((token.startsWith('/') || token.contains(r':\')) && !exists(token)) {
        return false;
      }
    }
  }
  return true;
}

bool _onPath(
  String name, {
  required bool Function(String path) exists,
  required List<String> pathDirectories,
}) {
  for (final directory in pathDirectories) {
    final candidate = directory.endsWith('/') || directory.endsWith(r'\')
        ? '$directory$name'
        : '$directory/$name';
    if (exists(candidate) || exists('$candidate.exe') || exists('$candidate.cmd')) {
      return true;
    }
  }
  return false;
}

List<OfficialFile> officialBinaries({
  required String operatingSystem,
  required String arch,
}) {
  final arm = arch == 'arm64' || arch == 'aarch64';
  final ytDlp = switch (operatingSystem) {
    'macos' => 'yt-dlp_macos',
    'windows' => arm ? 'yt-dlp_arm64.exe' : 'yt-dlp.exe',
    _ => arm ? 'yt-dlp_linux_aarch64' : 'yt-dlp_linux',
  };
  final ffmpeg = switch (operatingSystem) {
    'windows' => arm
        ? 'ffmpeg-master-latest-winarm64-gpl.zip'
        : 'ffmpeg-master-latest-win64-gpl.zip',
    'linux' => arm
        ? 'ffmpeg-master-latest-linuxarm64-gpl.tar.xz'
        : 'ffmpeg-master-latest-linux64-gpl.tar.xz',
    _ => 'ffmpeg.zip',
  };
  final ffmpegUrl = operatingSystem == 'macos'
      ? 'https://evermeet.cx/ffmpeg/getrelease/zip'
      : '$_ffmpeg/$ffmpeg';
  return [
    OfficialFile(url: '$_release/$ytDlp', fileName: ytDlp, archive: false),
    OfficialFile(url: ffmpegUrl, fileName: ffmpeg, archive: true),
    if (operatingSystem == 'macos')
      const OfficialFile(
        url: 'https://evermeet.cx/ffmpeg/getrelease/ffprobe/zip',
        fileName: 'ffprobe.zip',
        archive: true,
      ),
  ];
}

List<String> savedBinaryNames(String operatingSystem) {
  if (operatingSystem == 'windows') {
    return const ['yt-dlp.exe', 'ffmpeg.exe', 'ffprobe.exe'];
  }
  return const ['yt-dlp', 'ffmpeg', 'ffprobe'];
}
