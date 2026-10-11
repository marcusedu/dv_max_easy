import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/json_file.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/downloads/domain/download_job.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class JobStore {
  Future<List<DownloadJob>> load();

  Future<void> save(List<DownloadJob> jobs);
}

final jobStoreProvider = Provider<JobStore>((ref) => const NoopJobStore());

final class NoopJobStore implements JobStore {
  const NoopJobStore();

  @override
  Future<List<DownloadJob>> load() async => const [];

  @override
  Future<void> save(List<DownloadJob> jobs) async {}
}

final class JsonJobStore implements JobStore {
  JsonJobStore({required File file, required Clock clock, required Log log})
    : _json = JsonFile(file: file, clock: clock, log: log),
      _log = log;

  final JsonFile _json;
  final Log _log;

  @override
  Future<List<DownloadJob>> load() async {
    final read = await _json.read(schemaVersion: 1);
    final parsed = jobsFromDocument(read.document);
    final restored = restoreInterrupted(parsed);
    if (parsed.any((job) => job.running)) {
      await save(restored);
    }
    return restored;
  }

  @override
  Future<void> save(List<DownloadJob> jobs) async {
    try {
      await _json.write({
        'schemaVersion': 1,
        'jobs': [for (final job in capJobs(jobs)) jobToJson(job)],
      });
    } on Object catch (error) {
      _log.error('não gravei a fila', cause: error);
    }
  }
}

List<DownloadJob> capJobs(List<DownloadJob> jobs, {int limit = 200}) {
  if (jobs.length <= limit) {
    return jobs;
  }
  final kept = <DownloadJob>[];
  var finished = 0;
  for (final job in jobs) {
    if (job.running) {
      kept.add(job);
      continue;
    }
    if (finished >= limit) {
      continue;
    }
    kept.add(job);
    finished++;
  }
  return kept;
}

List<DownloadJob> restoreInterrupted(List<DownloadJob> jobs) {
  return [
    for (final job in jobs)
      if (job.running)
        job.copyWith(
          running: false,
          error: 'interrupted',
          detail: 'interrupted',
        )
      else
        job,
  ];
}

List<DownloadJob> jobsFromDocument(Map<String, dynamic>? document) {
  final raw = document?['jobs'];
  if (raw is! List) {
    return const [];
  }
  final jobs = <DownloadJob>[];
  for (final item in raw) {
    if (item is Map) {
      final job = jobFromJson(Map<String, dynamic>.from(item));
      if (job != null) {
        jobs.add(job);
      }
    }
  }
  return jobs;
}

Map<String, dynamic> jobToJson(DownloadJob job) {
  return {
    'id': job.id,
    'url': job.url,
    'profileName': job.profileName,
    'running': job.running,
    'detail': job.detail,
    'outputPath': job.outputPath,
    'error': job.error,
    'errorDetail': job.errorDetail,
    'audio': job.audio,
    'qualityLabel': job.qualityLabel,
    'containerLabel': job.containerLabel,
    'destination': job.destination,
    'thumbnailUrl': job.thumbnailUrl,
    'fraction': job.fraction,
    if (job.keepFile) 'keepFile': true,
    if (job.purgedAt != null)
      'purgedAt': job.purgedAt!.toUtc().toIso8601String(),
  };
}

DownloadJob? jobFromJson(Map<String, dynamic> json) {
  final id = json['id'];
  final url = json['url'];
  if (id is! String || id.isEmpty || url is! String || url.isEmpty) {
    return null;
  }
  final fraction = json['fraction'];
  return DownloadJob(
    id: id,
    url: url,
    profileName: json['profileName'] is String
        ? json['profileName'] as String
        : '',
    running: json['running'] == true,
    detail: json['detail'] is String ? json['detail'] as String : null,
    outputPath: json['outputPath'] is String
        ? json['outputPath'] as String
        : null,
    error: json['error'] is String ? json['error'] as String : null,
    errorDetail: json['errorDetail'] is String
        ? json['errorDetail'] as String
        : null,
    audio: json['audio'] == true,
    qualityLabel: json['qualityLabel'] is String
        ? json['qualityLabel'] as String
        : null,
    containerLabel: json['containerLabel'] is String
        ? json['containerLabel'] as String
        : '',
    destination: json['destination'] is String
        ? json['destination'] as String
        : null,
    thumbnailUrl: json['thumbnailUrl'] is String
        ? json['thumbnailUrl'] as String
        : null,
    fraction: fraction is num ? fraction.toDouble() : null,
    keepFile: json['keepFile'] == true,
    purgedAt: json['purgedAt'] is String
        ? DateTime.tryParse(json['purgedAt'] as String)
        : null,
  );
}
