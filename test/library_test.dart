import 'package:dv_max_easy/features/downloads/domain/download_job.dart';
import 'package:dv_max_easy/features/downloads/domain/file_stamp.dart';
import 'package:dv_max_easy/features/downloads/domain/library.dart';
import 'package:dv_max_easy/features/downloads/domain/retention.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:flutter_test/flutter_test.dart';

DownloadJob _job({
  required String id,
  bool running = false,
  String url = 'https://www.youtube.com/watch?v=1',
  String profile = 'Filmes',
  String container = 'mkv',
  String? path = '/tmp/a.mkv',
  String? error,
  bool keep = false,
  DateTime? purgedAt,
}) {
  return DownloadJob(
    id: id,
    url: url,
    profileName: profile,
    running: running,
    detail: error == null && !running ? 'done' : null,
    outputPath: path,
    error: error,
    containerLabel: container,
    keepFile: keep,
    purgedAt: purgedAt,
  );
}

void main() {
  test('the queue keeps every running job and the newest rest up to 10', () {
    final jobs = [
      _job(id: 'run', running: true, path: null),
      for (var index = 0; index < 12; index++) _job(id: '$index'),
    ];
    final visible = queuePreview(jobs);
    expect(visible.first.id, 'run');
    expect(visible, hasLength(10));
    expect(visible.last.id, '8');
    expect(
      queuePreview([for (var i = 0; i < 4; i++) _job(id: '$i')]),
      hasLength(4),
    );
  });

  test('filters combine and a repeated link points at the newest success', () {
    final older = _job(id: 'old', url: 'https://x.com/a');
    final newer = _job(
      id: 'new',
      url: 'https://x.com/a',
      profile: 'Música',
      container: 'mp3',
      path: '/tmp/a.mp3',
    );
    final other = _job(id: 'other', url: 'https://vimeo.com/b');
    final jobs = [newer, older, other];
    expect(earlierSuccess(jobs, ' https://x.com/a ')?.id, 'new');
    expect(earlierSuccess(jobs, 'https://vimeo.com/missing'), isNull);
    expect(sourceHost(newer.url), 'x.com');

    const query = LibraryQuery(
      text: 'a.mp3',
      host: 'x.com',
      profile: 'Música',
      type: 'mp3',
    );
    final now = DateTime.utc(2026, 10, 11);
    bool match(DownloadJob job) => libraryMatches(
      job,
      query,
      stamp: const FileStamp(exists: true),
      deleteAt: null,
      now: now,
    );
    expect(jobs.where(match).map((job) => job.id), ['new']);

    expect(
      libraryMatches(
        other,
        const LibraryQuery(disk: DiskFilter.missing),
        stamp: const FileStamp(exists: false),
        deleteAt: null,
        now: now,
      ),
      isTrue,
    );
    expect(
      libraryMatches(
        newer.copyWith(error: 'failed'),
        const LibraryQuery(disk: DiskFilter.missing),
        stamp: const FileStamp(exists: false),
        deleteAt: null,
        now: now,
      ),
      isFalse,
    );
  });

  test('retention uses the file time and skips a kept or missing file', () {
    final modified = DateTime.utc(2026, 10, 1, 12);
    final now = DateTime.utc(2026, 10, 11, 12);
    final profile = filmsPreset().copyWith(deleteAfterDays: 2);
    final due = _job(id: 'due');
    final kept = _job(id: 'kept', keep: true);
    final fresh = _job(id: 'fresh');
    final gone = _job(id: 'gone', path: '/tmp/missing.mkv');
    FileStamp stamp(String path) {
      if (path.endsWith('missing.mkv')) {
        return const FileStamp(exists: false);
      }
      if (path.endsWith('fresh.mkv')) {
        return FileStamp(exists: true, modified: now, bytes: 3);
      }
      return FileStamp(exists: true, modified: modified, bytes: 10);
    }

    final jobs = [
      due,
      kept,
      fresh.copyWith(outputPath: '/tmp/fresh.mkv'),
      gone,
    ];
    expect(
      scheduledDelete(job: due, days: 2, modified: modified),
      modified.add(const Duration(days: 2)),
    );
    expect(
      dueJobs(
        jobs: jobs,
        profiles: [profile],
        now: now,
        stampOf: stamp,
      ).map((job) => job.id),
      ['due'],
    );
    expect(storedBytes(jobs, stamp), 23);
    expect(filesOnDisk(jobs, stamp), 3);
  });
}
