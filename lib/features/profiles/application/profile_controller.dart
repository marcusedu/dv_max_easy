import 'dart:io';

import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/profiles/domain/profile_rules.dart';
import 'package:dv_max_easy/features/profiles/infrastructure/json_profile_store.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfileView>(
      ProfileController.new,
    );

final class ProfileView {
  const ProfileView({
    required this.profiles,
    required this.selectedId,
    this.errorCode,
    this.backupPath,
  });

  final List<Profile> profiles;
  final String? selectedId;
  final String? errorCode;
  final String? backupPath;

  Profile? get selected {
    for (final profile in profiles) {
      if (profile.id == selectedId) {
        return profile;
      }
    }
    return profiles.isEmpty ? null : profiles.first;
  }

  bool get canRestoreMusic =>
      profiles.every((profile) => profile.name != 'Música');

  bool get canRestoreFilms =>
      profiles.every((profile) => profile.name != 'Filmes');
}

final class ProfileController extends AsyncNotifier<ProfileView> {
  @override
  Future<ProfileView> build() async {
    final document = await ref.read(profileStoreProvider).ensureLoaded();
    final settings = await ref.watch(settingsControllerProvider.future);
    return ProfileView(
      profiles: document.profiles,
      selectedId: settings.settings.selectedProfileId,
      backupPath: document.backupPath,
    );
  }

  Future<void> select(String id) async {
    await ref.read(settingsControllerProvider.notifier).selectProfile(id);
    state = AsyncData(_current.copyWith(selectedId: id, clearError: true));
  }

  Future<void> save(Profile profile) async {
    final errors = validateProfile(profile);
    if (errors.isNotEmpty) {
      state = AsyncData(_current.copyWith(errorCode: errors.first));
      return;
    }
    final next = normalized(profile);
    final profiles = [
      for (final current in _current.profiles)
        if (current.id == next.id) next else current,
    ];
    if (profiles.every((item) => item.id != next.id)) {
      profiles.add(next);
    }
    await ref.read(profileStoreProvider).save(profiles);
    state = AsyncData(_current.copyWith(profiles: profiles, clearError: true));
  }

  Future<void> create() async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final created = filmsPreset(id: id).copyWith(name: 'Novo perfil');
    final profiles = [..._current.profiles, created];
    await ref.read(profileStoreProvider).save(profiles);
    await select(id);
    state = AsyncData(
      _current.copyWith(profiles: profiles, selectedId: id, clearError: true),
    );
  }

  Future<void> delete(String id) async {
    final profiles = [
      for (final profile in _current.profiles)
        if (profile.id != id) profile,
    ];
    await ref.read(profileStoreProvider).save(profiles);
    final selected = preferredProfileId(profiles, _current.selectedId);
    await ref.read(settingsControllerProvider.notifier).selectProfile(selected);
    state = AsyncData(
      _current.copyWith(
        profiles: profiles,
        selectedId: selected,
        clearError: true,
      ),
    );
  }

  Future<void> restoreMusic() {
    final music = ref.read(standardFoldersProvider).music;
    return _restore(
      musicPreset(destinationFolder: music.isEmpty ? null : music),
    );
  }

  Future<void> restoreFilms() {
    final films = ref.read(standardFoldersProvider).films;
    return _restore(
      filmsPreset(destinationFolder: films.isEmpty ? null : films),
    );
  }

  Future<void> _restore(Profile preset) async {
    if (_current.profiles.any((profile) => profile.name == preset.name)) {
      return;
    }
    final folder = preset.destinationFolder;
    if (folder != null &&
        folder.isNotEmpty &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      try {
        Directory(folder).createSync(recursive: true);
      } on Object {
        // A pasta padrão pode estar indisponível. O download avisa depois.
      }
    }
    final profiles = [..._current.profiles, preset];
    await ref.read(profileStoreProvider).save(profiles);
    state = AsyncData(_current.copyWith(profiles: profiles, clearError: true));
  }

  ProfileView get _current => state.requireValue;
}

extension on ProfileView {
  ProfileView copyWith({
    List<Profile>? profiles,
    String? selectedId,
    bool clearSelected = false,
    String? errorCode,
    bool clearError = false,
  }) {
    return ProfileView(
      profiles: profiles ?? this.profiles,
      selectedId: clearSelected ? null : selectedId ?? this.selectedId,
      errorCode: clearError ? null : errorCode ?? this.errorCode,
      backupPath: backupPath,
    );
  }
}
