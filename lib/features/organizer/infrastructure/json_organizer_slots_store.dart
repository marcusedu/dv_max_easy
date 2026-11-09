import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/json_file.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/organizer/domain/target_folder_slot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class OrganizerSlotsStore {
  Future<List<TargetFolderSlot>> load();
  Future<void> save(List<TargetFolderSlot> slots);
}

final organizerSlotsStoreProvider = Provider<OrganizerSlotsStore>(
  (ref) => const NoopOrganizerSlotsStore(),
);

final class NoopOrganizerSlotsStore implements OrganizerSlotsStore {
  const NoopOrganizerSlotsStore();

  @override
  Future<List<TargetFolderSlot>> load() async => const [];

  @override
  Future<void> save(List<TargetFolderSlot> slots) async {}
}

final class JsonOrganizerSlotsStore implements OrganizerSlotsStore {
  JsonOrganizerSlotsStore({
    required File file,
    required Clock clock,
    required Log log,
  }) : _json = JsonFile(file: file, clock: clock, log: log);

  final JsonFile _json;

  @override
  Future<List<TargetFolderSlot>> load() async {
    final read = await _json.read(schemaVersion: 1);
    final doc = read.document;
    if (doc == null || doc['slots'] is! List) {
      return const [];
    }
    final list = doc['slots'] as List;
    return list
        .whereType<Map<String, dynamic>>()
        .map(TargetFolderSlot.fromJson)
        .toList();
  }

  @override
  Future<void> save(List<TargetFolderSlot> slots) {
    return _json.write({
      'schemaVersion': 1,
      'slots': slots.map((s) => s.toJson()).toList(),
    });
  }
}
