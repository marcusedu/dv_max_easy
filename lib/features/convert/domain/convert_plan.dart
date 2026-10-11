import 'dart:convert';

import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';

enum ConvertTarget { mp4, mkv, webm, mp3, m4a }

const convertibleExtensions = {
  'mp4',
  'mkv',
  'webm',
  'avi',
  'mpg',
  'mpeg',
  'mov',
  'm4v',
  'mp3',
  'm4a',
  'wav',
  'flac',
  'aac',
  'ogg',
};

bool targetIsAudio(ConvertTarget target) {
  return target == ConvertTarget.mp3 || target == ConvertTarget.m4a;
}

/// Caminho absoluto de mídia, ou null quando o texto é URL ou não é arquivo.
String? localMediaPath(String raw, {required String home}) {
  var text = raw.trim();
  if (text.isEmpty || isHttpUrl(text)) {
    return null;
  }
  if (text.toLowerCase().startsWith('file://')) {
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'file') {
      return null;
    }
    text = uri.toFilePath();
  }
  if (text == '~') {
    return null;
  }
  if (text.startsWith('~/') || text.startsWith('~\\')) {
    if (home.isEmpty) {
      return null;
    }
    text = '$home${text.substring(1)}';
  }
  final absolute =
      text.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(text);
  if (!absolute || !_mediaExtension(text)) {
    return null;
  }
  return text;
}

bool looksLikePastedLocal(String before, String after, {required String home}) {
  if (localMediaPath(after, home: home) == null) {
    return false;
  }
  return after.trim().length - before.trim().length > 1;
}

bool _mediaExtension(String path) {
  final name = path.replaceAll(r'\', '/').split('/').last.toLowerCase();
  final dot = name.lastIndexOf('.');
  if (dot <= 0) {
    return false;
  }
  return convertibleExtensions.contains(name.substring(dot + 1));
}

final class ConvertFacts {
  const ConvertFacts({required this.video, required this.audio, this.duration});

  final bool video;
  final bool audio;
  final Duration? duration;
}

ConvertFacts? convertFactsFromProbe(String stdout) {
  final Object? decoded;
  try {
    decoded = jsonDecode(stdout);
  } on FormatException {
    return null;
  }
  if (decoded is! Map) {
    return null;
  }
  final streams = decoded['streams'];
  var video = false;
  var audio = false;
  if (streams is List) {
    for (final stream in streams) {
      if (stream is! Map) {
        continue;
      }
      if (stream['codec_type'] == 'video') {
        video = true;
      }
      if (stream['codec_type'] == 'audio') {
        audio = true;
      }
    }
  }
  final format = decoded['format'];
  final raw = format is Map ? format['duration'] : null;
  final seconds = raw is num ? raw.toDouble() : double.tryParse('$raw');
  Duration? duration;
  if (seconds != null && seconds > 0) {
    duration = Duration(milliseconds: (seconds * 1000).round());
  }
  if (!video && !audio && duration == null) {
    return null;
  }
  return ConvertFacts(video: video, audio: audio, duration: duration);
}

String? suggestConvertPath(
  String input,
  ConvertTarget target,
  bool Function(String path) taken,
) {
  final ext = target.name;
  final normalized = input.replaceAll(r'\', '/');
  final slash = normalized.lastIndexOf('/');
  final folder = slash <= 0 ? '' : normalized.substring(0, slash);
  final name = slash < 0 ? normalized : normalized.substring(slash + 1);
  final dot = name.lastIndexOf('.');
  final stem = dot <= 0 ? name : name.substring(0, dot);
  String join(String file) {
    final path = folder.isEmpty ? file : '$folder/$file';
    return input.contains(r'\') ? path.replaceAll('/', r'\') : path;
  }

  final direct = join('$stem.$ext');
  if (direct != input && !taken(direct)) {
    return direct;
  }
  for (var index = 0; index < 50; index++) {
    final suffix = index == 0 ? '-convert' : '-convert-${index + 1}';
    final path = join('$stem$suffix.$ext');
    if (path != input && !taken(path)) {
      return path;
    }
  }
  return null;
}

List<String> convertArguments({
  required String input,
  required String output,
  required ConvertTarget target,
  required bool audio,
}) {
  final video = switch (target) {
    ConvertTarget.mp3 || ConvertTarget.m4a => const <String>[],
    ConvertTarget.webm => const [
      '-c:v',
      'libvpx-vp9',
      '-crf',
      '32',
      '-b:v',
      '0',
      '-deadline',
      'realtime',
    ],
    ConvertTarget.mp4 || ConvertTarget.mkv => const [
      '-c:v',
      'libx264',
      '-preset',
      'veryfast',
      '-crf',
      '20',
    ],
  };
  final sound = switch (target) {
    ConvertTarget.mp3 => const ['-vn', '-c:a', 'libmp3lame', '-q:a', '2'],
    ConvertTarget.m4a => const ['-vn', '-c:a', 'aac', '-b:a', '192k'],
    _ when audio =>
      target == ConvertTarget.webm
          ? const ['-c:a', 'libopus', '-b:a', '128k']
          : const ['-c:a', 'aac', '-b:a', '160k'],
    _ => const ['-an'],
  };
  return [
    '-y',
    '-i',
    input,
    ...video,
    ...sound,
    if (target == ConvertTarget.mp4) ...['-movflags', '+faststart'],
    '-progress',
    'pipe:1',
    '-nostats',
    output,
  ];
}
