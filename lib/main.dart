import 'dart:io';

import 'package:dv_max_easy/app/dv_max_app.dart';
import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/lists/infrastructure/json_link_list_store.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/json_job_store.dart';
import 'package:dv_max_easy/features/gallery/infrastructure/json_gallery_store.dart';
import 'package:dv_max_easy/features/profiles/infrastructure/json_profile_store.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/features/settings/domain/standard_folders.dart';
import 'package:dv_max_easy/features/settings/infrastructure/json_settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  final clock = SystemClock();
  final log = MemoryLog();
  final store = JsonSettingsStore(
    file: File(p.join(support.path, 'settings.json')),
    clock: clock,
    log: log,
  );
  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
  String? userDirs;
  if (Platform.isLinux && home.isNotEmpty) {
    final file = File(p.join(home, '.config', 'user-dirs.dirs'));
    if (file.existsSync()) {
      userDirs = file.readAsStringSync();
    }
  }
  final folders = standardFolders(
    operatingSystem: Platform.operatingSystem,
    home: home,
    userDirs: userDirs,
  );
  final profiles = JsonProfileStore(
    file: File(p.join(support.path, 'profiles.json')),
    clock: clock,
    log: log,
    folders: folders,
  );
  final lists = JsonLinkListStore(
    file: File(p.join(support.path, 'link_lists.json')),
    clock: clock,
    log: log,
  );
  final jobs = JsonJobStore(
    file: File(p.join(support.path, 'jobs.json')),
    clock: clock,
    log: log,
  );
  final gallery = JsonGalleryStore(
    file: File(p.join(support.path, 'gallery.json')),
    clock: clock,
    log: log,
  );
  final restored = await jobs.load();
  final galleryDocument = await gallery.load();
  runApp(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(clock),
        logProvider.overrideWithValue(log),
        settingsStoreProvider.overrideWithValue(store),
        standardFoldersProvider.overrideWithValue(folders),
        profileStoreProvider.overrideWithValue(profiles),
        linkListStoreProvider.overrideWithValue(lists),
        jobStoreProvider.overrideWithValue(jobs),
        initialDownloadsProvider.overrideWithValue(restored),
        galleryStoreProvider.overrideWithValue(gallery),
        initialGalleryProvider.overrideWithValue(galleryDocument),
      ],
      child: const DvMaxApp(),
    ),
  );
}
