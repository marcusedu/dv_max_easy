import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';

final class FolderReport {
  const FolderReport({
    required this.folderPath,
    required this.totalBytes,
    required this.items,
    required this.countByCategory,
    required this.bytesByCategory,
  });

  final String folderPath;
  final int totalBytes;
  final List<TriageItem> items;
  final Map<FileCategory, int> countByCategory;
  final Map<FileCategory, int> bytesByCategory;

  int get totalFiles => items.length;

  List<TriageItem> get mediaItems => items.where((i) => i.isMedia).toList();

  List<TriageItem> get installerItems =>
      items.where((i) => i.category == FileCategory.installer).toList();

  List<TriageItem> get archiveItems =>
      items.where((i) => i.category == FileCategory.archive).toList();

  String formatTotalBytes() {
    if (totalBytes < 1024) return '$totalBytes B';
    if (totalBytes < 1024 * 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (totalBytes < 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  factory FolderReport.fromItems({
    required String folderPath,
    required List<TriageItem> items,
  }) {
    var totalBytes = 0;
    final counts = <FileCategory, int>{
      for (final cat in FileCategory.values) cat: 0,
    };
    final bytes = <FileCategory, int>{
      for (final cat in FileCategory.values) cat: 0,
    };

    for (final item in items) {
      totalBytes += item.bytes;
      counts[item.category] = (counts[item.category] ?? 0) + 1;
      bytes[item.category] = (bytes[item.category] ?? 0) + item.bytes;
    }

    return FolderReport(
      folderPath: folderPath,
      totalBytes: totalBytes,
      items: items,
      countByCategory: counts,
      bytesByCategory: bytes,
    );
  }
}
