import 'dart:convert';

import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';

enum ConvertMode { convert, extractAudio, join }

enum VideoPreset { balanced, highQuality, web, light }

enum ConvertTarget {
  mp4,
  mkv,
  mov,
  webm,
  avi,
  gif,
  mp3,
  m4a,
  wav,
  flac,
  ogg,
}

const videoTargets = [
  ConvertTarget.mp4,
  ConvertTarget.mkv,
  ConvertTarget.mov,
  ConvertTarget.webm,
  ConvertTarget.avi,
  ConvertTarget.gif,
];

const audioTargets = [
  ConvertTarget.mp3,
  ConvertTarget.m4a,
  ConvertTarget.wav,
  ConvertTarget.flac,
  ConvertTarget.ogg,
];

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
  return switch (target) {
    ConvertTarget.mp3 ||
    ConvertTarget.m4a ||
    ConvertTarget.wav ||
    ConvertTarget.flac ||
    ConvertTarget.ogg => true,
    _ => false,
  };
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
  VideoPreset preset = VideoPreset.balanced,
  String audioBitrate = '192k',
}) {
  final video = switch (target) {
    ConvertTarget.mp3 ||
    ConvertTarget.m4a ||
    ConvertTarget.wav ||
    ConvertTarget.flac ||
    ConvertTarget.ogg => const <String>[],
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
    ConvertTarget.gif => const [
      '-vf',
      'fps=15,scale=min(640\\,iw):-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse',
    ],
    ConvertTarget.mp4 ||
    ConvertTarget.mkv ||
    ConvertTarget.mov ||
    ConvertTarget.avi => switch (preset) {
      VideoPreset.balanced => const [
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-crf',
        '20',
      ],
      VideoPreset.highQuality => const [
        '-c:v',
        'libx264',
        '-preset',
        'medium',
        '-crf',
        '18',
      ],
      VideoPreset.web => const [
        '-c:v',
        'libx264',
        '-preset',
        'slow',
        '-crf',
        '24',
        '-vf',
        'scale=min(1280\\,iw):-2',
      ],
      VideoPreset.light => const [
        '-c:v',
        'libx264',
        '-preset',
        'veryfast',
        '-crf',
        '28',
        '-vf',
        'scale=min(854\\,iw):-2',
      ],
    },
  };
  final sound = switch (target) {
    ConvertTarget.gif => const <String>['-an'],
    ConvertTarget.mp3 => ['-vn', '-c:a', 'libmp3lame', '-q:a', '2', '-b:a', audioBitrate],
    ConvertTarget.m4a => ['-vn', '-c:a', 'aac', '-b:a', audioBitrate],
    ConvertTarget.wav => const ['-vn', '-c:a', 'pcm_s16le'],
    ConvertTarget.flac => const ['-vn', '-c:a', 'flac'],
    ConvertTarget.ogg => ['-vn', '-c:a', 'libvorbis', '-b:a', audioBitrate],
    _ when audio =>
      target == ConvertTarget.webm
          ? const ['-c:a', 'libopus', '-b:a', '128k']
          : ['-c:a', 'aac', '-b:a', audioBitrate],
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

String generateConcatListContent(List<String> filePaths) {
  final buffer = StringBuffer();
  for (final path in filePaths) {
    final escaped = path.replaceAll("'", r"'\''");
    buffer.writeln("file '$escaped'");
  }
  return buffer.toString();
}

List<String> joinArguments({
  required String listFilePath,
  required String output,
  required ConvertTarget target,
  bool reencode = false,
}) {
  if (!reencode) {
    return [
      '-y',
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      listFilePath,
      '-c',
      'copy',
      if (target == ConvertTarget.mp4) ...['-movflags', '+faststart'],
      '-progress',
      'pipe:1',
      '-nostats',
      output,
    ];
  }
  final video = targetIsAudio(target)
      ? const <String>['-vn']
      : const [
          '-c:v',
          'libx264',
          '-preset',
          'veryfast',
          '-crf',
          '20',
        ];
  final sound = targetIsAudio(target)
      ? target == ConvertTarget.mp3
          ? const ['-c:a', 'libmp3lame', '-b:a', '192k']
          : const ['-c:a', 'aac', '-b:a', '192k']
      : const ['-c:a', 'aac', '-b:a', '160k'];
  return [
    '-y',
    '-f',
    'concat',
    '-safe',
    '0',
    '-i',
    listFilePath,
    ...video,
    ...sound,
    if (target == ConvertTarget.mp4) ...['-movflags', '+faststart'],
    '-progress',
    'pipe:1',
    '-nostats',
    output,
  ];
}

String? suggestJoinPath(
  List<String> inputs,
  ConvertTarget target,
  bool Function(String path) taken,
) {
  if (inputs.isEmpty) {
    return null;
  }
  final first = inputs.first;
  final normalized = first.replaceAll(r'\', '/');
  final slash = normalized.lastIndexOf('/');
  final folder = slash <= 0 ? '' : normalized.substring(0, slash);
  final ext = target.name;
  String join(String file) {
    final path = folder.isEmpty ? file : '$folder/$file';
    return first.contains(r'\') ? path.replaceAll('/', r'\') : path;
  }

  final base = join('unido.$ext');
  if (!taken(base)) {
    return base;
  }
  for (var i = 1; i <= 50; i++) {
    final candidate = join('unido-$i.$ext');
    if (!taken(candidate)) {
      return candidate;
    }
  }
  return null;
}
