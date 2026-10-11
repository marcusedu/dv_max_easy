import 'package:dv_max_easy/l10n/app_localizations.dart';

String settingsMessage(
  AppLocalizations l10n,
  String code, {
  String? detail,
}) {
  return switch (code) {
    'broken_link' => l10n.errBrokenLink,
    'not_file' => l10n.errNotFile,
    'not_executable' => l10n.errNotExecutable,
    'forbidden_dir' => l10n.errForbiddenDir,
    'version_failed' => l10n.errVersion,
    'ffprobe_missing' => l10n.errFfprobe,
    'not_found' => l10n.errNotFound,
    'schema_reset' => l10n.schemaReset(detail ?? ''),
    _ => l10n.errVersion,
  };
}
