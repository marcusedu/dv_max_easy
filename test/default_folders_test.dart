import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/profiles/infrastructure/json_profile_store.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/features/settings/domain/app_settings.dart';
import 'package:dv_max_easy/features/settings/domain/standard_folders.dart';
import 'package:dv_max_easy/features/settings/domain/settings_ports.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('macOS uses Music, Movies and Downloads', () {
    final folders = standardFolders(
      operatingSystem: 'macos',
      home: '/Users/ana',
    );
    expect(folders.music, p.join('/Users/ana', 'Music'));
    expect(folders.films, p.join('/Users/ana', 'Movies'));
    expect(folders.downloads, p.join('/Users/ana', 'Downloads'));
  });

  test('Windows uses Music, Videos and Downloads', () {
    const home = r'C:\Users\ana';
    final folders = standardFolders(operatingSystem: 'windows', home: home);
    expect(folders.music, p.join(home, 'Music'));
    expect(folders.films, p.join(home, 'Videos'));
    expect(folders.downloads, p.join(home, 'Downloads'));
  });

  test('Linux reads XDG user dirs and falls back beside the home', () {
    final folders = standardFolders(
      operatingSystem: 'linux',
      home: '/home/ana',
      userDirs: '''
# comment
XDG_MUSIC_DIR="\$HOME/Música"
XDG_VIDEOS_DIR="\$HOME/Vídeos"
XDG_DOWNLOAD_DIR="\$HOME/Transferências"
''',
    );
    expect(folders.music, '/home/ana/Música');
    expect(folders.films, '/home/ana/Vídeos');
    expect(folders.downloads, '/home/ana/Transferências');

    final fallback = standardFolders(
      operatingSystem: 'linux',
      home: '/home/ana',
    );
    expect(fallback.films, p.join('/home/ana', 'Videos'));
    expect(fallback.downloads, p.join('/home/ana', 'Downloads'));
  });

  test('an empty home yields empty folders', () {
    final folders = standardFolders(operatingSystem: 'macos', home: '');
    expect(folders.music, isEmpty);
    expect(folders.films, isEmpty);
    expect(folders.downloads, isEmpty);
  });

  test('initial folders fill only Música and Filmes when empty', () {
    final placed = assignInitialFolders(
      [
        musicPreset(),
        filmsPreset(destinationFolder: '/keep/filmes'),
        filmsPreset(
          id: 'outro',
          destinationFolder: null,
        ).copyWith(name: 'Novo perfil'),
      ],
      music: '/os/Music',
      films: '/os/Movies',
    );
    expect(placed[0].destinationFolder, '/os/Music');
    expect(placed[1].destinationFolder, '/keep/filmes');
    expect(placed[2].destinationFolder, isNull);
  });

  test(
    'seeded profiles take the OS folders and tests do not create them',
    () async {
      final root = Directory.systemTemp.createTempSync('dvmax-profiles');
      addTearDown(() => root.deleteSync(recursive: true));
      final music = p.join(root.path, 'Music');
      final films = p.join(root.path, 'Videos');
      final store = JsonProfileStore(
        file: File(p.join(root.path, 'profiles.json')),
        clock: SystemClock(),
        log: MemoryLog(),
        folders: StandardFolders(music: music, films: films, downloads: ''),
      );

      final seeded = await store.ensureLoaded();
      expect(seeded.byName('Música')!.destinationFolder, music);
      expect(seeded.byName('Filmes')!.destinationFolder, films);
      expect(Directory(music).existsSync(), isFalse);
      expect(Directory(films).existsSync(), isFalse);

      final custom = p.join(root.path, 'Custom');
      await store.save([
        for (final profile in seeded.profiles)
          if (profile.name == 'Filmes')
            profile.copyWith(destinationFolder: custom)
          else
            profile,
      ]);
      final again = JsonProfileStore(
        file: File(p.join(root.path, 'profiles.json')),
        clock: SystemClock(),
        log: MemoryLog(),
        folders: StandardFolders(music: music, films: films, downloads: ''),
      );
      final reloaded = await again.ensureLoaded();
      expect(reloaded.byName('Filmes')!.destinationFolder, custom);
      expect(reloaded.byName('Música')!.destinationFolder, music);
    },
  );

  test('an empty download folder becomes the OS downloads folder', () async {
    final root = Directory.systemTemp.createTempSync('dvmax-settings');
    addTearDown(() => root.deleteSync(recursive: true));
    final downloads = p.join(root.path, 'Downloads');
    final store = MemorySettingsStore(const AppSettings());
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        profileStoreProvider.overrideWithValue(
          MemoryProfileStore(ProfileDocument([musicPreset(), filmsPreset()])),
        ),
        standardFoldersProvider.overrideWithValue(
          StandardFolders(music: '', films: '', downloads: downloads),
        ),
      ],
    );
    addTearDown(container.dispose);

    final view = await container.read(settingsControllerProvider.future);
    expect(view.settings.defaultDownloadFolder, downloads);
    expect(store.settings.defaultDownloadFolder, downloads);
    expect(Directory(downloads).existsSync(), isFalse);
  });

  test('a chosen download folder stays put', () async {
    final store = MemorySettingsStore(
      const AppSettings(defaultDownloadFolder: '/Users/me/Movies'),
    );
    final container = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(store),
        profileStoreProvider.overrideWithValue(
          MemoryProfileStore(ProfileDocument([musicPreset(), filmsPreset()])),
        ),
        standardFoldersProvider.overrideWithValue(
          const StandardFolders(
            music: '/os/Music',
            films: '/os/Movies',
            downloads: '/os/Downloads',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final view = await container.read(settingsControllerProvider.future);
    expect(view.settings.defaultDownloadFolder, '/Users/me/Movies');
  });
}

class MemoryProfileStore implements ProfileStore {
  MemoryProfileStore(this.document);

  ProfileDocument document;

  @override
  Future<ProfileDocument> ensureLoaded() async => document;

  @override
  Future<void> save(List<Profile> profiles) async {
    document = ProfileDocument(profiles);
  }
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore(this.settings);

  AppSettings settings;

  @override
  Future<SettingsLoad> load() async => SettingsLoad(settings);

  @override
  Future<void> save(AppSettings next) async {
    settings = next;
  }
}
