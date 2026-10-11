import 'package:path/path.dart' as p;

enum PathKind { missing, broken, directory, file }

enum BinaryKind { ytDlp, ffmpeg }

final class PathFacts {
  const PathFacts({
    required this.resolved,
    required this.kind,
    required this.executable,
  });

  final String? resolved;
  final PathKind kind;
  final bool executable;
}

/// Recusa binário em pasta de download, temporário ou destino.
/// `Movies-evil` não conta como dentro de `Movies`.
String? evaluateBinaryPath({
  required PathFacts facts,
  required List<String> forbiddenDirectories,
  required bool requireExecuteBit,
}) {
  switch (facts.kind) {
    case PathKind.missing:
    case PathKind.directory:
      return 'not_file';
    case PathKind.broken:
      return 'broken_link';
    case PathKind.file:
      break;
  }
  if (requireExecuteBit && !facts.executable) {
    return 'not_executable';
  }
  final resolved = facts.resolved;
  if (resolved == null) {
    return 'not_file';
  }
  for (final root in forbiddenDirectories) {
    if (root.isEmpty) {
      continue;
    }
    if (isInsideDirectory(root, resolved)) {
      return 'forbidden_dir';
    }
  }
  return null;
}

bool isInsideDirectory(String parent, String child) {
  final base = _key(p.normalize(parent));
  final target = _key(p.normalize(child));
  if (base == target) {
    return true;
  }
  final prefix = base.endsWith('/') ? base : '$base/';
  return target.startsWith(prefix);
}

String _key(String value) {
  if (p.separator == r'\') {
    return value.toLowerCase().replaceAll(r'\', '/');
  }
  return value;
}

List<String> binarySearchDirectories({
  required String pathEnv,
  required String operatingSystem,
  required Map<String, String> environment,
}) {
  final fromPath = pathEnv
      .split(operatingSystem == 'windows' ? ';' : ':')
      .where((entry) => entry.isNotEmpty);
  final extra = switch (operatingSystem) {
    'macos' => ['/opt/homebrew/bin', '/usr/local/bin'],
    'linux' => ['/usr/local/bin', '/usr/bin'],
    'windows' => [
      _windowsExtra(environment, 'LOCALAPPDATA', r'Microsoft\WinGet\Links'),
      _windowsExtra(environment, 'ProgramFiles', 'yt-dlp'),
      _windowsExtra(environment, 'ProgramFiles', r'ffmpeg\bin'),
      _windowsExtra(environment, 'ChocolateyInstall', 'bin'),
    ].whereType<String>(),
    _ => const <String>[],
  };
  final seen = <String>{};
  final ordered = <String>[];
  for (final directory in [...fromPath, ...extra]) {
    final normalized = p.normalize(directory);
    if (seen.add(normalized)) {
      ordered.add(normalized);
    }
  }
  return ordered;
}

String? _windowsExtra(
  Map<String, String> environment,
  String variable,
  String child,
) {
  final root = environment[variable];
  if (root == null || root.isEmpty) {
    return null;
  }
  return p.join(root, child);
}

List<String> forbiddenBinaryDirectories({
  required String home,
  required String temp,
  required String? destination,
}) {
  return [
    p.join(home, 'Downloads'),
    p.join(home, 'downloads'),
    temp,
    if (destination != null && destination.isNotEmpty) destination,
  ];
}
