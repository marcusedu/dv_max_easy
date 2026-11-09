import 'dart:async';
import 'dart:io';

import 'package:dv_max_easy/features/downloads/application/clipboard_offer.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/system_clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final class DetectedLink {
  const DetectedLink({
    required this.url,
    required this.detectedAt,
    this.title,
  });

  final String url;
  final DateTime detectedAt;
  final String? title;

  String? get videoId => extractMediaId(url);
}

String? extractMediaId(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;
  final host = uri.host.toLowerCase();

  if (host.contains('youtube.com')) {
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    final segments = uri.pathSegments;
    final shortsIndex = segments.indexOf('shorts');
    if (shortsIndex >= 0 && shortsIndex + 1 < segments.length) {
      return segments[shortsIndex + 1];
    }
  } else if (host == 'youtu.be') {
    final segments = uri.pathSegments;
    if (segments.isNotEmpty && segments.first.isNotEmpty) {
      return segments.first;
    }
  } else if (host.contains('tiktok.com')) {
    final segments = uri.pathSegments;
    final videoIndex = segments.indexOf('video');
    if (videoIndex >= 0 && videoIndex + 1 < segments.length) {
      return segments[videoIndex + 1];
    }
  } else if (host.contains('instagram.com')) {
    final segments = uri.pathSegments;
    final reelIndex = segments.indexOf('reel');
    if (reelIndex >= 0 && reelIndex + 1 < segments.length) {
      return segments[reelIndex + 1];
    }
    final pIndex = segments.indexOf('p');
    if (pIndex >= 0 && pIndex + 1 < segments.length) {
      return segments[pIndex + 1];
    }
  }
  return uri.path;
}

bool isMediaUrl(String raw) {
  final url = raw.trim();
  if (!isHttpUrl(url)) return false;
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  final host = uri.host.toLowerCase();
  const mediaDomains = [
    'youtube.com',
    'youtu.be',
    'tiktok.com',
    'instagram.com',
    'twitter.com',
    'x.com',
    'vimeo.com',
    'facebook.com',
    'fb.watch',
    'twitch.tv',
    'reddit.com',
    'dailymotion.com',
  ];
  return mediaDomains.any((d) => host.contains(d));
}

bool isAlreadyDownloaded({
  required String url,
  required List<DownloadJob> jobs,
}) {
  final cleanTarget = cleanMediaUrl(url);
  final targetId = extractMediaId(url);

  for (final job in jobs) {
    if (!downloadSucceeded(job)) continue;
    if (cleanMediaUrl(job.url) == cleanTarget) return true;
    final jobId = extractMediaId(job.url);
    if (targetId != null && jobId != null && targetId == jobId) return true;
  }
  return false;
}

String cleanMediaUrl(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return raw.trim();
  // Remove tracking parameters
  final cleanQuery = Map<String, String>.from(uri.queryParameters)
    ..removeWhere((key, _) => key.startsWith('utm_') || key == 'si' || key == 'feature');
  return uri.replace(queryParameters: cleanQuery.isEmpty ? null : cleanQuery).toString();
}

final clipboardHistoryProvider =
    NotifierProvider<ClipboardHistoryNotifier, List<DetectedLink>>(
  ClipboardHistoryNotifier.new,
);

final class ClipboardHistoryNotifier extends Notifier<List<DetectedLink>> {
  @override
  List<DetectedLink> build() => const [];

  void add(String url, {String? title}) {
    final clean = cleanMediaUrl(url);
    if (state.any((item) => cleanMediaUrl(item.url) == clean)) {
      return;
    }
    state = [
      DetectedLink(
        url: url.trim(),
        detectedAt: DateTime.now(),
        title: title,
      ),
      ...state,
    ];
  }

  void remove(String url) {
    state = state.where((item) => item.url != url).toList();
  }

  void clear() {
    state = const [];
  }
}

final clipboardMonitorProvider = Provider<ClipboardMonitor>((ref) {
  final monitor = ClipboardMonitor(ref);
  ref.onDispose(monitor.dispose);
  return monitor;
});

class ClipboardMonitor {
  ClipboardMonitor(this._ref);

  final Ref _ref;
  Timer? _timer;
  String? _lastCopied;

  void start() {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (_) => check());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> check() async {
    try {
      final reader = _ref.read(clipboardReaderProvider);
      final text = await reader.readText();
      if (text == null || text.trim().isEmpty || text == _lastCopied) {
        return;
      }
      _lastCopied = text;
      final trimmed = text.trim();

      if (isMediaUrl(trimmed)) {
        // Record in history
        _ref.read(clipboardHistoryProvider.notifier).add(trimmed);

        final jobs = _ref.read(downloadControllerProvider);
        if (!isAlreadyDownloaded(url: trimmed, jobs: jobs)) {
          _ref.read(clipboardOfferProvider.notifier).offer(trimmed, enabled: true);
        }
      }
    } catch (_) {}
  }
}
