import 'package:path/path.dart' as p;

final class StandardFolders {
  const StandardFolders({
    required this.music,
    required this.films,
    required this.downloads,
  });

  final String music;
  final String films;
  final String downloads;
}

/// Pastas conhecidas do sistema. No Linux, `userDirs` é o texto de
/// `~/.config/user-dirs.dirs`.
StandardFolders standardFolders({
  required String operatingSystem,
  required String home,
  String? userDirs,
}) {
  if (home.isEmpty) {
    return const StandardFolders(music: '', films: '', downloads: '');
  }
  final fromFile = _userDirs(userDirs, home);
  return switch (operatingSystem) {
    'macos' => StandardFolders(
      music: p.join(home, 'Music'),
      films: p.join(home, 'Movies'),
      downloads: p.join(home, 'Downloads'),
    ),
    'windows' => StandardFolders(
      music: p.join(home, 'Music'),
      films: p.join(home, 'Videos'),
      downloads: p.join(home, 'Downloads'),
    ),
    _ => StandardFolders(
      music: fromFile['XDG_MUSIC_DIR'] ?? p.join(home, 'Music'),
      films: fromFile['XDG_VIDEOS_DIR'] ?? p.join(home, 'Videos'),
      downloads: fromFile['XDG_DOWNLOAD_DIR'] ?? p.join(home, 'Downloads'),
    ),
  };
}

Map<String, String> _userDirs(String? text, String home) {
  if (text == null || text.isEmpty) {
    return const {};
  }
  final found = <String, String>{};
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    final split = line.indexOf('=');
    if (split <= 0 || line.startsWith('#')) {
      continue;
    }
    final key = line.substring(0, split).trim();
    var value = line.substring(split + 1).trim();
    if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    value = value.replaceAll('\$HOME', home);
    if (value.isNotEmpty) {
      found[key] = value;
    }
  }
  return found;
}
