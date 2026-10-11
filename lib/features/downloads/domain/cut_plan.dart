import 'dart:convert';

final class Span {
  const Span(this.start, this.end);

  final Duration start;
  final Duration end;

  bool get valid => end > start;

  @override
  bool operator ==(Object other) {
    return other is Span && other.start == start && other.end == end;
  }

  @override
  int get hashCode => Object.hash(start, end);
}

Duration? parseClock(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  if (!text.contains(':')) {
    final seconds = double.tryParse(text.replaceAll(',', '.'));
    if (seconds == null || seconds < 0) {
      return null;
    }
    return Duration(milliseconds: (seconds * 1000).round());
  }
  final parts = text.split(':');
  if (parts.length < 2 || parts.length > 3) {
    return null;
  }
  final numbers = <int>[];
  for (final part in parts) {
    if (part.isEmpty || int.tryParse(part) == null) {
      return null;
    }
    numbers.add(int.parse(part));
  }
  if (numbers.any((value) => value < 0)) {
    return null;
  }
  final seconds = numbers.removeLast();
  final minutes = numbers.removeLast();
  final hours = numbers.isEmpty ? 0 : numbers.single;
  if (seconds > 59 || minutes > 59) {
    return null;
  }
  return Duration(hours: hours, minutes: minutes, seconds: seconds);
}

String formatSpan(Duration value) {
  final whole = value.inSeconds < 0 ? 0 : value.inSeconds;
  final hours = whole ~/ 3600;
  final minutes = (whole % 3600) ~/ 60;
  final seconds = whole % 60;
  String two(int number) => number.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${two(minutes)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
}

List<Span> keptAfterCuts(Duration duration, List<Span> removed) {
  if (duration <= Duration.zero) {
    return const [];
  }
  final cuts = <Span>[];
  for (final cut in removed) {
    final start = cut.start < Duration.zero ? Duration.zero : cut.start;
    final end = cut.end > duration ? duration : cut.end;
    if (end > start) {
      cuts.add(Span(start, end));
    }
  }
  cuts.sort((a, b) => a.start.compareTo(b.start));
  final merged = <Span>[];
  for (final cut in cuts) {
    if (merged.isEmpty || cut.start > merged.last.end) {
      merged.add(cut);
      continue;
    }
    if (cut.end > merged.last.end) {
      merged[merged.length - 1] = Span(merged.last.start, cut.end);
    }
  }
  final kept = <Span>[];
  var cursor = Duration.zero;
  for (final cut in merged) {
    if (cut.start > cursor) {
      kept.add(Span(cursor, cut.start));
    }
    if (cut.end > cursor) {
      cursor = cut.end;
    }
  }
  if (cursor < duration) {
    kept.add(Span(cursor, duration));
  }
  return kept;
}

List<Span> keepOnly(Duration duration, Span keep) {
  return [
    if (keep.start > Duration.zero) Span(Duration.zero, keep.start),
    if (keep.end < duration) Span(keep.end, duration),
  ];
}

String describeKept(List<Span> kept) {
  return kept
      .map((span) => '${formatSpan(span.start)}–${formatSpan(span.end)}')
      .join(' + ');
}

bool cutsChangeTheFile(Duration duration, List<Span> kept) {
  if (kept.isEmpty) {
    return false;
  }
  return kept.length != 1 ||
      kept.single.start != Duration.zero ||
      kept.single.end != duration;
}

String? suggestCutPath(String input, bool Function(String path) taken) {
  final normalized = input.replaceAll(r'\', '/');
  final slash = normalized.lastIndexOf('/');
  final folder = slash <= 0 ? '' : normalized.substring(0, slash);
  final name = slash == -1 ? normalized : normalized.substring(slash + 1);
  final dot = name.lastIndexOf('.');
  final stem = dot <= 0 ? name : name.substring(0, dot);
  final extension = dot <= 0 ? '' : name.substring(dot + 1).toLowerCase();
  final video = {'mp4', 'mkv', 'mov', 'm4v'};
  final ext = video.contains(extension) ? extension : 'mp4';
  for (var index = 1; index < 50; index++) {
    final suffix = index == 1 ? '-corte' : '-corte-$index';
    final file = '$stem$suffix.$ext';
    final path = folder.isEmpty ? file : '$folder/$file';
    if (!taken(path)) {
      return input.contains(r'\') ? path.replaceAll('/', r'\') : path;
    }
  }
  return null;
}

List<String> probeArguments(String path) {
  return [
    '-v',
    'error',
    '-print_format',
    'json',
    '-show_entries',
    'format=duration:stream=codec_type',
    path,
  ];
}

final class MediaFacts {
  const MediaFacts({required this.duration, required this.audio});

  final Duration duration;
  final bool audio;
}

MediaFacts? mediaFactsFromProbe(String stdout) {
  final Object? decoded;
  try {
    decoded = jsonDecode(stdout);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) {
    return null;
  }
  final format = decoded['format'];
  final raw = format is Map ? format['duration'] : null;
  final seconds = raw is num ? raw.toDouble() : double.tryParse('$raw');
  if (seconds == null || seconds <= 0) {
    return null;
  }
  final streams = decoded['streams'];
  var audio = false;
  if (streams is List) {
    for (final stream in streams) {
      if (stream is Map && stream['codec_type'] == 'audio') {
        audio = true;
      }
    }
  }
  return MediaFacts(
    duration: Duration(milliseconds: (seconds * 1000).round()),
    audio: audio,
  );
}

List<String>? cutArguments({
  required String input,
  required String output,
  required List<Span> kept,
  required bool audio,
}) {
  if (kept.isEmpty) {
    return null;
  }
  final filters = <String>[];
  final labels = <String>[];
  for (var index = 0; index < kept.length; index++) {
    final span = kept[index];
    final start = (span.start.inMilliseconds / 1000).toStringAsFixed(3);
    final end = (span.end.inMilliseconds / 1000).toStringAsFixed(3);
    filters.add('[0:v]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v$index]');
    if (audio) {
      filters.add(
        '[0:a]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a$index]',
      );
      labels.add('[v$index][a$index]');
    } else {
      labels.add('[v$index]');
    }
  }
  final concat = audio
      ? '${labels.join()}concat=n=${kept.length}:v=1:a=1[v][a]'
      : '${labels.join()}concat=n=${kept.length}:v=1:a=0[v]';
  return [
    '-y',
    '-i',
    input,
    '-filter_complex',
    '${filters.join(';')};$concat',
    '-map',
    '[v]',
    if (audio) ...['-map', '[a]', '-c:a', 'aac', '-b:a', '160k'],
    '-c:v',
    'libx264',
    '-preset',
    'veryfast',
    '-crf',
    '20',
    '-progress',
    'pipe:1',
    '-nostats',
    output,
  ];
}

double? progressFraction(String line, Duration total) {
  final text = line.trim();
  final marker = text.startsWith('out_time_us=')
      ? 'out_time_us='
      : text.startsWith('out_time_ms=')
      ? 'out_time_ms='
      : null;
  if (marker == null || total.inMilliseconds <= 0) {
    return null;
  }
  final micros = int.tryParse(text.substring(marker.length));
  if (micros == null) {
    return null;
  }
  final fraction = micros / (total.inMilliseconds * 1000);
  if (fraction.isNaN) {
    return null;
  }
  if (fraction < 0) {
    return 0;
  }
  if (fraction > 1) {
    return 1;
  }
  return fraction;
}

bool isVideoFile(String path) {
  final name = path.replaceAll(r'\', '/').split('/').last.toLowerCase();
  final dot = name.lastIndexOf('.');
  if (dot <= 0) {
    return false;
  }
  return const {
    'mp4',
    'mkv',
    'webm',
    'mov',
    'm4v',
    'avi',
  }.contains(name.substring(dot + 1));
}
