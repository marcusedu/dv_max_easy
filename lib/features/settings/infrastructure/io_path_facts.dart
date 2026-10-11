import 'dart:io';

import 'package:dv_max_easy/features/settings/domain/binary_path.dart';
import 'package:dv_max_easy/features/settings/domain/settings_ports.dart';
import 'package:path/path.dart' as p;

final class IoPathFacts implements PathFactsReader {
  @override
  PathFacts inspect(String path) {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) {
      return const PathFacts(
        resolved: null,
        kind: PathKind.missing,
        executable: false,
      );
    }
    var current = path;
    for (var hop = 0; hop < 16; hop++) {
      if (FileSystemEntity.typeSync(current, followLinks: false) !=
          FileSystemEntityType.link) {
        break;
      }
      final next = Link(current).targetSync();
      current = p.isAbsolute(next)
          ? next
          : p.normalize(p.join(p.dirname(current), next));
      if (FileSystemEntity.typeSync(current, followLinks: false) ==
          FileSystemEntityType.notFound) {
        return const PathFacts(
          resolved: null,
          kind: PathKind.broken,
          executable: false,
        );
      }
    }
    if (FileSystemEntity.typeSync(current, followLinks: false) ==
        FileSystemEntityType.link) {
      return const PathFacts(
        resolved: null,
        kind: PathKind.broken,
        executable: false,
      );
    }
    final resolvedType = FileSystemEntity.typeSync(current, followLinks: false);
    if (resolvedType == FileSystemEntityType.directory) {
      return PathFacts(
        resolved: p.normalize(current),
        kind: PathKind.directory,
        executable: false,
      );
    }
    if (resolvedType != FileSystemEntityType.file) {
      return const PathFacts(
        resolved: null,
        kind: PathKind.missing,
        executable: false,
      );
    }
    final mode = FileStat.statSync(current).mode;
    final executable = Platform.isWindows || (mode & 0x49) != 0;
    return PathFacts(
      resolved: p.normalize(current),
      kind: PathKind.file,
      executable: executable,
    );
  }
}
