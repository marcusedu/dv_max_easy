import 'dart:io';

import 'package:dv_max_easy/app/shell_section.dart';
import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/convert/application/convert_request.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/domain/cut_plan.dart';
import 'package:dv_max_easy/features/downloads/domain/download_failure.dart';
import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/downloads/domain/retention.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:dv_max_easy/features/downloads/presentation/cut_editor.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/io_file_stamp.dart';
import 'package:dv_max_easy/features/downloads/presentation/source_favicon.dart';
import 'package:dv_max_easy/features/profiles/application/profile_controller.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

bool jobHasFile(DownloadJob job) => downloadSucceeded(job);

String containerOf(DownloadJob job) {
  if (job.containerLabel.isNotEmpty) {
    return job.containerLabel;
  }
  final name = fileTitle(job.outputPath, '');
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) {
    return '';
  }
  return name.substring(dot + 1);
}

String? folderOf(DownloadJob job) {
  final path = job.outputPath;
  if (path != null && path.isNotEmpty) {
    return parentDirectory(path);
  }
  final folder = job.destination;
  if (folder == null || folder.isEmpty) {
    return null;
  }
  return folder;
}

class DownloadJobCard extends ConsumerStatefulWidget {
  const DownloadJobCard({required this.job, super.key});

  final DownloadJob job;

  @override
  ConsumerState<DownloadJobCard> createState() => _DownloadJobCardState();
}

class _DownloadJobCardState extends ConsumerState<DownloadJobCard> {
  final _actions = const FileActions();

  DownloadJob get job => widget.job;

  Future<void> _run(Future<void> action, {String? notice}) async {
    try {
      await action;
      if (!mounted || notice == null) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(notice)));
    } on Object {
      // A ação do sistema falhou; o cartão continua utilizável.
    }
  }

  bool _canCut(_CardFacts facts, String? path) {
    return facts.onDisk &&
        !job.audio &&
        path != null &&
        path.isNotEmpty &&
        isVideoFile(path);
  }

  void _openCut(String path) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => CutEditorPage(path: path)));
  }

  void _openFolder() {
    final path = job.outputPath;
    if (path != null && path.isNotEmpty) {
      _run(_actions.reveal(path));
      return;
    }
    final folder = job.destination;
    if (folder != null && folder.isNotEmpty) {
      _run(_actions.open(folder));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.watch(profileControllerProvider);
    ref.watch(fileStampReaderProvider);
    ref.watch(clockProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final path = job.outputPath;
    final folder = folderOf(job);
    final fileName = fileTitle(path, job.url);
    final showFileName = path != null && path.isNotEmpty;
    final facts = _facts();
    final hasFile = facts.onDisk && jobHasFile(job);
    final missing = jobHasFile(job) && !facts.onDisk;
    final hasMenu = _menuItems(l10n, facts).isNotEmpty;
    final container = containerOf(job);
    final quality = [
      if (job.qualityLabel != null) job.qualityLabel!,
      if (container.isNotEmpty) container,
    ].join(' • ');
    final card = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onSecondaryTapUp: (details) => _showContextMenu(details.globalPosition),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Thumb(
                url: job.thumbnailUrl,
                playLabel: l10n.fileOpen,
                onPlay: switch (path) {
                  final String saved when hasFile => () => _run(
                    _actions.open(saved),
                  ),
                  _ => null,
                },
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SourceFavicon(url: job.url),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            job.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        if (isHttpUrl(job.url))
                          IconButton(
                            tooltip: l10n.openLink,
                            onPressed: () => _run(_actions.openUrl(job.url)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 28,
                              height: 28,
                            ),
                            style: IconButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(28, 28),
                            ),
                            icon: Icon(
                              Icons.open_in_new,
                              size: 16,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                    if (showFileName) ...[
                      const SizedBox(height: 4),
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _status(l10n),
                      style: text.bodySmall?.copyWith(
                        color: job.error == null ? null : scheme.error,
                      ),
                    ),
                    if (_extra() case final extra?) ...[
                      const SizedBox(height: 4),
                      Text(
                        extra,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(color: scheme.error),
                      ),
                    ],
                    if (facts.modified != null && facts.onDisk) ...[
                      const SizedBox(height: 4),
                      Text(
                        l10n.downloadedAt(formatStamp(facts.modified!)),
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (facts.deleteAt != null &&
                        facts.onDisk &&
                        facts.deleteAt!.isAfter(facts.now)) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: scheme.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l10n.deletesIn(
                                retentionWhen(
                                  l10n,
                                  facts.deleteAt!.difference(facts.now),
                                ),
                              ),
                              style: text.bodySmall?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (missing) ...[
                      const SizedBox(height: 4),
                      Text(
                        job.purgedAt == null
                            ? l10n.fileMissing
                            : l10n.filePurged,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (job.error != null && !job.running)
                      TextButton.icon(
                        onPressed: () => ref
                            .read(downloadControllerProvider.notifier)
                            .retry(job.id),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(l10n.downloadRetry),
                      ),
                    if (missing)
                      TextButton.icon(
                        onPressed: () => ref
                            .read(downloadControllerProvider.notifier)
                            .retry(job.id),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(l10n.downloadAgain),
                      ),
                    if (job.running) ...[
                      const SizedBox(height: 10),
                      SmoothProgressIndicator(value: job.fraction),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _KindChip(
                        audio: job.audio,
                        label: job.audio ? l10n.mediaAudio : l10n.mediaVideo,
                      ),
                      if (quality.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          quality,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (folder != null) ...[
                    const SizedBox(height: 8),
                    Tooltip(
                      message: l10n.fileReveal,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _openFolder,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 15,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Text(
                                  folder,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (hasMenu) ...[
                    const SizedBox(height: 8),
                    PressableScale(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: PopupMenuButton<String>(
                          tooltip: l10n.moreActions,
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: scheme.outlineVariant),
                          ),
                          elevation: 4,
                          constraints: const BoxConstraints(
                            minWidth: 180,
                            maxWidth: 320,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(32, 32),
                            padding: EdgeInsets.zero,
                          ),
                          icon: Icon(
                            Icons.more_horiz,
                            color: scheme.onSurfaceVariant,
                          ),
                          onSelected: _onMenu,
                          itemBuilder: (context) => _menuItems(l10n, facts),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
    final shown = missing ? Opacity(opacity: 0.55, child: card) : card;
    if (path case final String saved when hasFile && fileDragOutEnabled) {
      return DragItemWidget(
        allowedOperations: () => [DropOperation.copy],
        dragItemProvider: (_) {
          final item = DragItem(suggestedName: fileName);
          item.add(
            Formats.fileUri(fileDragUri(saved, windows: Platform.isWindows)),
          );
          return item;
        },
        child: DraggableWidget(
          child: MouseRegion(cursor: SystemMouseCursors.grab, child: shown),
        ),
      );
    }
    return shown;
  }

  _CardFacts _facts() {
    final path = job.outputPath;
    final stamp = path == null || path.isEmpty
        ? null
        : ref.read(fileStampReaderProvider).stamp(path);
    final profiles =
        ref.read(profileControllerProvider).asData?.value.profiles ?? const [];
    final days = retentionDays(job, profiles);
    final now = ref.read(clockProvider).now();
    return _CardFacts(
      onDisk: stamp?.exists == true,
      modified: stamp?.modified,
      deleteAt: scheduledDelete(
        job: job,
        days: days,
        modified: stamp?.modified,
      ),
      canResume:
          job.keepFile &&
          days != null &&
          days > 0 &&
          stamp?.exists == true &&
          job.purgedAt == null,
      now: now,
    );
  }

  PopupMenuItem<String> _menuItem({
    required String value,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PopupMenuEntry<String>> _menuItems(
    AppLocalizations l10n,
    _CardFacts facts,
  ) {
    final folder = folderOf(job);
    final open = facts.onDisk && jobHasFile(job);
    final again = jobHasFile(job) && !facts.onDisk;
    final scheduled =
        facts.deleteAt != null &&
        facts.onDisk &&
        facts.deleteAt!.isAfter(facts.now);
    final scheme = Theme.of(context).colorScheme;
    return [
      if (open) ...[
        _menuItem(
          value: 'open',
          icon: Icons.play_arrow_outlined,
          label: l10n.fileOpen,
        ),
        _menuItem(
          value: 'copy',
          icon: Icons.content_copy_outlined,
          label: l10n.fileCopy,
        ),
      ],
      if (folder != null)
        _menuItem(
          value: 'reveal',
          icon: Icons.folder_open_outlined,
          label: l10n.fileReveal,
        ),
      if (open)
        _menuItem(
          value: 'share',
          icon: Icons.share_outlined,
          label: l10n.fileShare,
        ),
      if (open)
        _menuItem(
          value: 'convert',
          icon: Icons.transform_rounded,
          label: l10n.convertAction,
        ),
      if (_canCut(facts, job.outputPath))
        _menuItem(
          value: 'cut',
          icon: Icons.content_cut_outlined,
          label: l10n.cutOpen,
        ),
      if (scheduled)
        _menuItem(
          value: 'keep',
          icon: Icons.bookmark_border_rounded,
          label: l10n.keepFile,
        ),
      if (facts.canResume)
        _menuItem(
          value: 'resume',
          icon: Icons.schedule_rounded,
          label: l10n.resumeRetention,
        ),
      if (job.error != null && !job.running)
        _menuItem(
          value: 'retry',
          icon: Icons.refresh_rounded,
          label: l10n.downloadRetry,
        ),
      if (again)
        _menuItem(
          value: 'retry',
          icon: Icons.refresh_rounded,
          label: l10n.downloadAgain,
        ),
      if (job.running)
        _menuItem(
          value: 'cancel',
          icon: Icons.close_rounded,
          label: l10n.downloadCancel,
        ),
      const PopupMenuDivider(height: 8),
      _menuItem(
        value: 'remove',
        icon: Icons.delete_outline_rounded,
        label: l10n.jobRemove,
        color: scheme.error,
      ),
    ];
  }

  void _onMenu(String value) {
    final l10n = AppLocalizations.of(context);
    final path = job.outputPath;
    switch (value) {
      case 'open' when path != null:
        _run(_actions.open(path));
      case 'copy' when path != null:
        _run(_actions.copy(path), notice: l10n.fileCopied);
      case 'reveal':
        _openFolder();
      case 'share' when path != null:
        _run(_actions.share(path));
      case 'convert' when path != null:
        ref.read(convertRequestProvider.notifier).open(path);
        ref.read(shellSectionProvider.notifier).select(ShellSection.convert);
      case 'cut' when path != null:
        _openCut(path);
      case 'retry':
        ref.read(downloadControllerProvider.notifier).retry(job.id);
      case 'keep':
        ref
            .read(downloadControllerProvider.notifier)
            .setKeepFile(job.id, keep: true);
      case 'resume':
        ref
            .read(downloadControllerProvider.notifier)
            .setKeepFile(job.id, keep: false);
      case 'cancel':
        ref.read(downloadControllerProvider.notifier).cancel(job.id);
      case 'remove':
        _confirmRemove();
    }
  }

  Future<void> _confirmRemove() async {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_outline_rounded, color: scheme.error, size: 22),
              const SizedBox(width: 10),
              Text(l10n.jobRemoveTitle),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              l10n.jobRemoveMessage,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          actionsOverflowAlignment: OverflowBarAlignment.end,
          actions: [
            PressableScale(
              child: TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.downloadCancel),
              ),
            ),
            PressableScale(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  ref
                      .read(downloadControllerProvider.notifier)
                      .remove(job.id, deleteFile: false);
                },
                child: Text(l10n.jobRemoveOnlyList),
              ),
            ),
            PressableScale(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  ref
                      .read(downloadControllerProvider.notifier)
                      .remove(job.id, deleteFile: true);
                },
                child: Text(l10n.jobDeleteFile),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showContextMenu(Offset global) async {
    final l10n = AppLocalizations.of(context);
    final items = _menuItems(l10n, _facts());
    if (items.isEmpty) {
      return;
    }
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(global.dx, global.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      elevation: 4,
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 320),
      items: items,
    );
    if (!mounted || selected == null) {
      return;
    }
    _onMenu(selected);
  }

  String? _reason() {
    final code = job.error;
    if (code != 'failed') {
      return code;
    }
    final again = classifyDownloadFailure(job.errorDetail ?? '');
    return again == 'failed' ? code : again;
  }

  String? _extra() {
    return switch (_reason()) {
      'filename_too_long' ||
      'format_unavailable' ||
      'interrupted' ||
      null => null,
      _ => shortFailureDetail(job.errorDetail),
    };
  }

  String _status(AppLocalizations l10n) {
    return switch (_reason()) {
      'missing_folder' => l10n.downloadNeedFolder,
      'missing_binary' => l10n.downloadNeedBinary,
      'filename_too_long' => l10n.errFilename,
      'private_video' => l10n.errPrivate,
      'unavailable' => l10n.errUnavailable,
      'login_required' => l10n.errLogin,
      'unsupported_url' => l10n.errUnsupported,
      'forbidden' => l10n.errForbidden,
      'extract_failed' => l10n.errExtract,
      'format_unavailable' => l10n.errFormat,
      'ffmpeg_failed' => l10n.errFfmpeg,
      'network' => l10n.errNetwork,
      'interrupted' => l10n.errInterrupted,
      null when job.running => _running(l10n),
      null when job.detail == 'cancelled' => l10n.statusCancelled,
      null => l10n.statusDone,
      _ => l10n.statusFailed,
    };
  }

  String _running(AppLocalizations l10n) {
    final parts = <String>[
      if (job.fraction != null) '${(job.fraction! * 100).round()}%',
      if (job.downloaded != null && job.total != null && job.total! > 0)
        '${formatMegabytes(job.downloaded!)} de ${formatMegabytes(job.total!)}',
      if (job.speed != null && job.speed! > 0) formatSpeed(job.speed!),
      if (job.eta != null && job.eta! >= 0)
        l10n.statusRemaining(formatClock(job.eta!)),
    ];
    if (parts.isEmpty) {
      return l10n.downloadStarting;
    }
    return l10n.statusDownloading(parts.join(' • '));
  }
}

final class _CardFacts {
  const _CardFacts({
    required this.onDisk,
    required this.modified,
    required this.deleteAt,
    required this.canResume,
    required this.now,
  });

  final bool onDisk;
  final DateTime? modified;
  final DateTime? deleteAt;
  final bool canResume;
  final DateTime now;
}

String formatStamp(DateTime time) {
  const months = [
    'jan.',
    'fev.',
    'mar.',
    'abr.',
    'mai.',
    'jun.',
    'jul.',
    'ago.',
    'set.',
    'out.',
    'nov.',
    'dez.',
  ];
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.day} ${months[local.month - 1]} $hour:$minute';
}

String retentionWhen(AppLocalizations l10n, Duration left) {
  if (left.inMinutes < 60) {
    final count = left.inMinutes < 1 ? 1 : left.inMinutes;
    return count == 1 ? l10n.whenMinute : l10n.whenMinutes(count);
  }
  if (left.inHours < 24) {
    final count = left.inHours;
    return count == 1 ? l10n.whenHour : l10n.whenHours(count);
  }
  final count = (left.inHours / 24).ceil();
  return count == 1 ? l10n.whenDay : l10n.whenDays(count);
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.playLabel, this.onPlay});

  final String? url;
  final String playLabel;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final image = url == null
        ? null
        : Image.network(
            url!,
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          );
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 84,
        height: 84,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.surfaceContainerLow),
            ?image,
            if (onPlay != null)
              Center(
                child: PressableScale(
                  child: IconButton(
                    tooltip: playLabel,
                    onPressed: onPlay,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.45),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.audio, required this.label});

  final bool audio;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              audio ? Icons.music_note_outlined : Icons.videocam_outlined,
              size: 14,
              color: scheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
