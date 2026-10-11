import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/downloads/domain/download_failure.dart';
import 'package:dv_max_easy/features/downloads/domain/download_job.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/json_job_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filename too long is its own reason', () {
    expect(
      classifyDownloadFailure('ERROR: [Errno 63] File name too long'),
      'filename_too_long',
    );
    expect(classifyDownloadFailure('ERROR: Video unavailable'), 'unavailable');
    expect(shortFailureDetail('ERROR: Video unavailable'), 'Video unavailable');
    expect(notableErrorLine('WARNING: something'), isNull);
  });

  test(
    'jobs survive a restart and a running one becomes interrupted',
    () async {
      final directory = await Directory.systemTemp.createTemp('dv-max-jobs');
      addTearDown(() => directory.delete(recursive: true));
      final store = JsonJobStore(
        file: File('${directory.path}/jobs.json'),
        clock: SystemClock(),
        log: MemoryLog(),
      );
      await store.save([
        const DownloadJob(
          id: 'done',
          url: 'https://example.com/a',
          profileName: 'Filmes',
          running: false,
          detail: 'done',
          outputPath: '/tmp/a.mkv',
        ),
        const DownloadJob(
          id: 'live',
          url: 'https://example.com/b',
          profileName: 'Filmes',
          running: true,
          destination: '/tmp',
        ),
      ]);

      final loaded = await store.load();
      expect(loaded.map((job) => job.id), ['done', 'live']);
      expect(loaded.last.running, isFalse);
      expect(loaded.last.error, 'interrupted');
      expect(loaded.first.outputPath, '/tmp/a.mkv');
    },
  );

  test('history keeps running jobs and the newest finished ones', () {
    final jobs = [
      for (var index = 0; index < 205; index++)
        DownloadJob(
          id: '$index',
          url: 'https://example.com/$index',
          profileName: 'Filmes',
          running: index == 204,
        ),
    ];
    final kept = capJobs(jobs, limit: 200);
    expect(kept.first.id, '0');
    expect(kept.any((job) => job.id == '204'), isTrue);
    expect(kept.where((job) => !job.running), hasLength(200));
  });
}
