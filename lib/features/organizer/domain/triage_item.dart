enum FileCategory {
  video,
  image,
  audio,
  document,
  archive,
  installer,
  other,
}

FileCategory classifyExtension(String extension) {
  final ext = extension.toLowerCase().replaceFirst('.', '').trim();
  return switch (ext) {
    'mp4' ||
    'mkv' ||
    'webm' ||
    'mov' ||
    'avi' ||
    'm4v' ||
    'flv' ||
    'wmv' => FileCategory.video,

    'jpg' ||
    'jpeg' ||
    'png' ||
    'gif' ||
    'webp' ||
    'bmp' ||
    'svg' ||
    'tiff' ||
    'heic' ||
    'avif' => FileCategory.image,

    'mp3' ||
    'm4a' ||
    'wav' ||
    'flac' ||
    'aac' ||
    'ogg' ||
    'opus' => FileCategory.audio,

    'pdf' ||
    'doc' ||
    'docx' ||
    'xls' ||
    'xlsx' ||
    'ppt' ||
    'pptx' ||
    'txt' ||
    'csv' ||
    'tsv' ||
    'json' ||
    'log' ||
    'xml' ||
    'yaml' ||
    'yml' ||
    'rtf' ||
    'md' => FileCategory.document,

    'zip' || 'rar' || '7z' || 'tar' || 'gz' || 'bz2' => FileCategory.archive,

    'dmg' ||
    'pkg' ||
    'exe' ||
    'msi' ||
    'iso' ||
    'deb' ||
    'rpm' ||
    'appimage' => FileCategory.installer,

    _ => FileCategory.other,
  };
}

final class TriageItem {
  const TriageItem({
    required this.path,
    required this.name,
    required this.extension,
    required this.bytes,
    required this.modifiedAt,
    required this.category,
    this.isFavorite = false,
  });

  final String path;
  final String name;
  final String extension;
  final int bytes;
  final DateTime modifiedAt;
  final FileCategory category;
  final bool isFavorite;

  bool get isMedia =>
      category == FileCategory.video ||
      category == FileCategory.image ||
      category == FileCategory.audio;

  bool get isTextFile {
    final ext = extension.toLowerCase();
    return ext == 'txt' ||
        ext == 'md' ||
        ext == 'markdown' ||
        ext == 'csv' ||
        ext == 'tsv' ||
        ext == 'json' ||
        ext == 'log' ||
        ext == 'xml' ||
        ext == 'yaml' ||
        ext == 'yml' ||
        ext == 'ini' ||
        ext == 'conf' ||
        ext == 'sh' ||
        ext == 'py' ||
        ext == 'js' ||
        ext == 'ts' ||
        ext == 'html' ||
        ext == 'css' ||
        ext == 'dart' ||
        ext == 'sql' ||
        ext == 'env';
  }

  bool get isCsv {
    final ext = extension.toLowerCase();
    return ext == 'csv' || ext == 'tsv';
  }

  bool get isMarkdown {
    final ext = extension.toLowerCase();
    return ext == 'md' || ext == 'markdown';
  }

  bool get isHtml {
    final ext = extension.toLowerCase();
    return ext == 'html' || ext == 'htm';
  }

  bool get isRichDocument {
    final ext = extension.toLowerCase();
    return ext == 'pdf' ||
        ext == 'doc' ||
        ext == 'docx' ||
        ext == 'ppt' ||
        ext == 'pptx' ||
        ext == 'xls' ||
        ext == 'xlsx' ||
        ext == 'pages' ||
        ext == 'keynote' ||
        ext == 'numbers' ||
        ext == 'rtf';
  }

  String formatBytes() {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  TriageItem copyWith({
    String? path,
    String? name,
    String? extension,
    int? bytes,
    DateTime? modifiedAt,
    FileCategory? category,
    bool? isFavorite,
  }) {
    return TriageItem(
      path: path ?? this.path,
      name: name ?? this.name,
      extension: extension ?? this.extension,
      bytes: bytes ?? this.bytes,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageItem &&
          runtimeType == other.runtimeType &&
          path == other.path;

  @override
  int get hashCode => path.hashCode;
}
