import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/json_file.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/lists/domain/link_list.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class LinkListStore {
  Future<List<LinkList>> load();

  Future<void> save(List<LinkList> lists);
}

final linkListStoreProvider = Provider<LinkListStore>(
  (ref) => MemoryLinkListStore(),
);

final class MemoryLinkListStore implements LinkListStore {
  MemoryLinkListStore([this.lists = const []]);

  List<LinkList> lists;

  @override
  Future<List<LinkList>> load() async => lists;

  @override
  Future<void> save(List<LinkList> next) async {
    lists = next;
  }
}

final class JsonLinkListStore implements LinkListStore {
  JsonLinkListStore({
    required File file,
    required Clock clock,
    required Log log,
  }) : _json = JsonFile(file: file, clock: clock, log: log);

  final JsonFile _json;

  @override
  Future<List<LinkList>> load() async {
    final read = await _json.read(schemaVersion: 1);
    final raw = read.document?['lists'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map)
          ?LinkList.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<void> save(List<LinkList> lists) {
    return _json.write({
      'schemaVersion': 1,
      'lists': [for (final list in lists) list.toJson()],
    });
  }
}
