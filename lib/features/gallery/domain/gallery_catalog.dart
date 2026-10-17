import 'package:dv_max_easy/features/downloads/domain/download_job.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_document.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_rules.dart';

final class GalleryFileFacts {
  const GalleryFileFacts({required this.exists, required this.bytes});

  final bool exists;
  final int bytes;
}

final class GalleryItem {
  const GalleryItem({
    required this.jobId,
    required this.path,
    required this.url,
    required this.name,
    required this.liked,
    required this.positionMs,
    required this.bytes,
    this.durationMs,
  });

  final String jobId;
  final String path;
  final String url;
  final String name;
  final bool liked;
  final int positionMs;
  final int bytes;
  final int? durationMs;

  bool get hasOrigin => url.trim().isNotEmpty;

  String get shareText => hasOrigin ? url.trim() : path;

  GalleryItem copyWith({
    bool? liked,
    int? positionMs,
    int? durationMs,
    int? bytes,
  }) {
    return GalleryItem(
      jobId: jobId,
      path: path,
      url: url,
      name: name,
      liked: liked ?? this.liked,
      positionMs: positionMs ?? this.positionMs,
      bytes: bytes ?? this.bytes,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

List<GalleryItem> buildGallery({
  required List<DownloadJob> jobs,
  required GalleryDocument document,
  required GalleryFileFacts Function(String path) factsOf,
}) {
  final items = <GalleryItem>[];
  for (final job in jobs) {
    if (!isGalleryVideo(job)) {
      continue;
    }
    final record = document.recordOf(job.id);
    if (record.removed) {
      continue;
    }
    final path = job.outputPath!;
    final facts = factsOf(path);
    if (!facts.exists) {
      continue;
    }
    items.add(
      GalleryItem(
        jobId: job.id,
        path: path,
        url: job.url,
        name: galleryFileName(path),
        liked: record.liked,
        positionMs: record.positionMs,
        durationMs: record.durationMs,
        bytes: facts.bytes,
      ),
    );
  }
  return items;
}

bool isGalleryVideo(DownloadJob job) {
  if (job.audio || !downloadSucceeded(job)) {
    return false;
  }
  final path = job.outputPath;
  if (path == null) {
    return false;
  }
  return galleryVideoExtensions.contains(galleryExtension(path));
}

String galleryFileName(String path) {
  final normalized = path.replaceAll(r'\', '/');
  final index = normalized.lastIndexOf('/');
  if (index == -1 || index == normalized.length - 1) {
    return path;
  }
  return normalized.substring(index + 1);
}

String galleryExtension(String path) {
  final name = galleryFileName(path).toLowerCase();
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) {
    return '';
  }
  return name.substring(dot + 1);
}
