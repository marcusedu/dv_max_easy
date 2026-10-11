import 'package:dv_max_easy/features/downloads/domain/download_job.dart';
import 'package:dv_max_easy/features/downloads/domain/file_stamp.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';

int? retentionDays(DownloadJob job, List<Profile> profiles) {
  for (final profile in profiles) {
    if (profile.name == job.profileName) {
      return profile.deleteAfterDays;
    }
  }
  return null;
}

DateTime? scheduledDelete({
  required DownloadJob job,
  required int? days,
  required DateTime? modified,
}) {
  if (!downloadSucceeded(job) || job.keepFile || job.purgedAt != null) {
    return null;
  }
  if (days == null || days <= 0 || modified == null) {
    return null;
  }
  return modified.add(Duration(days: days));
}

List<DownloadJob> dueJobs({
  required List<DownloadJob> jobs,
  required List<Profile> profiles,
  required DateTime now,
  required FileStamp Function(String path) stampOf,
}) {
  final due = <DownloadJob>[];
  for (final job in jobs) {
    final path = job.outputPath;
    if (path == null || path.isEmpty) {
      continue;
    }
    final stamp = stampOf(path);
    final at = scheduledDelete(
      job: job,
      days: retentionDays(job, profiles),
      modified: stamp.modified,
    );
    if (stamp.exists && at != null && !at.isAfter(now)) {
      due.add(job);
    }
  }
  return due;
}

int storedBytes(
  List<DownloadJob> jobs,
  FileStamp Function(String path) stampOf,
) {
  var total = 0;
  for (final job in jobs) {
    final path = job.outputPath;
    if (path == null || path.isEmpty) {
      continue;
    }
    final stamp = stampOf(path);
    if (stamp.exists) {
      total += stamp.bytes;
    }
  }
  return total;
}

int filesOnDisk(
  List<DownloadJob> jobs,
  FileStamp Function(String path) stampOf,
) {
  var count = 0;
  for (final job in jobs) {
    final path = job.outputPath;
    if (path == null || path.isEmpty) {
      continue;
    }
    if (stampOf(path).exists) {
      count++;
    }
  }
  return count;
}
