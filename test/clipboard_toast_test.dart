import 'package:dv_max_easy/features/downloads/application/link_meta_probe.dart';
import 'package:dv_max_easy/features/downloads/presentation/clipboard_toast.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/settings_harness.dart';

void main() {
  group('quickThumbnailUrl', () {
    test('extracts thumbnail for standard youtube url', () {
      expect(
        quickThumbnailUrl('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      );
    });

    test('extracts thumbnail for youtu.be short url', () {
      expect(
        quickThumbnailUrl('https://youtu.be/dQw4w9WgXcQ'),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      );
    });

    test('extracts thumbnail for youtube shorts url', () {
      expect(
        quickThumbnailUrl('https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
      );
    });

    test('returns null for non-youtube urls', () {
      expect(quickThumbnailUrl('https://example.com/video.mp4'), isNull);
    });
  });

  group('ClipboardToast widget', () {
    testWidgets('renders url and fires callbacks', (tester) async {
      var downloaded = false;
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('pt', 'BR'),
          home: Scaffold(
            body: ProviderScope(
              child: ClipboardToast(
                url: 'https://example.com/awesome-video',
                onDownload: () => downloaded = true,
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tem um link copiado'), findsOneWidget);
      expect(find.text('https://example.com/awesome-video'), findsOneWidget);
      expect(find.text('Baixar'), findsOneWidget);

      await tester.tap(find.text('Baixar'));
      expect(downloaded, isTrue);

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('appears outside queue section when clipboard has a link', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        appWithSettings(readySettings(), clipboard: 'https://example.com/music'),
      );
      await tester.pumpAndSettle();

      // In queue section, the queue banner is visible.
      // Now navigate to "Concluídos"
      await tester.tap(find.text('Concluídos'));
      await tester.pumpAndSettle();

      // Now on Concluídos, the floating ClipboardToast is displayed
      expect(find.byType(ClipboardToast), findsOneWidget);
      expect(find.text('https://example.com/music'), findsOneWidget);

      // Tapping dismiss closes it
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(ClipboardToast), findsNothing);
    });
  });
}
