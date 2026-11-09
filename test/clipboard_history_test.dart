import 'package:dv_max_easy/features/downloads/application/clipboard_monitor.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Clipboard monitoring & smart history', () {
    test('isMediaUrl detects popular yt-dlp media sources', () {
      expect(isMediaUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'), isTrue);
      expect(isMediaUrl('https://youtu.be/dQw4w9WgXcQ?si=123'), isTrue);
      expect(isMediaUrl('https://www.tiktok.com/@user/video/7123456789'), isTrue);
      expect(isMediaUrl('https://www.instagram.com/reel/C1234567/'), isTrue);
      expect(isMediaUrl('https://x.com/user/status/123456789'), isTrue);
      expect(isMediaUrl('https://google.com'), isFalse);
      expect(isMediaUrl('not-a-url'), isFalse);
    });

    test('extractMediaId extracts YouTube, Shorts, TikTok, and Instagram IDs', () {
      expect(
        extractMediaId('https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=10s'),
        equals('dQw4w9WgXcQ'),
      );
      expect(
        extractMediaId('https://youtube.com/shorts/abc123XYZ'),
        equals('abc123XYZ'),
      );
      expect(
        extractMediaId('https://youtu.be/shortId123'),
        equals('shortId123'),
      );
      expect(
        extractMediaId('https://www.tiktok.com/@creator/video/9876543210'),
        equals('9876543210'),
      );
      expect(
        extractMediaId('https://www.instagram.com/reel/reelCode123/'),
        equals('reelCode123'),
      );
    });

    test('cleanMediaUrl strips tracking query parameters', () {
      final clean = cleanMediaUrl('https://youtu.be/abc?utm_source=share&si=tracking123&t=20');
      expect(clean, contains('t=20'));
      expect(clean, isNot(contains('utm_source')));
      expect(clean, isNot(contains('si=tracking123')));
    });

    test('isAlreadyDownloaded detects matching URL or video ID', () {
      const existingJob = DownloadJob(
        id: 'job_done',
        url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        profileName: 'Filmes',
        running: false,
        outputPath: '/path/to/video.mp4',
      );

      // Same URL with tracking parameters
      expect(
        isAlreadyDownloaded(
          url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&si=tracking',
          jobs: const [existingJob],
        ),
        isTrue,
      );

      // youtu.be shortlink with same video ID
      expect(
        isAlreadyDownloaded(
          url: 'https://youtu.be/dQw4w9WgXcQ',
          jobs: const [existingJob],
        ),
        isTrue,
      );

      // Unrelated video URL
      expect(
        isAlreadyDownloaded(
          url: 'https://www.youtube.com/watch?v=otherVideoId',
          jobs: const [existingJob],
        ),
        isFalse,
      );
    });

    test('ClipboardHistoryNotifier adds links uniquely and can clear', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(clipboardHistoryProvider.notifier);
      expect(container.read(clipboardHistoryProvider), isEmpty);

      notifier.add('https://www.youtube.com/watch?v=video1');
      expect(container.read(clipboardHistoryProvider).length, equals(1));

      // Adding same clean URL again should not duplicate
      notifier.add('https://www.youtube.com/watch?v=video1&si=abc');
      expect(container.read(clipboardHistoryProvider).length, equals(1));

      // Adding second URL
      notifier.add('https://www.youtube.com/watch?v=video2');
      expect(container.read(clipboardHistoryProvider).length, equals(2));

      // Remove single
      notifier.remove('https://www.youtube.com/watch?v=video1');
      expect(container.read(clipboardHistoryProvider).length, equals(1));

      // Clear all
      notifier.clear();
      expect(container.read(clipboardHistoryProvider), isEmpty);
    });
  });
}
