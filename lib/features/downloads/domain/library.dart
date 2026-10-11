import 'package:dv_max_easy/features/downloads/domain/download_job.dart';
import 'package:dv_max_easy/features/downloads/domain/file_stamp.dart';

const queuePreviewLimit = 10;

enum DiskFilter { any, present, missing, scheduled, purged }

final class LibraryQuery {
  const LibraryQuery({
    this.text = '',
    this.host,
    this.profile,
    this.type,
    this.disk = DiskFilter.any,
  });

  final String text;
  final String? host;
  final String? profile;
  final String? type;
  final DiskFilter disk;

  LibraryQuery copyWith({
    String? text,
    String? host,
    bool clearHost = false,
    String? profile,
    bool clearProfile = false,
    String? type,
    bool clearType = false,
    DiskFilter? disk,
  }) {
    return LibraryQuery(
      text: text ?? this.text,
      host: clearHost ? null : host ?? this.host,
      profile: clearProfile ? null : profile ?? this.profile,
      type: clearType ? null : type ?? this.type,
      disk: disk ?? this.disk,
    );
  }
}

List<DownloadJob> queuePreview(
  List<DownloadJob> jobs, {
  int limit = queuePreviewLimit,
}) {
  final running = jobs.where((job) => job.running).length;
  final room = running >= limit ? 0 : limit - running;
  var kept = 0;
  final visible = <DownloadJob>[];
  for (final job in jobs) {
    if (job.running) {
      visible.add(job);
      continue;
    }
    if (kept >= room) {
      continue;
    }
    visible.add(job);
    kept++;
  }
  return visible;
}

DownloadJob? earlierSuccess(List<DownloadJob> jobs, String url) {
  final trimmed = url.trim();
  for (final job in jobs) {
    if (job.url.trim() == trimmed && downloadSucceeded(job)) {
      return job;
    }
  }
  return null;
}

String? sourceHost(String url) {
  final host = Uri.tryParse(url.trim())?.host.toLowerCase();
  if (host == null || host.isEmpty) {
    return null;
  }
  return host.startsWith('www.') ? host.substring(4) : host;
}

String fileType(DownloadJob job) {
  final label = job.containerLabel.trim().toLowerCase();
  if (label.isNotEmpty) {
    return label;
  }
  final path = job.outputPath;
  if (path == null || path.isEmpty) {
    return '';
  }
  final name = path.split(RegExp(r'[\\/]')).last;
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) {
    return '';
  }
  return name.substring(dot + 1).toLowerCase();
}

bool libraryMatches(
  DownloadJob job,
  LibraryQuery query, {
  required FileStamp? stamp,
  required DateTime? deleteAt,
  required DateTime now,
}) {
  if (job.running) {
    return false;
  }
  final text = query.text.trim().toLowerCase();
  if (text.isNotEmpty) {
    final haystack = '${job.url}\n${job.outputPath ?? ''}\n${job.profileName}'
        .toLowerCase();
    if (!haystack.contains(text)) {
      return false;
    }
  }
  if (query.host != null && sourceHost(job.url) != query.host) {
    return false;
  }
  if (query.profile != null && job.profileName != query.profile) {
    return false;
  }
  if (query.type != null && fileType(job) != query.type) {
    return false;
  }
  final onDisk = stamp?.exists == true;
  return switch (query.disk) {
    DiskFilter.any => true,
    DiskFilter.present => onDisk,
    DiskFilter.missing =>
      downloadSucceeded(job) && !onDisk && job.purgedAt == null,
    DiskFilter.scheduled => onDisk && deleteAt != null && deleteAt.isAfter(now),
    DiskFilter.purged => job.purgedAt != null,
  };
}

List<String> distinctValues(Iterable<String?> values) {
  final unique = <String>{
    for (final value in values)
      if (value != null && value.isNotEmpty) value,
  };
  final sorted = unique.toList()..sort();
  return sorted;
}
