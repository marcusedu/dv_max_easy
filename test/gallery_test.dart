import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/domain/file_stamp.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/io_file_stamp.dart';
import 'package:dv_max_easy/features/gallery/application/gallery_controller.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_catalog.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_document.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_rules.dart';
import 'package:dv_max_easy/features/gallery/infrastructure/gallery_files.dart';
import 'package:dv_max_easy/features/gallery/infrastructure/json_gallery_store.dart';
import 'package:dv_max_easy/features/settings/domain/app_settings.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/settings_harness.dart';

DownloadJob _job({
  required String id,
  String path = '/tmp/a.mp4',
  bool audio = false,
  bool running = false,
  String? error,
}) {
  return DownloadJob(
    id: id,
    url: 'https://example.com/$id',
    profileName: 'Filmes',
    running: running,
    outputPath: path,
    error: error,
    audio: audio,
    detail: running ? 'starting' : 'done',
  );
}

void main() {
  test('catalog keeps present videos and the newest order', () {
    final jobs = [
      _job(id: 'new', path: '/films/new.webm'),
      _job(id: 'audio', path: '/music/a.mp3', audio: true),
      _job(id: 'missing', path: '/films/gone.mp4'),
      _job(id: 'running', path: '/films/now.mp4', running: true),
      _job(id: 'old', path: '/films/old.mkv'),
      _job(id: 'removed', path: '/films/removed.mov'),
    ];
    final document = GalleryDocument(
      records: {
        'removed': const GalleryRecord(jobId: 'removed', removed: true),
        'old': const GalleryRecord(
          jobId: 'old',
          liked: true,
          positionMs: 4000,
          durationMs: 90000,
          bytes: 10,
        ),
      },
    );
    final items = buildGallery(
      jobs: jobs,
      document: document,
      factsOf: (path) {
        if (path.endsWith('gone.mp4')) {
          return const GalleryFileFacts(exists: false, bytes: 0);
        }
        return GalleryFileFacts(exists: true, bytes: path.length);
      },
    );
    expect(items.map((item) => item.jobId), ['new', 'old']);
    expect(items.last.liked, isTrue);
    expect(items.last.positionMs, 4000);
  });

  test('short videos loop and long videos follow the end setting', () {
    expect(
      finishFor(durationMs: 60000, end: GalleryEnd.next),
      PlaybackFinish.loop,
    );
    expect(
      finishFor(durationMs: 60001, end: GalleryEnd.stay),
      PlaybackFinish.stop,
    );
    expect(
      finishFor(durationMs: 90000, end: GalleryEnd.repeat),
      PlaybackFinish.repeat,
    );
    expect(
      finishFor(durationMs: 90000, end: GalleryEnd.next),
      PlaybackFinish.advance,
    );
    expect(
      finishFor(durationMs: null, end: GalleryEnd.stay),
      PlaybackFinish.stop,
    );
  });

  test('scroll down moves next unless the direction is inverted', () {
    expect(scrollStep(dy: 120, inverted: false), GalleryStep.next);
    expect(scrollStep(dy: -40, inverted: false), GalleryStep.previous);
    expect(scrollStep(dy: 120, inverted: true), GalleryStep.previous);
    expect(scrollStep(dy: 0, inverted: false), GalleryStep.none);
  });

  test('a position at the edges restarts from the beginning', () {
    expect(rememberedPositionMs(positionMs: 2999, durationMs: 20000), 0);
    expect(rememberedPositionMs(positionMs: 8000, durationMs: 20000), 8000);
    expect(rememberedPositionMs(positionMs: 17000, durationMs: 20000), 0);
  });

  test('likes and resume survive a json round trip', () async {
    final directory = await Directory.systemTemp.createTemp('dv-max-gallery');
    addTearDown(() => directory.delete(recursive: true));
    final store = JsonGalleryStore(
      file: File('${directory.path}/gallery.json'),
      clock: SystemClock(),
      log: MemoryLog(),
    );
    await store.save(
      const GalleryDocument(
        lastJobId: 'old',
        records: {
          'old': GalleryRecord(
            jobId: 'old',
            liked: true,
            positionMs: 8000,
            durationMs: 20000,
            bytes: 4096,
          ),
        },
      ),
    );
    final loaded = await store.load();
    expect(loaded.lastJobId, 'old');
    expect(loaded.recordOf('old').liked, isTrue);
    expect(loaded.recordOf('old').positionMs, 8000);
    expect(loaded.recordOf('old').bytes, 4096);
  });

  test('trackpad pan uses the same direction as the mouse wheel', () {
    expect(galleryFeedDelta(scrollDy: 40, scrollDx: 0, panDy: 0, panDx: 0), 40);
    expect(
      galleryFeedDelta(scrollDy: 0, scrollDx: 0, panDy: -40, panDx: 0),
      40,
    );
    expect(
      scrollStep(
        dy: galleryFeedDelta(scrollDy: 0, scrollDx: 0, panDy: 30, panDx: 0),
        inverted: false,
      ),
      GalleryStep.previous,
    );
  });

  test('a failed reopen does not erase the stored second', () {
    expect(
      blocksResumeOverwrite(incomingMs: 0, storedMs: 8000, reached: false),
      isTrue,
    );
    expect(
      blocksResumeOverwrite(incomingMs: 12000, storedMs: 8000, reached: true),
      isFalse,
    );
    expect(
      blocksResumeOverwrite(incomingMs: 0, storedMs: 8000, reached: true),
      isFalse,
    );
  });

  test('settings without gallery keys stay on stop and natural scroll', () {
    final settings = AppSettings.fromJson(<String, dynamic>{
      'schemaVersion': 1,
    });
    expect(settings.galleryEnd, 'stay');
    expect(settings.galleryScrollInverted, isFalse);
    final again = AppSettings.fromJson(
      settings
          .copyWith(galleryEnd: 'next', galleryScrollInverted: true)
          .toJson(),
    );
    expect(again.galleryEnd, 'next');
    expect(again.galleryScrollInverted, isTrue);
  });

  test('like, resume and delete stay on the gallery record', () async {
    final store = _MemoryGalleryStore(GalleryDocument.empty);
    final deleter = _MemoryDeleter();
    final container = ProviderContainer(
      overrides: [
        initialDownloadsProvider.overrideWithValue([
          _job(id: 'a', path: '/films/a.mp4'),
          _job(id: 'b', path: '/films/b.mkv'),
        ]),
        initialGalleryProvider.overrideWithValue(GalleryDocument.empty),
        galleryStoreProvider.overrideWithValue(store),
        galleryFileDeleterProvider.overrideWithValue(deleter),
        fileStampReaderProvider.overrideWithValue(const _PresentStamps(2048)),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(galleryControllerProvider.notifier);
    expect(container.read(galleryControllerProvider).current?.jobId, 'a');

    await notifier.toggleLike();
    expect(container.read(galleryControllerProvider).current?.liked, isTrue);
    expect(store.document.recordOf('a').liked, isTrue);

    notifier.rememberPosition('a', 18000, 20000);
    await notifier.flush();
    expect(store.document.recordOf('a').positionMs, 0);

    notifier.rememberPosition('a', 8000, 20000);
    await notifier.flush();
    expect(notifier.savedPositionMs('a'), 8000);

    final subscription = container.listen(galleryControllerProvider, (_, _) {});
    subscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(galleryControllerProvider.notifier).savedPositionMs('a'),
      8000,
    );

    final error = await notifier.deleteCurrent();
    expect(error, isNull);
    expect(deleter.deleted, ['/films/a.mp4']);
    expect(container.read(galleryControllerProvider).current?.jobId, 'b');
    expect(store.document.recordOf('a').removed, isTrue);
  });

  testWidgets('the gallery stage is black and settings keep the end choice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(appWithSettings(readySettings()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Galeria'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Os vídeos concluídos aparecem aqui.'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsNothing);

    await tester.tap(find.text('Ajustes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final end = find.text('Ao terminar um vídeo longo');
    await tester.scrollUntilVisible(end, 120);
    expect(end, findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ir para o próximo'), 120);
    await tester.tap(find.text('Ir para o próximo'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Invertida'), 120);
    await tester.tap(find.text('Invertida'));
    await tester.pump();
  });

  testWidgets('a finished video shows the rail and the info dialog', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final directory = Directory.systemTemp.createTempSync('dv-gallery-ui');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/clip.mp4')..writeAsStringSync('clip');

    await tester.pumpWidget(
      appWithSettings(
        readySettings(),
        jobs: [
          DownloadJob(
            id: 'clip',
            url: 'https://example.com/clip',
            profileName: 'Filmes',
            running: false,
            outputPath: file.path,
            detail: 'done',
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Galeria'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.ios_share), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    expect(find.text('clip.mp4'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.info_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Local'), findsOneWidget);
    expect(find.text('https://example.com/clip'), findsOneWidget);
    expect(find.text(file.path), findsOneWidget);
  });

  testWidgets('the wheel and the arrow keys change the video', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final directory = Directory.systemTemp.createTempSync('dv-gallery-move');
    addTearDown(() => directory.deleteSync(recursive: true));
    final first = File('${directory.path}/first.mp4')..writeAsStringSync('a');
    final second = File('${directory.path}/second.mp4')..writeAsStringSync('b');

    await tester.pumpWidget(
      appWithSettings(
        readySettings(),
        jobs: [
          DownloadJob(
            id: '1',
            url: 'https://example.com/1',
            profileName: 'Filmes',
            running: false,
            outputPath: first.path,
            detail: 'done',
          ),
          DownloadJob(
            id: '2',
            url: 'https://example.com/2',
            profileName: 'Filmes',
            running: false,
            outputPath: second.path,
            detail: 'done',
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Galeria'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('first.mp4'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(find.text('second.mp4'), findsOneWidget);

    final center = tester.getCenter(find.byKey(const Key('gallery-stage')));
    await tester.sendEventToBinding(
      PointerScrollEvent(position: center, scrollDelta: const Offset(0, -40)),
    );
    await tester.pump();
    expect(find.text('first.mp4'), findsOneWidget);

    await tester.sendEventToBinding(PointerPanZoomStartEvent(position: center));
    await tester.sendEventToBinding(
      PointerPanZoomUpdateEvent(
        position: center,
        pan: const Offset(0, -48),
        panDelta: const Offset(0, -48),
      ),
    );
    await tester.pump();
    expect(find.text('second.mp4'), findsOneWidget);

    await tester.tap(find.text('Concluídos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Galeria'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('second.mp4'), findsOneWidget);
  });
}

final class _PresentStamps implements FileStampReader {
  const _PresentStamps(this.bytes);

  final int bytes;

  @override
  FileStamp stamp(String path) {
    return FileStamp(exists: true, bytes: bytes);
  }
}

final class _MemoryGalleryStore implements GalleryStore {
  _MemoryGalleryStore(this.document);

  GalleryDocument document;

  @override
  Future<GalleryDocument> load() async => document;

  @override
  Future<void> save(GalleryDocument next) async {
    document = next;
  }
}

final class _MemoryDeleter implements GalleryFileDeleter {
  final deleted = <String>[];

  @override
  Future<bool> delete(String path) async {
    deleted.add(path);
    return true;
  }
}
