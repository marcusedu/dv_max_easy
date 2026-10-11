import 'package:dv_max_easy/features/profiles/domain/profile.dart';

final _urlPattern = RegExp(r'^https?://\S+$', caseSensitive: false);

bool isHttpUrl(String raw) {
  final text = raw.trim();
  return _urlPattern.hasMatch(text);
}

/// PNG do favicon do host. O arquivo /favicon.ico costuma ser ICO, que o Flutter não desenha.
String? sourceFaviconUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      uri.host.isEmpty ||
      (scheme != 'http' && scheme != 'https')) {
    return null;
  }
  return Uri.https('www.google.com', '/s2/favicons', {
    'sz': '64',
    'domain': uri.host,
  }).toString();
}

/// O botão usa o link copiado. Se a área de transferência não tiver um, usa o campo.
String? downloadUrl({required String field, String? clipboard}) {
  final clip = clipboard?.trim() ?? '';
  if (isHttpUrl(clip)) {
    return clip;
  }
  final typed = field.trim();
  if (isHttpUrl(typed)) {
    return typed;
  }
  return null;
}

/// Colar entra de uma vez. Digitar letra por letra não dispara.
bool looksLikePastedUrl(String before, String after) {
  if (!isHttpUrl(after)) {
    return false;
  }
  return after.trim().length - before.trim().length > 1;
}

bool isPlaylistPage(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) {
    return false;
  }
  if (uri.path.contains('playlist')) {
    return true;
  }
  final list = uri.queryParameters['list'];
  final video = uri.queryParameters['v'];
  return list != null && list.isNotEmpty && (video == null || video.isEmpty);
}

List<String> downloadArguments({
  required Profile profile,
  required String destination,
  required String ffmpegPath,
  required String url,
}) {
  final args = <String>[
    '--no-warnings',
    '--newline',
    '--progress',
    '--progress-delta',
    '0.5',
    '--progress-template',
    'download:{"event":"download","status":"%(progress.status)s","downloaded":"%(progress.downloaded_bytes|)s","total":"%(progress.total_bytes|)s","total_estimate":"%(progress.total_bytes_estimate|)s","speed":"%(progress.speed|)s","eta":"%(progress.eta|)s"}',
    '--progress-template',
    'postprocess:{"event":"postprocess","status":"%(progress.status)s","postprocessor":"%(progress.postprocessor|)s"}',
    '--ffmpeg-location',
    ffmpegPath,
    '--trim-filenames',
    '120',
    '-P',
    destination,
    '-o',
    profile.filenameTemplate,
    '--no-mtime',
    '--print',
    'before_dl:thumb:%(thumbnail)s',
    '--print',
    'after_move:dest:%(filepath)s',
  ];
  if (!isPlaylistPage(url)) {
    args.add('--no-playlist');
  }
  if (profile.rateLimit != null) {
    args.addAll(['-r', profile.rateLimit!]);
  }
  if (profile.concurrentFragments != null) {
    args.addAll(['-N', '${profile.concurrentFragments}']);
  }
  if (profile.isAudio) {
    args.addAll([
      '-x',
      '--audio-format',
      profile.container.name,
      '--audio-quality',
      profile.maxBitrateKbps == null ? '0' : '${profile.maxBitrateKbps}K',
      '-f',
      _audioFormat(profile),
    ]);
  } else {
    args.addAll([
      '--merge-output-format',
      profile.container.name,
      '-f',
      _videoFormat(profile),
    ]);
    _addSubtitles(args, profile);
  }
  args.add(url.trim());
  return args;
}

String _height(Profile profile) {
  return switch (profile.preset) {
    QualityPreset.h1080 => '[height<=1080]',
    QualityPreset.h720 => '[height<=720]',
    _ => '',
  };
}

String _videoFormat(Profile profile) {
  final height = _height(profile);
  final selectors = <String>[
    for (final language in profile.preferredAudioLanguages)
      if (language.trim().isNotEmpty)
        'bv*$height+ba[language^=${language.trim()}]',
  ];
  if (profile.audioFallback == AudioFallback.any ||
      profile.preferredAudioLanguages.isEmpty) {
    selectors.add('bv*$height+ba');
    selectors.add('b$height');
  }
  // Sites like Facebook often omit height. A strict filter then matches nothing.
  if (height.isNotEmpty) {
    selectors.add('bv*+ba');
  }
  if (selectors.isEmpty || selectors.last != 'b') {
    selectors.add('b');
  }
  return selectors.join('/');
}

String _audioFormat(Profile profile) {
  final selectors = <String>[
    for (final language in profile.preferredAudioLanguages)
      if (language.trim().isNotEmpty) 'ba[language^=${language.trim()}]',
  ];
  if (profile.audioFallback == AudioFallback.any || selectors.isEmpty) {
    selectors.add('ba');
  }
  if (selectors.isEmpty || selectors.last != 'b') {
    selectors.add('b');
  }
  return selectors.join('/');
}

void _addSubtitles(List<String> args, Profile profile) {
  if (profile.subtitleMode == SubtitleMode.none) {
    return;
  }
  if (profile.subtitleLanguages.isEmpty) {
    return;
  }
  args.add(
    profile.subtitleMode == SubtitleMode.embed
        ? '--embed-subs'
        : '--write-subs',
  );
  final codes = profile.subtitleLanguages
      .map((code) => '${code.trim()}.*')
      .join(',');
  final liveChat = profile.includeAutoSubtitles ? '' : ',-live_chat';
  args.addAll(['--sub-langs', '$codes$liveChat', '--convert-subs', 'srt']);
}

final class DownloadProgress {
  const DownloadProgress({
    this.fraction,
    this.detail,
    this.outputPath,
    this.thumbnailUrl,
    this.downloaded,
    this.total,
    this.speed,
    this.eta,
  });

  final double? fraction;
  final String? detail;
  final String? outputPath;
  final String? thumbnailUrl;
  final int? downloaded;
  final int? total;
  final double? speed;
  final int? eta;
}

String formatMegabytes(num bytes) {
  return '${(bytes / 1000000).toStringAsFixed(1).replaceAll('.', ',')} MB';
}

String formatSpeed(num bytesPerSecond) {
  return '${(bytesPerSecond / 1000000).toStringAsFixed(1).replaceAll('.', ',')} MB/s';
}

String formatClock(int seconds) {
  final safe = seconds < 0 ? 0 : seconds;
  final hours = safe ~/ 3600;
  final minutes = (safe % 3600) ~/ 60;
  final remain = safe % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(hours)}:${two(minutes)}:${two(remain)}';
}

DownloadProgress? parseDownloadLine(String line) {
  final text = line.trim();
  if (text.isEmpty) {
    return null;
  }
  if (text.startsWith('dest:')) {
    final path = text.substring('dest:'.length).trim();
    if (path.isEmpty) {
      return null;
    }
    return DownloadProgress(outputPath: path, detail: path);
  }
  if (text.startsWith('thumb:')) {
    final url = text.substring('thumb:'.length).trim();
    if (!url.startsWith('http')) {
      return null;
    }
    return DownloadProgress(thumbnailUrl: url);
  }
  final brace = text.indexOf('{');
  if (brace >= 0 && text.contains('"event"')) {
    return _parseEvent(text.substring(brace));
  }
  final percent = RegExp(r'(\d+(?:\.\d+)?)%').firstMatch(text);
  if (text.startsWith('[download]') && percent != null) {
    final value = double.parse(percent.group(1)!) / 100;
    return DownloadProgress(fraction: value.clamp(0, 1), detail: text);
  }
  return null;
}

DownloadProgress? _parseEvent(String jsonText) {
  final downloaded = _jsonNumber(jsonText, 'downloaded');
  final total =
      _jsonNumber(jsonText, 'total') ?? _jsonNumber(jsonText, 'total_estimate');
  final status = _jsonString(jsonText, 'status');
  final speed = _jsonNumber(jsonText, 'speed');
  final eta = _jsonNumber(jsonText, 'eta');
  double? fraction;
  if (downloaded != null && total != null && total > 0) {
    fraction = (downloaded / total).clamp(0, 1);
  }
  final post = _jsonString(jsonText, 'postprocessor');
  final detail = post ?? status ?? _detail(speed, eta);
  final downloadedBytes = downloaded?.round();
  final totalBytes = total?.round();
  if (fraction == null &&
      detail == null &&
      downloadedBytes == null &&
      totalBytes == null) {
    return null;
  }
  return DownloadProgress(
    fraction: fraction,
    detail: detail,
    downloaded: downloadedBytes,
    total: totalBytes,
    speed: speed,
    eta: eta?.round(),
  );
}

String? _detail(double? speed, double? eta) {
  if (speed == null && eta == null) {
    return null;
  }
  final speedText = speed == null
      ? ''
      : '${(speed / 1000000).toStringAsFixed(1)} MB/s';
  final etaText = eta == null ? '' : ' ETA ${eta.round()}s';
  return '$speedText$etaText'.trim();
}

double? _jsonNumber(String jsonText, String key) {
  final match = RegExp('"$key"\\s*:\\s*"?(-?\\d+(?:\\.\\d+)?)"?')
      .firstMatch(jsonText);
  if (match == null) {
    return null;
  }
  return double.tryParse(match.group(1)!);
}

String? _jsonString(String jsonText, String key) {
  final match = RegExp('"$key"\\s*:\\s*"([^"]*)"').firstMatch(jsonText);
  final value = match?.group(1);
  if (value == null || value.isEmpty || value == 'NA') {
    return null;
  }
  return value;
}
