import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/json_file.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/settings/domain/app_settings.dart';
import 'package:dv_max_easy/features/settings/domain/settings_ports.dart';

final class JsonSettingsStore implements SettingsStore {
  JsonSettingsStore({
    required File file,
    required Clock clock,
    required Log log,
  }) : _json = JsonFile(file: file, clock: clock, log: log);

  final JsonFile _json;

  @override
  Future<SettingsLoad> load() async {
    final read = await _json.read(schemaVersion: AppSettings.schemaVersion);
    if (read.document == null) {
      return SettingsLoad(const AppSettings(), backupPath: read.backupPath);
    }
    return SettingsLoad(AppSettings.fromJson(read.document!));
  }

  @override
  Future<void> save(AppSettings settings) {
    return _json.write(settings.toJson());
  }
}
