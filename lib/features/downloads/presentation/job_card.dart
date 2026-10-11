import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

bool jobHasFile(DownloadJob job) {
  return !job.running &&
      job.error == null &&
      job.detail != 'cancelled' &&
      job.outputPath != null &&
      job.outputPath!.isNotEmpty;
}

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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final path = job.outputPath;
    final folder = folderOf(job);
    final fileName = fileTitle(path, job.url);
    final showFileName = path != null && path.isNotEmpty;
    final hasFile = path != null && jobHasFile(job);
    final hasMenu = hasFile || job.running;
    final container = containerOf(job);
    final quality = [
      if (job.qualityLabel != null) job.qualityLabel!,
      if (container.isNotEmpty) container,
    ].join(' • ');
    return DecoratedBox(
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
            _Thumb(url: job.thumbnailUrl),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: scheme.primary),
                  ),
                  if (showFileName) ...[
                    const SizedBox(height: 4),
                    Text(
                      fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: scheme.onSurface),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(_status(l10n), style: text.bodySmall),
                  if (job.running) ...[
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: job.fraction),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _KindChip(
                        audio: job.audio,
                        label: job.audio ? l10n.mediaAudio : l10n.mediaVideo,
                      ),
                      if (quality.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            quality,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (folder != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 15,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            folder,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (folder != null)
                        OutlinedButton.icon(
                          onPressed: _openFolder,
                          icon: const Icon(
                            Icons.folder_open_outlined,
                            size: 16,
                          ),
                          label: Text(l10n.fileReveal),
                        ),
                      if (hasMenu) ...[
                        const SizedBox(width: 6),
                        PopupMenuButton<String>(
                          tooltip: l10n.moreActions,
                          icon: Icon(
                            Icons.more_horiz,
                            color: scheme.onSurfaceVariant,
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'open' when path != null:
                                _run(_actions.open(path));
                              case 'copy' when path != null:
                                _run(
                                  _actions.copy(path),
                                  notice: l10n.fileCopied,
                                );
                              case 'share' when path != null:
                                _run(_actions.share(path));
                              case 'cancel':
                                ref
                                    .read(downloadControllerProvider.notifier)
                                    .cancel(job.id);
                            }
                          },
                          itemBuilder: (context) => [
                            if (hasFile) ...[
                              PopupMenuItem(
                                value: 'open',
                                child: Text(l10n.fileOpen),
                              ),
                              PopupMenuItem(
                                value: 'copy',
                                child: Text(l10n.fileCopy),
                              ),
                              PopupMenuItem(
                                value: 'share',
                                child: Text(l10n.fileShare),
                              ),
                            ],
                            if (job.running)
                              PopupMenuItem(
                                value: 'cancel',
                                child: Text(l10n.downloadCancel),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _status(AppLocalizations l10n) {
    return switch (job.error) {
      'missing_folder' => l10n.downloadNeedFolder,
      'missing_binary' => l10n.downloadNeedBinary,
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

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
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 28,
                  height: 28,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
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
