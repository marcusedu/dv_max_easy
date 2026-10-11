import 'package:dv_max_easy/features/settings/domain/binary_path.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('symlink to a regular executable is accepted', () {
    final code = evaluateBinaryPath(
      facts: const PathFacts(
        resolved: '/opt/homebrew/Cellar/yt-dlp/2026/bin/yt-dlp',
        kind: PathKind.file,
        executable: true,
      ),
      forbiddenDirectories: const ['/Users/me/Downloads', '/tmp'],
      requireExecuteBit: true,
    );

    expect(code, isNull);
  });

  test('broken link, directory and missing execute bit are rejected', () {
    expect(
      evaluateBinaryPath(
        facts: const PathFacts(
          resolved: null,
          kind: PathKind.broken,
          executable: false,
        ),
        forbiddenDirectories: const [],
        requireExecuteBit: true,
      ),
      'broken_link',
    );
    expect(
      evaluateBinaryPath(
        facts: const PathFacts(
          resolved: '/opt/homebrew/bin',
          kind: PathKind.directory,
          executable: false,
        ),
        forbiddenDirectories: const [],
        requireExecuteBit: true,
      ),
      'not_file',
    );
    expect(
      evaluateBinaryPath(
        facts: const PathFacts(
          resolved: '/opt/homebrew/bin/yt-dlp',
          kind: PathKind.file,
          executable: false,
        ),
        forbiddenDirectories: const [],
        requireExecuteBit: true,
      ),
      'not_executable',
    );
  });

  test('Movies-evil is not inside Movies', () {
    expect(
      isInsideDirectory('/Users/me/Movies', '/Users/me/Movies-evil/yt-dlp'),
      isFalse,
    );
    expect(
      evaluateBinaryPath(
        facts: const PathFacts(
          resolved: '/Users/me/Movies-evil/yt-dlp',
          kind: PathKind.file,
          executable: true,
        ),
        forbiddenDirectories: const ['/Users/me/Movies', '/tmp'],
        requireExecuteBit: true,
      ),
      isNull,
    );
    expect(
      evaluateBinaryPath(
        facts: const PathFacts(
          resolved: '/Users/me/Downloads/yt-dlp',
          kind: PathKind.file,
          executable: true,
        ),
        forbiddenDirectories: const ['/Users/me/Downloads'],
        requireExecuteBit: true,
      ),
      'forbidden_dir',
    );
  });

  test('macOS search adds Homebrew before executing anything', () {
    final directories = binarySearchDirectories(
      pathEnv: '/usr/bin',
      operatingSystem: 'macos',
      environment: const {},
    );

    expect(directories, ['/usr/bin', '/opt/homebrew/bin', '/usr/local/bin']);
  });
}
