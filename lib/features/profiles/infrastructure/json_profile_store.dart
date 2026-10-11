import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/json_file.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
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
  }) : _json = JsonFile(file: file, clock: clock, log: log);

  final JsonFile _json;
  Future<ProfileDocument>? _once;

  @override
  Future<ProfileDocument> ensureLoaded() {
    return _once ??= _load();
  }

  Future<ProfileDocument> _load() async {
    final read = await _json.read(schemaVersion: 1);
    if (read.missing) {
      final seeded = [musicPreset(), filmsPreset()];
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
    return ProfileDocument(profiles);
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
