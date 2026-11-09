// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/domain/activity.dart';
import 'package:dv_max_easy/features/downloads/domain/download_job.dart';
import 'package:dv_max_easy/features/downloads/domain/file_stamp.dart';
import 'package:dv_max_easy/features/downloads/domain/retention.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:dv_max_easy/features/gallery/domain/gallery_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tray_manager/legacy.dart';
import 'package:window_manager/window_manager.dart';

final trayServiceProvider = Provider<TrayService>((ref) {
  final service = TrayService();
  ref.onDispose(service.dispose);
  return service;
});

class TrayService with TrayListener {
  TrayService();

  bool _initialized = false;
  String _currentIcon = '';

  Future<void> init() async {
    if (kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    if (_initialized) return;
    _initialized = true;

    try {
      trayManager.addListener(this);

      await trayManager.setIcon('assets/tray_idle.png');
      _currentIcon = 'assets/tray_idle.png';

      final initialMenu = _buildMenu(const []);
      await trayManager.setContextMenu(initialMenu);
      await trayManager.setToolTip('DV Max — Pronto');
    } catch (_) {
      // Ignore if native tray setup fails in unsupported environments
    }
  }

  void dispose() {
    if (!_initialized) return;
    trayManager.removeListener(this);
    _initialized = false;
  }

  @override
  void onTrayIconMouseDown() async {
    try {
      await trayManager.popUpContextMenu();
    } catch (_) {}
  }

  @override
  void onTrayIconRightMouseDown() async {
    try {
      await trayManager.popUpContextMenu();
    } catch (_) {}
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    final key = menuItem.key;
    if (key == null) return;

    if (key == 'show') {
      if (await windowManager.isMinimized()) {
        await windowManager.restore();
      }
      await windowManager.show();
      await windowManager.focus();
    } else if (key == 'exit') {
      exit(0);
    } else if (key.startsWith('open_')) {
      final path = key.substring('open_'.length);
      if (path.isNotEmpty) {
        await const FileActions().open(path);
      }
    } else if (key.startsWith('reveal_')) {
      final path = key.substring('reveal_'.length);
      if (path.isNotEmpty) {
        await const FileActions().reveal(path);
      }
    }
  }

  Menu _buildMenu(List<DownloadJob> jobs) {
    final finished = jobs.where(downloadSucceeded).take(15).toList();
    final activity = downloadActivity(jobs);
    final statusText = activity.running > 0
        ? 'DV Max — Baixando ${activity.running}/${jobs.length}'
        : 'DV Max — Ocioso';

    final recentItems = <MenuItem>[];
    if (finished.isEmpty) {
      recentItems.add(
        MenuItem(
          key: 'recent_empty',
          label: 'Nenhum download concluído',
          disabled: true,
        ),
      );
    } else {
      for (final job in finished) {
        final path = job.outputPath ?? '';
        final name = galleryFileName(path);
        final displayName = name.length > 36 ? '${name.substring(0, 33)}...' : name;

        recentItems.add(
          MenuItem.submenu(
            key: 'item_${job.id}',
            label: displayName,
            submenu: Menu(
              items: [
                MenuItem(
                  key: 'open_$path',
                  label: 'Reproduzir',
                  onClick: (_) {
                    if (path.isNotEmpty) const FileActions().open(path);
                  },
                ),
                MenuItem(
                  key: 'reveal_$path',
                  label: 'Revelar na pasta',
                  onClick: (_) {
                    if (path.isNotEmpty) const FileActions().reveal(path);
                  },
                ),
              ],
            ),
          ),
        );
      }
    }

    return Menu(
      items: [
        MenuItem(
          key: 'status_header',
          label: statusText,
          disabled: true,
        ),
        MenuItem.separator(),
        MenuItem.submenu(
          key: 'recent_submenu',
          label: 'Últimos Downloads (${finished.length})',
          submenu: Menu(items: recentItems),
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'show',
          label: 'Abrir DV Max',
          onClick: (_) async {
            if (await windowManager.isMinimized()) {
              await windowManager.restore();
            }
            await windowManager.show();
            await windowManager.focus();
          },
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit',
          label: 'Sair',
          onClick: (_) => exit(0),
        ),
      ],
    );
  }

  Future<void> updateStatus({
    required List<DownloadJob> jobs,
    required FileStamp Function(String) stampOf,
    required int? freeBytes,
  }) async {
    if (!_initialized) return;

    final activity = downloadActivity(jobs);
    final running = activity.running;
    final total = jobs.length;
    final finished = filesOnDisk(jobs, stampOf);
    final used = formatBytes(storedBytes(jobs, stampOf));
    final free = freeBytes == null ? '—' : formatBytes(freeBytes);

    // Dynamic icon based on active downloads
    final iconTarget = running > 0 ? 'assets/tray_active.png' : 'assets/tray_idle.png';
    if (_currentIcon != iconTarget) {
      _currentIcon = iconTarget;
      try {
        await trayManager.setIcon(iconTarget);
      } catch (_) {}
    }

    // Tooltip format: Status: Baixando 2/5 | Baixados: 1.240 vídeos | Espaço Usado: 45.2 GB | Espaço Livre: 120 GB
    final statusText = running > 0 ? 'Baixando $running/$total' : 'Ocioso';
    final tooltip =
        'Status: $statusText | Baixados: $finished vídeos | Espaço Usado: $used | Espaço Livre: $free';

    try {
      await trayManager.setToolTip(tooltip);
      final menu = _buildMenu(jobs);
      await trayManager.setContextMenu(menu);
    } catch (_) {}
  }
}
