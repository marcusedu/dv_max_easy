import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/json_file.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_document.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class GalleryStore {
  Future<GalleryDocument> load();

  Future<void> save(GalleryDocument document);
}

final galleryStoreProvider = Provider<GalleryStore>(
  (ref) => const NoopGalleryStore(),
);

final initialGalleryProvider = Provider<GalleryDocument>(
  (ref) => GalleryDocument.empty,
);

final class NoopGalleryStore implements GalleryStore {
  const NoopGalleryStore();

  @override
  Future<GalleryDocument> load() async => GalleryDocument.empty;

  @override
  Future<void> save(GalleryDocument document) async {}
}

final class JsonGalleryStore implements GalleryStore {
  JsonGalleryStore({required File file, required Clock clock, required Log log})
    : _json = JsonFile(file: file, clock: clock, log: log);

  final JsonFile _json;

  @override
  Future<GalleryDocument> load() async {
    final read = await _json.read(schemaVersion: 1);
    return GalleryDocument.fromJson(read.document);
  }

  @override
  Future<void> save(GalleryDocument document) {
    return _json.write(document.toJson());
  }
}
