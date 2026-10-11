import 'package:dv_max_easy/features/downloads/domain/download_job.dart';

final class DownloadActivity {
  const DownloadActivity({
    required this.running,
    required this.fraction,
    required this.speed,
    required this.eta,
  });

  final int running;
  final double? fraction;
  final double? speed;
  final int? eta;
}

DownloadActivity downloadActivity(List<DownloadJob> jobs) {
  final running = [
    for (final job in jobs)
      if (job.running) job,
  ];
  return DownloadActivity(
    running: running.length,
    fraction: _fraction(running),
    speed: _speed(running),
    eta: _eta(running),
  );
}

double? _fraction(List<DownloadJob> running) {
  if (running.isEmpty) {
    return null;
  }
  var got = 0;
  var total = 0;
  for (final job in running) {
    final downloaded = job.downloaded;
    final size = job.total;
    if (downloaded != null && size != null && size > 0) {
      got += downloaded;
      total += size;
    }
  }
  if (total > 0) {
    final value = got / total;
    return value > 1 ? 1 : value;
  }
  final known = [
    for (final job in running)
      if (job.fraction != null) job.fraction!,
  ];
  if (known.isEmpty) {
    return null;
  }
  final average = known.reduce((a, b) => a + b) / known.length;
  return average > 1 ? 1 : average;
}

double? _speed(List<DownloadJob> running) {
  var speed = 0.0;
  var any = false;
  for (final job in running) {
    final value = job.speed;
    if (value != null && value > 0) {
      speed += value;
      any = true;
    }
  }
  return any ? speed : null;
}

int? _eta(List<DownloadJob> running) {
  int? longest;
  for (final job in running) {
    final eta = job.eta;
    if (eta == null || eta < 0) {
      continue;
    }
    if (longest == null || eta > longest) {
      longest = eta;
    }
  }
  return longest;
}

String formatBytes(num bytes) {
  if (bytes.abs() >= 1000000000) {
    return '${(bytes / 1000000000).toStringAsFixed(1).replaceAll('.', ',')} GB';
  }
  final megabytes = bytes / 1000000;
  return '${megabytes.toStringAsFixed(1).replaceAll('.', ',')} MB';
}
