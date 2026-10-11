import 'dart:io';

import 'package:dv_max_easy/app/dv_max_app.dart';
import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/profiles/infrastructure/json_profile_store.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/features/settings/infrastructure/json_settings_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  final clock = SystemClock();
  final log = MemoryLog();
  final store = JsonSettingsStore(
    file: File(p.join(support.path, 'settings.json')),
    clock: clock,
    log: log,
  );
  final profiles = JsonProfileStore(
    file: File(p.join(support.path, 'profiles.json')),
    clock: clock,
    log: log,
  );
  runApp(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(clock),
        logProvider.overrideWithValue(log),
        settingsStoreProvider.overrideWithValue(store),
        profileStoreProvider.overrideWithValue(profiles),
      ],
      child: const DvMaxApp(),
    ),
  );
}
