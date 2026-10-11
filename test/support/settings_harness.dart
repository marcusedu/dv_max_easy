import 'package:dv_max_easy/app/dv_max_app.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/features/settings/domain/app_settings.dart';
import 'package:dv_max_easy/features/settings/domain/binary_path.dart';
import 'package:dv_max_easy/features/settings/domain/settings_ports.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

AppSettings readySettings() {
  return const AppSettings(
    defaultDownloadFolder: '/Users/me/Movies',
    uiLanguage: 'pt-BR',
    ytDlpPath: '/usr/local/bin/yt-dlp',
    ffmpegPath: '/usr/local/bin/ffmpeg',
  );
}

class MemorySettingsStore implements SettingsStore {
  MemorySettingsStore(this.settings);

  AppSettings settings;

  @override
  Future<SettingsLoad> load() async => SettingsLoad(settings);

  @override
  Future<void> save(AppSettings next) async {
    settings = next;
  }
}

final class AcceptingPathFacts implements PathFactsReader {
  const AcceptingPathFacts();

  @override
  PathFacts inspect(String path) {
    return PathFacts(resolved: path, kind: PathKind.file, executable: true);
  }
}

final class FixedVersionProbe implements VersionProbe {
  const FixedVersionProbe(this.version);

  final String version;

  @override
  Future<String?> readVersion(String executable) async => version;
}

Widget appWithSettings(AppSettings settings) {
  return ProviderScope(
    overrides: [
      settingsStoreProvider.overrideWithValue(MemorySettingsStore(settings)),
      pathFactsProvider.overrideWithValue(const AcceptingPathFacts()),
      versionProbeProvider.overrideWithValue(
        const FixedVersionProbe('yt-dlp 2026.1.1'),
      ),
    ],
    child: const DvMaxApp(),
  );
}
