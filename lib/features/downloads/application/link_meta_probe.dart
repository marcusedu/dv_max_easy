import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class LinkMeta {
  const LinkMeta({
    required this.url,
    this.title,
    this.thumbnailUrl,
  });

  final String url;
  final String? title;
  final String? thumbnailUrl;
}

String? quickThumbnailUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) {
    return null;
  }
  final host = uri.host.toLowerCase();
  if (host.contains('youtube.com')) {
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) {
      return 'https://img.youtube.com/vi/$v/mqdefault.jpg';
    }
    final segments = uri.pathSegments;
    final shortsIndex = segments.indexOf('shorts');
    if (shortsIndex >= 0 && shortsIndex + 1 < segments.length) {
      return 'https://img.youtube.com/vi/${segments[shortsIndex + 1]}/mqdefault.jpg';
    }
  } else if (host == 'youtu.be') {
    final segments = uri.pathSegments;
    if (segments.isNotEmpty && segments.first.isNotEmpty) {
      return 'https://img.youtube.com/vi/${segments.first}/mqdefault.jpg';
    }
  }
  return null;
}

final linkMetaProvider = FutureProvider.family<LinkMeta, String>((ref, url) async {
  final quickThumb = quickThumbnailUrl(url);
  final settings = ref.watch(settingsControllerProvider).asData?.value;
  final ytDlp = settings?.settings.ytDlpPath;
  if (ytDlp == null || ytDlp.isEmpty || !File(ytDlp).existsSync()) {
    return LinkMeta(url: url, thumbnailUrl: quickThumb);
  }
  try {
    final result = await Process.run(
      ytDlp,
      [
        '--no-warnings',
        '--no-playlist',
        '--print',
        '%(title)s',
        '--print',
        '%(thumbnail)s',
        url,
      ],
    ).timeout(const Duration(seconds: 4));

    final lines = const LineSplitter()
        .convert('${result.stdout}')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String? title;
    String? thumb = quickThumb;
    if (lines.isNotEmpty) {
      title = lines[0];
    }
    if (lines.length > 1 && isHttpUrl(lines[1])) {
      thumb = lines[1];
    }
    return LinkMeta(url: url, title: title, thumbnailUrl: thumb);
  } catch (_) {
    return LinkMeta(url: url, thumbnailUrl: quickThumb);
  }
});
