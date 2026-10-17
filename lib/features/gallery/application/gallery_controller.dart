import 'dart:async';

import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/io_file_stamp.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_catalog.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_document.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_rules.dart';
import 'package:dv_max_easy/features/gallery/infrastructure/gallery_files.dart';
import 'package:dv_max_easy/features/gallery/infrastructure/json_gallery_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final galleryControllerProvider =
    NotifierProvider<GalleryController, GalleryState>(GalleryController.new);

final class GalleryState {
  const GalleryState({required this.items, required this.index});

  final List<GalleryItem> items;
  final int index;

  GalleryItem? get current {
    if (items.isEmpty) {
      return null;
    }
    final safe = index.clamp(0, items.length - 1);
    return items[safe];
  }

  GalleryState copyWith({List<GalleryItem>? items, int? index}) {
    return GalleryState(items: items ?? this.items, index: index ?? this.index);
  }
}

final class GalleryController extends Notifier<GalleryState> {
  GalleryDocument? _doc;
  String? _currentId;
  Timer? _saveTimer;
  var _bound = false;

  @override
  GalleryState build() {
    _doc ??= ref.read(initialGalleryProvider);
    ref.keepAlive();
    if (!_bound) {
      _bound = true;
      final store = ref.read(galleryStoreProvider);
      ref.onDispose(() {
        _saveTimer?.cancel();
        store.save(_doc ?? GalleryDocument.empty);
      });
    }
    return _compose(ref.watch(downloadControllerProvider));
  }

  int savedPositionMs(String jobId) => _doc?.recordOf(jobId).positionMs ?? 0;

  void step(int direction) {
    if (direction == 0 || state.items.isEmpty) {
      return;
    }
    final next = state.index + direction;
    if (next < 0 || next >= state.items.length) {
      return;
    }
    _focus(state.items[next].jobId);
  }

  Future<void> toggleLike() async {
    final item = state.current;
    final doc = _doc;
    if (item == null || doc == null) {
      return;
    }
    final liked = !item.liked;
    _doc = doc.upsert(doc.recordOf(item.jobId).copyWith(liked: liked));
    final items = [...state.items];
    items[state.index] = item.copyWith(liked: liked);
    state = state.copyWith(items: items);
    await _saveNow();
  }

  Future<String?> deleteCurrent() async {
    final item = state.current;
    final doc = _doc;
    if (item == null || doc == null) {
      return null;
    }
    final removed = await ref
        .read(galleryFileDeleterProvider)
        .delete(item.path);
    if (!removed) {
      return 'delete_failed';
    }
    final items = state.items;
    final index = state.index;
    final follow = index + 1 < items.length
        ? items[index + 1].jobId
        : (index > 0 ? items[index - 1].jobId : null);
    _doc = doc
        .upsert(doc.recordOf(item.jobId).copyWith(removed: true))
        .copyWith(lastJobId: follow, clearLast: follow == null);
    _currentId = follow;
    state = _compose(ref.read(downloadControllerProvider));
    await _saveNow();
    return null;
  }

  void rememberPosition(String jobId, int positionMs, int? durationMs) {
    final doc = _doc;
    if (doc == null) {
      return;
    }
    final stored = rememberedPositionMs(
      positionMs: positionMs,
      durationMs: durationMs,
    );
    final record = doc.recordOf(jobId);
    final duration = durationMs != null && durationMs > 0
        ? durationMs
        : record.durationMs;
    if (record.positionMs == stored && record.durationMs == duration) {
      return;
    }
    _doc = doc.upsert(
      record.copyWith(positionMs: stored, durationMs: duration),
    );
    _scheduleSave();
  }

  void noteDuration(String jobId, int durationMs, int bytes) {
    final doc = _doc;
    if (doc == null || durationMs <= 0) {
      return;
    }
    final record = doc.recordOf(jobId);
    if (record.durationMs == durationMs && record.bytes == bytes) {
      return;
    }
    _doc = doc.upsert(record.copyWith(durationMs: durationMs, bytes: bytes));
    state = _compose(ref.read(downloadControllerProvider));
    _scheduleSave();
  }

  Future<void> flush() => _saveNow();

  void _focus(String jobId) {
    final doc = _doc;
    if (doc == null) {
      return;
    }
    _currentId = jobId;
    _doc = doc.copyWith(lastJobId: jobId);
    state = _compose(ref.read(downloadControllerProvider));
    _saveNow();
  }

  GalleryState _compose(List<DownloadJob> jobs) {
    final doc = _doc ?? GalleryDocument.empty;
    final reader = ref.read(fileStampReaderProvider);
    final items = buildGallery(
      jobs: jobs,
      document: doc,
      factsOf: (path) {
        final stamp = reader.stamp(path);
        return GalleryFileFacts(exists: stamp.exists, bytes: stamp.bytes);
      },
    );
    var index = 0;
    final wanted = _currentId ?? doc.lastJobId;
    if (wanted != null) {
      final found = items.indexWhere((item) => item.jobId == wanted);
      if (found >= 0) {
        index = found;
      }
    }
    if (items.isNotEmpty) {
      _currentId = items[index].jobId;
    }
    return GalleryState(items: items, index: index);
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () {
      _saveNow();
    });
  }

  Future<void> _saveNow() {
    _saveTimer?.cancel();
    _saveTimer = null;
    final doc = _doc;
    if (doc == null) {
      return Future.value();
    }
    return ref.read(galleryStoreProvider).save(doc);
  }
}
