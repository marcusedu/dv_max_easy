import 'package:dv_max_easy/features/downloads/domain/activity.dart';
import 'package:dv_max_easy/features/downloads/domain/download_job.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/disk_space.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('global progress weighs bytes and keeps the longest eta', () {
    final activity = downloadActivity([
      _job(running: false),
      _job(downloaded: 25, total: 100, speed: 1000000, eta: 10, fraction: 0.25),
      _job(downloaded: 50, total: 100, speed: 2000000, eta: 40, fraction: 0.5),
    ]);

    expect(activity.running, 2);
    expect(activity.fraction, closeTo(0.375, 0.0001));
    expect(activity.speed, 3000000);
    expect(activity.eta, 40);
  });

  test('without sizes the bar averages the known fractions', () {
    final activity = downloadActivity([
      _job(fraction: 0.2),
      _job(fraction: 0.4),
    ]);

    expect(activity.fraction, closeTo(0.3, 0.0001));
    expect(activity.speed, isNull);
    expect(activity.eta, isNull);
  });

  test('an idle queue has no progress', () {
    final activity = downloadActivity([_job(running: false)]);
    expect(activity.running, 0);
    expect(activity.fraction, isNull);
  });

  test('sizes use megabytes until a gigabyte', () {
    expect(formatBytes(2500000), '2,5 MB');
    expect(formatBytes(1500000000), '1,5 GB');
    expect(formatBytes(0), '0,0 MB');
  });

  test('df available is the fourth field in 1024-byte blocks', () {
    const stdout = '''
Filesystem 1024-blocks Used Available Capacity Mounted on
/dev/disk1 1000000 100 500000 1% /
''';
    expect(parseDfAvailableBytes(stdout), 500000 * 1024);
    expect(parseDfAvailableBytes(''), isNull);
  });
}

DownloadJob _job({
  bool running = true,
  double? fraction,
  int? downloaded,
  int? total,
  double? speed,
  int? eta,
}) {
  return DownloadJob(
    id: 'job',
    url: 'https://example.com/v',
    profileName: 'Filmes',
    running: running,
    fraction: fraction,
    downloaded: downloaded,
    total: total,
    speed: speed,
    eta: eta,
  );
}
