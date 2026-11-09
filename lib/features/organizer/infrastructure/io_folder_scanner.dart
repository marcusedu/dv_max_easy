import 'dart:io';

import 'package:dv_max_easy/features/organizer/domain/folder_report.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';

final class IoFolderScanner {
  const IoFolderScanner();

  Future<FolderReport> scanFolder(String folderPath) async {
    final dir = Directory(folderPath);
    if (!dir.existsSync()) {
      return FolderReport.fromItems(folderPath: folderPath, items: const []);
    }

    final items = <TriageItem>[];

    await for (final entity in dir.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final fileName = entity.uri.pathSegments.lastWhere(
        (s) => s.isNotEmpty,
        orElse: () => '',
      );

      // Ignora arquivos ocultos de sistema como .DS_Store, .localized, .thumbnails
      if (fileName.isEmpty || fileName.startsWith('.')) {
        continue;
      }

      final dot = fileName.lastIndexOf('.');
      final ext = dot == -1 ? '' : fileName.substring(dot + 1);

      try {
        final stat = entity.statSync();
        final item = TriageItem(
          path: entity.path,
          name: fileName,
          extension: ext,
          bytes: stat.size,
          modifiedAt: stat.modified,
          category: classifyExtension(ext),
        );
        items.add(item);
      } on FileSystemException {
        // Arquivo temporariamente bloqueado ou sem permissão de leitura
        continue;
      }
    }

    // Ordena os itens: arquivos mais recentes primeiro
    items.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));

    return FolderReport.fromItems(
      folderPath: folderPath,
      items: items,
    );
  }
}
