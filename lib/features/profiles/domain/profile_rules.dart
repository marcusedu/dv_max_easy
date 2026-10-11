import 'package:dv_max_easy/features/profiles/domain/profile.dart';

final _ratePattern = RegExp(r'^([0-9]+(?:\.[0-9]+)?)([kmgKMG])?$');

String? normalizeRateLimit(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  final match = _ratePattern.firstMatch(raw.trim());
  if (match == null) {
    return null;
  }
  final suffix = (match.group(2) ?? '').toUpperCase();
  return '${match.group(1)}$suffix';
}

bool rateLimitIsValid(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return true;
  }
  return _ratePattern.hasMatch(raw.trim());
}

List<String> validateProfile(Profile profile) {
  final errors = <String>[];
  if (profile.name.trim().isEmpty) {
    errors.add('name_empty');
  }
  if (profile.isAudio && profile.subtitleMode == SubtitleMode.embed) {
    errors.add('audio_embed_subs');
  }
  final audioContainers = {MediaContainer.mp3, MediaContainer.m4a};
  final videoContainers = {MediaContainer.mkv, MediaContainer.mp4};
  if (profile.isAudio && !audioContainers.contains(profile.container)) {
    errors.add('container_mismatch');
  }
  if (!profile.isAudio && !videoContainers.contains(profile.container)) {
    errors.add('container_mismatch');
  }
  final bitrate = profile.maxBitrateKbps;
  if (bitrate != null && bitrate <= 0) {
    errors.add('bitrate_invalid');
  }
  if (!rateLimitIsValid(profile.rateLimit)) {
    errors.add('rate_invalid');
  }
  final fragments = profile.concurrentFragments;
  if (fragments != null && (fragments < 1 || fragments > 16)) {
    errors.add('fragments_invalid');
  }
  if (_templateEscapes(profile.filenameTemplate)) {
    errors.add('template_escape');
  }
  return errors;
}

String? preferredProfileId(List<Profile> profiles, String? selectedId) {
  if (profiles.any((profile) => profile.id == selectedId)) {
    return selectedId;
  }
  for (final name in ['Filmes', 'Música']) {
    for (final profile in profiles) {
      if (profile.name == name) {
        return profile.id;
      }
    }
  }
  return null;
}

bool _templateEscapes(String template) {
  if (template.trim().isEmpty) {
    return true;
  }
  if (template.contains('/') || template.contains(r'\')) {
    return true;
  }
  return template.split(RegExp(r'\s+')).contains('..') || template.contains('..');
}

Profile normalized(Profile profile) {
  return profile.copyWith(
    name: profile.name.trim(),
    rateLimit: normalizeRateLimit(profile.rateLimit),
    clearRate: normalizeRateLimit(profile.rateLimit) == null,
    filenameTemplate: profile.filenameTemplate.trim(),
  );
}
