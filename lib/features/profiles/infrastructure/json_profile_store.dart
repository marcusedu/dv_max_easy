import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/json_file.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/settings/domain/standard_folders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileStoreProvider = Provider<ProfileStore>((ref) {
  throw StateError('profileStoreProvider não foi configurado');
});

final class ProfileDocument {
  const ProfileDocument(this.profiles, {this.backupPath, this.seeded = false});

  final List<Profile> profiles;
  final String? backupPath;
  final bool seeded;

  Profile? byName(String name) {
    for (final profile in profiles) {
      if (profile.name == name) {
        return profile;
      }
    }
    return null;
  }

  Profile? byId(String? id) {
    if (id == null) {
      return null;
    }
    for (final profile in profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }
}

abstract interface class ProfileStore {
  Future<ProfileDocument> ensureLoaded();

  Future<void> save(List<Profile> profiles);
}

final class JsonProfileStore implements ProfileStore {
  JsonProfileStore({
    required File file,
    required Clock clock,
    required Log log,
    this.folders = const StandardFolders(music: '', films: '', downloads: ''),
  }) : _json = JsonFile(file: file, clock: clock, log: log);

  final JsonFile _json;
  final StandardFolders folders;
  Future<ProfileDocument>? _once;

  @override
  Future<ProfileDocument> ensureLoaded() {
    return _once ??= _load();
  }

  Future<ProfileDocument> _load() async {
    final read = await _json.read(schemaVersion: 1);
    if (read.missing) {
      final seeded = _placed([musicPreset(), filmsPreset()]);
      await save(seeded);
      return ProfileDocument(seeded, seeded: true);
    }
    if (read.document == null) {
      return ProfileDocument(const [], backupPath: read.backupPath);
    }
    final raw = read.document!['profiles'];
    if (raw is! List) {
      return const ProfileDocument([]);
    }
    final profiles = [
      for (final item in raw)
        if (item is Map) Profile.fromJson(Map<String, dynamic>.from(item)),
    ];
    final placed = _placed(profiles);
    if (!_sameFolders(profiles, placed)) {
      await save(placed);
    }
    return ProfileDocument(placed);
  }

  List<Profile> _placed(List<Profile> profiles) {
    final placed = assignInitialFolders(
      profiles,
      music: folders.music,
      films: folders.films,
    );
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      for (final profile in placed) {
        final folder = profile.destinationFolder;
        if (folder == null || folder.isEmpty) {
          continue;
        }
        try {
          Directory(folder).createSync(recursive: true);
        } on Object {
          // A pasta padrão pode estar indisponível. O download avisa depois.
        }
      }
    }
    return placed;
  }

  bool _sameFolders(List<Profile> before, List<Profile> after) {
    if (before.length != after.length) {
      return false;
    }
    for (var index = 0; index < before.length; index++) {
      if (before[index].destinationFolder != after[index].destinationFolder) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> save(List<Profile> profiles) {
    _once = Future.value(ProfileDocument(profiles));
    return _json.write({
      'schemaVersion': 1,
      'profiles': [for (final profile in profiles) profile.toJson()],
    });
  }
}
