enum QualityPreset { best, h1080, h720, audio }

enum MediaContainer { mkv, mp4, m4a, mp3 }

enum AudioFallback { any, none }

enum SubtitleMode { none, embed, file }

final class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.destinationFolder,
    required this.preset,
    required this.container,
    required this.preferredAudioLanguages,
    required this.audioFallback,
    required this.subtitleLanguages,
    required this.subtitleMode,
    required this.includeAutoSubtitles,
    required this.maxBitrateKbps,
    required this.rateLimit,
    required this.concurrentFragments,
    required this.filenameTemplate,
    this.deleteAfterDays,
  });

  static const musicId = 'a31c0b52-6d4e-4a1f-9c88-2f0b6e5d7a10';
  static const filmsId = '7c9e6679-7425-40de-944b-e07fc1f90ae7';
  static const defaultTemplate = '%(title)s [%(id)s].%(ext)s';

  final String id;
  final String name;
  final String? destinationFolder;
  final QualityPreset preset;
  final MediaContainer container;
  final List<String> preferredAudioLanguages;
  final AudioFallback audioFallback;
  final List<String> subtitleLanguages;
  final SubtitleMode subtitleMode;
  final bool includeAutoSubtitles;
  final int? maxBitrateKbps;
  final String? rateLimit;
  final int? concurrentFragments;
  final String filenameTemplate;
  final int? deleteAfterDays;

  bool get isAudio => preset == QualityPreset.audio;

  Profile copyWith({
    String? name,
    String? destinationFolder,
    bool clearFolder = false,
    QualityPreset? preset,
    MediaContainer? container,
    List<String>? preferredAudioLanguages,
    AudioFallback? audioFallback,
    List<String>? subtitleLanguages,
    SubtitleMode? subtitleMode,
    bool? includeAutoSubtitles,
    int? maxBitrateKbps,
    bool clearBitrate = false,
    String? rateLimit,
    bool clearRate = false,
    int? concurrentFragments,
    bool clearFragments = false,
    String? filenameTemplate,
    int? deleteAfterDays,
    bool clearRetention = false,
  }) {
    return Profile(
      id: id,
      name: name ?? this.name,
      destinationFolder: clearFolder
          ? null
          : destinationFolder ?? this.destinationFolder,
      preset: preset ?? this.preset,
      container: container ?? this.container,
      preferredAudioLanguages:
          preferredAudioLanguages ?? this.preferredAudioLanguages,
      audioFallback: audioFallback ?? this.audioFallback,
      subtitleLanguages: subtitleLanguages ?? this.subtitleLanguages,
      subtitleMode: subtitleMode ?? this.subtitleMode,
      includeAutoSubtitles: includeAutoSubtitles ?? this.includeAutoSubtitles,
      maxBitrateKbps: clearBitrate
          ? null
          : maxBitrateKbps ?? this.maxBitrateKbps,
      rateLimit: clearRate ? null : rateLimit ?? this.rateLimit,
      concurrentFragments: clearFragments
          ? null
          : concurrentFragments ?? this.concurrentFragments,
      filenameTemplate: filenameTemplate ?? this.filenameTemplate,
      deleteAfterDays: clearRetention
          ? null
          : deleteAfterDays ?? this.deleteAfterDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'destinationFolder': destinationFolder,
      'mediaKind': isAudio ? 'audio' : 'video',
      'container': container.name,
      'preset': preset.name,
      'preferredAudioLanguages': preferredAudioLanguages,
      'audioFallback': audioFallback.name,
      'subtitleLanguages': subtitleLanguages,
      'subtitleMode': subtitleMode.name,
      'includeAutoSubtitles': includeAutoSubtitles,
      'maxBitrateKbps': maxBitrateKbps,
      'rateLimit': rateLimit,
      'concurrentFragments': concurrentFragments,
      'filenameTemplate': filenameTemplate,
      'deleteAfterDays': deleteAfterDays,
    };
  }

  static Profile fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      name: json['name'] as String,
      destinationFolder: json['destinationFolder'] as String?,
      preset: QualityPreset.values.byName(json['preset'] as String),
      container: MediaContainer.values.byName(json['container'] as String),
      preferredAudioLanguages: _strings(json['preferredAudioLanguages']),
      audioFallback: AudioFallback.values.byName(
        json['audioFallback'] as String,
      ),
      subtitleLanguages: _strings(json['subtitleLanguages']),
      subtitleMode: SubtitleMode.values.byName(json['subtitleMode'] as String),
      includeAutoSubtitles: json['includeAutoSubtitles'] == true,
      maxBitrateKbps: json['maxBitrateKbps'] as int?,
      rateLimit: json['rateLimit'] as String?,
      concurrentFragments: json['concurrentFragments'] as int?,
      filenameTemplate: json['filenameTemplate'] as String? ?? defaultTemplate,
      deleteAfterDays: json['deleteAfterDays'] is int
          ? json['deleteAfterDays'] as int
          : null,
    );
  }

  static List<String> _strings(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is String) item,
    ];
  }
}

Profile musicPreset({
  String id = Profile.musicId,
  String? destinationFolder,
}) {
  return Profile(
    id: id,
    name: 'Música',
    destinationFolder: destinationFolder,
    preset: QualityPreset.audio,
    container: MediaContainer.mp3,
    preferredAudioLanguages: const [],
    audioFallback: AudioFallback.any,
    subtitleLanguages: const [],
    subtitleMode: SubtitleMode.none,
    includeAutoSubtitles: false,
    maxBitrateKbps: null,
    rateLimit: null,
    concurrentFragments: null,
    filenameTemplate: Profile.defaultTemplate,
  );
}

Profile filmsPreset({
  String id = Profile.filmsId,
  String? destinationFolder,
}) {
  return Profile(
    id: id,
    name: 'Filmes',
    destinationFolder: destinationFolder,
    preset: QualityPreset.h1080,
    container: MediaContainer.mkv,
    preferredAudioLanguages: const ['ja', 'pt'],
    audioFallback: AudioFallback.any,
    subtitleLanguages: const ['pt'],
    subtitleMode: SubtitleMode.embed,
    includeAutoSubtitles: false,
    maxBitrateKbps: null,
    rateLimit: null,
    concurrentFragments: null,
    filenameTemplate: Profile.defaultTemplate,
  );
}

List<Profile> assignInitialFolders(
  List<Profile> profiles, {
  required String music,
  required String films,
}) {
  return [
    for (final profile in profiles)
      if (profile.destinationFolder != null &&
          profile.destinationFolder!.isNotEmpty)
        profile
      else if (profile.name == 'Música' && music.isNotEmpty)
        profile.copyWith(destinationFolder: music)
      else if (profile.name == 'Filmes' && films.isNotEmpty)
        profile.copyWith(destinationFolder: films)
      else
        profile,
  ];
}
