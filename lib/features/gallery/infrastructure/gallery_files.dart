import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class GalleryFileDeleter {
  Future<bool> delete(String path);
}

final galleryFileDeleterProvider = Provider<GalleryFileDeleter>(
  (ref) => const IoGalleryFileDeleter(),
);

final class IoGalleryFileDeleter implements GalleryFileDeleter {
  const IoGalleryFileDeleter();

  @override
  Future<bool> delete(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } on Object {
      return false;
    }
  }
}
