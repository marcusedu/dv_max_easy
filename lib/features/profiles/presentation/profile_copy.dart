import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';

String profileSummary(AppLocalizations l10n, Profile profile) {
  return '${presetLabel(l10n, profile.preset)} · ${profile.container.name}';
}

String presetLabel(AppLocalizations l10n, QualityPreset preset) {
  return switch (preset) {
    QualityPreset.best => l10n.presetBest,
    QualityPreset.h1080 => l10n.preset1080,
    QualityPreset.h720 => l10n.preset720,
    QualityPreset.audio => l10n.presetAudio,
  };
}

String profileMessage(AppLocalizations l10n, String code) {
  return switch (code) {
    'name_empty' => l10n.errNameEmpty,
    'audio_embed_subs' => l10n.errAudioEmbed,
    'container_mismatch' => l10n.errContainer,
    'bitrate_invalid' => l10n.errBitrate,
    'rate_invalid' => l10n.errRate,
    'fragments_invalid' => l10n.errFragments,
    'template_escape' => l10n.errTemplate,
    'retention_invalid' => l10n.errRetention,
    _ => l10n.errRate,
  };
}
