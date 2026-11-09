import 'dart:io';

import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/organizer/domain/folder_report.dart';
import 'package:dv_max_easy/features/organizer/domain/target_folder_slot.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_action.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';
import 'package:dv_max_easy/features/organizer/infrastructure/io_file_mover.dart';
import 'package:dv_max_easy/features/organizer/infrastructure/io_folder_scanner.dart';
import 'package:dv_max_easy/features/organizer/infrastructure/json_organizer_slots_store.dart';
import 'package:dv_max_easy/features/organizer/infrastructure/system_trash_service.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

final folderScannerProvider = Provider<IoFolderScanner>(
  (ref) => const IoFolderScanner(),
);

final fileMoverProvider = Provider<IoFileMover>(
  (ref) => const IoFileMover(),
);

final systemTrashProvider = Provider<SystemTrashService>(
  (ref) => const SystemTrashService(),
);

final organizerControllerProvider =
    NotifierProvider<OrganizerController, OrganizerState>(
      OrganizerController.new,
    );

final class OrganizerState {
  const OrganizerState({
    required this.folderPath,
    this.report,
    this.isScanning = false,
    this.slots = const [],
    this.queue = const [],
    this.currentIndex = 0,
    this.stashedItems = const [],
    this.actionHistory = const [],
    this.isTriageActive = false,
    this.lastToast,
    this.errorNotice,
  });

  final String folderPath;
  final FolderReport? report;
  final bool isScanning;
  final List<TargetFolderSlot> slots;
  final List<TriageItem> queue;
  final int currentIndex;
  final List<TriageItem> stashedItems;
  final List<TriageAction> actionHistory;
  final bool isTriageActive;
  final String? lastToast;
  final String? errorNotice;

  TriageItem? get currentItem {
    if (queue.isEmpty || currentIndex < 0 || currentIndex >= queue.length) {
      return null;
    }
    return queue[currentIndex];
  }

  bool get hasPrevious => currentIndex > 0;
  bool get hasNext => currentIndex < queue.length - 1;
  bool get canUndo => actionHistory.isNotEmpty;
  bool get isCompleted => queue.isNotEmpty && currentIndex >= queue.length;

  int get processedCount =>
      queue.isEmpty ? 0 : currentIndex.clamp(0, queue.length);

  OrganizerState copyWith({
    String? folderPath,
    FolderReport? report,
    bool? isScanning,
    List<TargetFolderSlot>? slots,
    List<TriageItem>? queue,
    int? currentIndex,
    List<TriageItem>? stashedItems,
    List<TriageAction>? actionHistory,
    bool? isTriageActive,
    String? lastToast,
    bool clearToast = false,
    String? errorNotice,
    bool clearError = false,
  }) {
    return OrganizerState(
      folderPath: folderPath ?? this.folderPath,
      report: report ?? this.report,
      isScanning: isScanning ?? this.isScanning,
      slots: slots ?? this.slots,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      stashedItems: stashedItems ?? this.stashedItems,
      actionHistory: actionHistory ?? this.actionHistory,
      isTriageActive: isTriageActive ?? this.isTriageActive,
      lastToast: clearToast ? null : lastToast ?? this.lastToast,
      errorNotice: clearError ? null : errorNotice ?? this.errorNotice,
    );
  }
}

final class OrganizerController extends Notifier<OrganizerState> {
  var _initialized = false;

  @override
  OrganizerState build() {
    ref.keepAlive();
    final state = OrganizerState(folderPath: _defaultFolder());
    if (!_initialized) {
      _initialized = true;
      Future.microtask(() => init());
    }
    return state;
  }

  String _home() =>
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';

  String _defaultFolder() {
    final standard = ref.read(standardFoldersProvider);
    if (standard.downloads.isNotEmpty &&
        Directory(standard.downloads).existsSync()) {
      return standard.downloads;
    }
    final home = _home();
    if (home.isNotEmpty) {
      final dl = p.join(home, 'Downloads');
      if (Directory(dl).existsSync()) {
        return dl;
      }
    }
    return '';
  }

  Future<void> init() async {
    final store = ref.read(organizerSlotsStoreProvider);
    var savedSlots = await store.load();

    if (savedSlots.isEmpty) {
      final home = _home();
      final standard = ref.read(standardFoldersProvider);
      savedSlots = createDefaultSlots(
        picturesPath: p.join(home, 'Pictures'),
        moviesPath: standard.films.isNotEmpty
            ? standard.films
            : p.join(home, 'Movies'),
        musicPath: standard.music.isNotEmpty
            ? standard.music
            : p.join(home, 'Music'),
        documentsPath: p.join(home, 'Documents'),
      );
      await store.save(savedSlots);
    }

    state = state.copyWith(slots: savedSlots);
    if (state.folderPath.isNotEmpty) {
      await scanCurrentFolder();
    }
  }

  Future<void> setFolderPath(String path) async {
    if (path == state.folderPath) {
      return;
    }
    state = state.copyWith(folderPath: path, isTriageActive: false);
    await scanCurrentFolder();
  }

  Future<void> scanCurrentFolder() async {
    if (state.folderPath.isEmpty) {
      return;
    }
    state = state.copyWith(isScanning: true, clearError: true);
    final scanner = ref.read(folderScannerProvider);
    try {
      final report = await scanner.scanFolder(state.folderPath);
      state = state.copyWith(report: report, isScanning: false);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorNotice: 'Falha ao analisar a pasta: $e',
      );
    }
  }

  void startTriage({bool mediaOnly = true}) {
    final report = state.report;
    if (report == null || report.items.isEmpty) {
      return;
    }

    final items = mediaOnly ? report.mediaItems : report.items;
    state = state.copyWith(
      queue: items,
      currentIndex: 0,
      stashedItems: const [],
      actionHistory: const [],
      isTriageActive: true,
      clearToast: true,
    );
  }

  void exitTriage() {
    state = state.copyWith(isTriageActive: false);
    scanCurrentFolder();
  }

  void nextItem() {
    if (state.hasNext) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        clearToast: true,
      );
    } else if (state.currentIndex == state.queue.length - 1) {
      // Avançou além do último item -> Concluiu a fila
      state = state.copyWith(
        currentIndex: state.queue.length,
        clearToast: true,
      );
    }
  }

  void previousItem() {
    if (state.hasPrevious) {
      state = state.copyWith(
        currentIndex: state.currentIndex - 1,
        clearToast: true,
      );
    }
  }

  Future<void> moveToSlot(int slotNumber) async {
    final item = state.currentItem;
    if (item == null) return;

    final slot = state.slots.firstWhere(
      (s) => s.slotNumber == slotNumber,
      orElse: () => TargetFolderSlot(slotNumber: slotNumber, label: '', path: ''),
    );

    if (!slot.isConfigured) {
      state = state.copyWith(
        lastToast: 'Slot $slotNumber não configurado. Toque para escolher pasta.',
      );
      return;
    }

    final mover = ref.read(fileMoverProvider);
    try {
      final destPath = await mover.moveFile(
        sourcePath: item.path,
        targetDirectory: slot.path,
      );

      ref.read(downloadControllerProvider.notifier).updateOutputPath(
            oldPath: item.path,
            newPath: destPath,
          );

      final action = TriageAction(
        id: '${DateTime.now().millisecondsSinceEpoch}_$slotNumber',
        item: item,
        type: TriageActionType.movedToSlot,
        timestamp: DateTime.now(),
        destinationPath: destPath,
        slotNumber: slotNumber,
      );

      state = state.copyWith(
        actionHistory: [...state.actionHistory, action],
        lastToast: '${item.name} ➔ ${slot.label}',
        currentIndex: state.currentIndex + 1,
      );
    } catch (e) {
      state = state.copyWith(errorNotice: 'Falha ao mover arquivo: $e');
    }
  }

  Future<void> trashCurrent() async {
    final item = state.currentItem;
    if (item == null) return;

    final trashService = ref.read(systemTrashProvider);
    try {
      await trashService.moveToTrash(item.path);

      final action = TriageAction(
        id: '${DateTime.now().millisecondsSinceEpoch}_trash',
        item: item,
        type: TriageActionType.movedToTrash,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        actionHistory: [...state.actionHistory, action],
        lastToast: '${item.name} movido para a Lixeira',
        currentIndex: state.currentIndex + 1,
      );
    } catch (e) {
      state = state.copyWith(errorNotice: 'Falha ao enviar para lixeira: $e');
    }
  }

  void stashTemporaryCurrent() {
    final item = state.currentItem;
    if (item == null) return;

    final action = TriageAction(
      id: '${DateTime.now().millisecondsSinceEpoch}_stash',
      item: item,
      type: TriageActionType.stashedTemporary,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      stashedItems: [...state.stashedItems, item],
      actionHistory: [...state.actionHistory, action],
      lastToast: '${item.name} adicionado à lista temporária',
      currentIndex: state.currentIndex + 1,
    );
  }

  void toggleFavoriteCurrent() {
    final item = state.currentItem;
    if (item == null) return;

    final updated = item.copyWith(isFavorite: !item.isFavorite);
    final newQueue = List<TriageItem>.from(state.queue);
    newQueue[state.currentIndex] = updated;

    state = state.copyWith(
      queue: newQueue,
      lastToast: updated.isFavorite ? 'Favoritado ⭐' : 'Desmarcado',
    );
  }

  Future<void> undo() async {
    if (!state.canUndo) return;

    final lastAction = state.actionHistory.last;
    final history = state.actionHistory.sublist(0, state.actionHistory.length - 1);
    final mover = ref.read(fileMoverProvider);

    try {
      if (lastAction.type == TriageActionType.movedToSlot &&
          lastAction.destinationPath != null) {
        await mover.restoreFile(
          currentPath: lastAction.destinationPath!,
          originalPath: lastAction.item.path,
        );
        ref.read(downloadControllerProvider.notifier).updateOutputPath(
              oldPath: lastAction.destinationPath!,
              newPath: lastAction.item.path,
            );
      } else if (lastAction.type == TriageActionType.stashedTemporary) {
        state = state.copyWith(
          stashedItems: state.stashedItems
              .where((i) => i.path != lastAction.item.path)
              .toList(),
        );
      }

      final prevIndex = (state.currentIndex > 0)
          ? state.currentIndex - 1
          : 0;

      state = state.copyWith(
        actionHistory: history,
        currentIndex: prevIndex,
        lastToast: 'Ação desfeita: ${lastAction.item.name}',
      );
    } catch (e) {
      state = state.copyWith(errorNotice: 'Falha ao desfazer: $e');
    }
  }

  Future<void> updateSlot(
    int slotNumber, {
    required String label,
    required String path,
  }) async {
    final newSlots = state.slots.map((s) {
      if (s.slotNumber == slotNumber) {
        return s.copyWith(label: label, path: path);
      }
      return s;
    }).toList();

    state = state.copyWith(slots: newSlots);
    final store = ref.read(organizerSlotsStoreProvider);
    await store.save(newSlots);
  }

  Future<void> purgeInstallers() async {
    final report = state.report;
    if (report == null || report.installerItems.isEmpty) return;

    final trashService = ref.read(systemTrashProvider);
    var count = 0;
    for (final item in report.installerItems) {
      try {
        await trashService.moveToTrash(item.path);
        count++;
      } catch (_) {}
    }

    state = state.copyWith(
      lastToast: '$count instalador(es) enviados para a Lixeira',
    );
    await scanCurrentFolder();
  }
}
