import 'dart:io';

import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/json_job_store.dart';
import 'package:dv_max_easy/features/gallery/application/gallery_controller.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_document.dart';
import 'package:dv_max_easy/features/gallery/infrastructure/json_gallery_store.dart';
import 'package:dv_max_easy/features/gallery/presentation/gallery_rail.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeGalleryStore implements GalleryStore {
  GalleryDocument document = GalleryDocument.empty;

  @override
  Future<GalleryDocument> load() async => document;

  @override
  Future<void> save(GalleryDocument doc) async {
    document = doc;
  }
}

void main() {
  test('jumpToFirst and jumpToLast move to the extreme ends of the list', () async {
    final temp = await Directory.systemTemp.createTemp('gallery_nav_test');
    addTearDown(() => temp.delete(recursive: true));

    final file1 = File('${temp.path}/video1.mp4')..writeAsStringSync('1');
    final file2 = File('${temp.path}/video2.mp4')..writeAsStringSync('2');
    final file3 = File('${temp.path}/video3.mp4')..writeAsStringSync('3');

    final jobs = [
      DownloadJob(
        id: 'j1',
        url: 'https://site.com/1',
        profileName: 'Filmes',
        running: false,
        outputPath: file1.path,
        tags: const ['#perfil:filmes', '#comedia'],
      ),
      DownloadJob(
        id: 'j2',
        url: 'https://site.com/2',
        profileName: 'Música',
        running: false,
        outputPath: file2.path,
        tags: const ['#perfil:musica', '#rock'],
      ),
      DownloadJob(
        id: 'j3',
        url: 'https://site.com/3',
        profileName: 'Filmes',
        running: false,
        outputPath: file3.path,
        tags: const ['#perfil:filmes', '#drama'],
      ),
    ];

    final fakeStore = FakeGalleryStore();
    final container = ProviderContainer(
      overrides: [
        galleryStoreProvider.overrideWithValue(fakeStore),
        jobStoreProvider.overrideWithValue(const NoopJobStore()),
        initialGalleryProvider.overrideWithValue(GalleryDocument.empty),
        initialDownloadsProvider.overrideWithValue(jobs),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(galleryControllerProvider.notifier);
    expect(container.read(galleryControllerProvider).items.length, equals(3));
    expect(container.read(galleryControllerProvider).index, equals(0));

    // Jump to last
    controller.jumpToLast();
    expect(container.read(galleryControllerProvider).index, equals(2));
    expect(container.read(galleryControllerProvider).current?.jobId, equals('j3'));

    // Jump to first
    controller.jumpToFirst();
    expect(container.read(galleryControllerProvider).index, equals(0));
    expect(container.read(galleryControllerProvider).current?.jobId, equals('j1'));

    // Filter by tag
    controller.setFilterTag('#perfil:musica');
    final stateFiltered = container.read(galleryControllerProvider);
    expect(stateFiltered.items.length, equals(1));
    expect(stateFiltered.current?.jobId, equals('j2'));

    // Clear filter
    controller.setFilterTag(null);
    expect(container.read(galleryControllerProvider).items.length, equals(3));
  });

  testWidgets('GalleryRail renders double arrow buttons and triggers onFirst / onLast', (tester) async {
    var firstCalled = false;
    var lastCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GalleryRail(
            liked: false,
            canFirst: true,
            canPrevious: true,
            canNext: true,
            canLast: true,
            onFirst: () => firstCalled = true,
            onPrevious: () {},
            onNext: () {},
            onLast: () => lastCalled = true,
            onLike: () {},
            onShare: () {},
            onInfo: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.keyboard_double_arrow_up_rounded), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_double_arrow_down_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_double_arrow_up_rounded));
    await tester.pump();
    expect(firstCalled, isTrue);

    await tester.tap(find.byIcon(Icons.keyboard_double_arrow_down_rounded));
    await tester.pump();
    expect(lastCalled, isTrue);
  });
}
