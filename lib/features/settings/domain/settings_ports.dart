import 'package:dv_max_easy/features/settings/domain/app_settings.dart';
import 'package:dv_max_easy/features/settings/domain/binary_path.dart';

final class SettingsLoad {
  const SettingsLoad(this.settings, {this.backupPath});

  final AppSettings settings;
  final String? backupPath;
}

abstract interface class SettingsStore {
  Future<SettingsLoad> load();

  Future<void> save(AppSettings settings);
}

abstract interface class PathFactsReader {
  PathFacts inspect(String path);
}

abstract interface class VersionProbe {
  Future<String?> readVersion(String executable);
}
