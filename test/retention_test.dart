import 'dart:io';

import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/profiles/infrastructure/json_profile_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/settings_harness.dart';

void main() {
  test('purge deletes only an expired file and keeps the history', () async {
    final directory = await Directory.systemTemp.createTemp('dv-purge');
    addTearDown(() => directory.delete(recursive: true));
    final expired = File('${directory.path}/old.mp3')..writeAsStringSync('old');
    final kept = File('${directory.path}/kept.mp3')..writeAsStringSync('kept');
    final fresh = File('${directory.path}/new.mp3')..writeAsStringSync('new');
    final past = DateTime.now().subtract(const Duration(days: 5));
    expired.setLastModifiedSync(past);
    kept.setLastModifiedSync(past);
    final container = ProviderContainer(
      overrides: [
        initialDownloadsProvider.overrideWithValue([
          DownloadJob(
            id: 'old',
            url: 'https://example.com/old',
            profileName: 'Temp',
            running: false,
            detail: 'done',
            outputPath: expired.path,
          ),
          DownloadJob(
            id: 'kept',
            url: 'https://example.com/kept',
            profileName: 'Temp',
            running: false,
            detail: 'done',
            outputPath: kept.path,
            keepFile: true,
          ),
          DownloadJob(
            id: 'new',
            url: 'https://example.com/new',
            profileName: 'Temp',
            running: false,
            detail: 'done',
            outputPath: fresh.path,
          ),
          const DownloadJob(
            id: 'moved',
            url: 'https://example.com/moved',
            profileName: 'Temp',
            running: false,
            detail: 'done',
            outputPath: '/tmp/dv-max-does-not-exist.mp3',
          ),
        ]),
        profileStoreProvider.overrideWithValue(
          MemoryProfileStore(
            ProfileDocument([
              musicPreset().copyWith(name: 'Temp', deleteAfterDays: 2),
            ]),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final removed = await container
        .read(downloadControllerProvider.notifier)
        .purgeExpired();

    expect(removed, 1);
    expect(expired.existsSync(), isFalse);
    expect(kept.existsSync(), isTrue);
    expect(fresh.existsSync(), isTrue);
    final jobs = container.read(downloadControllerProvider);
    expect(jobs.first.purgedAt, isNotNull);
    expect(jobs.first.outputPath, expired.path);
    expect(jobs[3].purgedAt, isNull);
  });
}
