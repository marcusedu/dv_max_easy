import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/profiles/domain/profile_rules.dart';
import 'package:dv_max_easy/features/profiles/infrastructure/json_profile_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('2m is stored as 2M and fragments stay inside 1 to 16', () {
    final profile = filmsPreset().copyWith(rateLimit: '2m', concurrentFragments: 4);
    expect(validateProfile(profile), isEmpty);
    expect(normalized(profile).rateLimit, '2M');

    expect(
      validateProfile(filmsPreset().copyWith(concurrentFragments: 0)),
      contains('fragments_invalid'),
    );
    expect(
      validateProfile(filmsPreset().copyWith(concurrentFragments: 17)),
      contains('fragments_invalid'),
    );
    expect(
      validateProfile(filmsPreset().copyWith(concurrentFragments: null, clearFragments: true)),
      isEmpty,
    );
  });

  test('audio profile cannot embed subtitles and template cannot escape', () {
    expect(
      validateProfile(musicPreset().copyWith(subtitleMode: SubtitleMode.embed)),
      contains('audio_embed_subs'),
    );
    expect(
      validateProfile(filmsPreset().copyWith(container: MediaContainer.mp3)),
      contains('container_mismatch'),
    );
    expect(
      validateProfile(filmsPreset().copyWith(filenameTemplate: '../fora.mkv')),
      contains('template_escape'),
    );
  });

  test('missing file seeds music and films and does not recreate later', () async {
    final directory = await Directory.systemTemp.createTemp('dv-max-profiles');
    addTearDown(() => directory.delete(recursive: true));
    final store = JsonProfileStore(
      file: File('${directory.path}/profiles.json'),
      clock: FixedClock(DateTime.utc(2026, 10, 10)),
      log: MemoryLog(),
    );

    final seeded = await store.ensureLoaded();
    expect(seeded.seeded, isTrue);
    expect(seeded.profiles.map((profile) => profile.name), ['Música', 'Filmes']);
    expect(preferredProfileId(seeded.profiles, null), Profile.filmsId);

    await store.save([seeded.byName('Música')!]);
    final again = JsonProfileStore(
      file: File('${directory.path}/profiles.json'),
      clock: FixedClock(DateTime.utc(2026, 10, 10)),
      log: MemoryLog(),
    );
    final loaded = await again.ensureLoaded();
    expect(loaded.seeded, isFalse);
    expect(loaded.profiles.map((profile) => profile.name), ['Música']);
  });
}