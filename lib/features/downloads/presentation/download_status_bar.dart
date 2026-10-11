import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/domain/activity.dart';
import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/downloads/domain/retention.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/disk_space.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/io_file_stamp.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DownloadStatusBar extends ConsumerWidget {
  const DownloadStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final jobs = ref.watch(downloadControllerProvider);
    final stamp = ref.watch(fileStampReaderProvider).stamp;
    final activity = downloadActivity(jobs);
    final free = ref.watch(diskFreeProvider).asData?.value;
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant);
    final left = activity.running == 0
        ? l10n.statusIdle
        : [
            l10n.statusRunningCount(activity.running),
            if (activity.speed != null) formatSpeed(activity.speed!),
            if (activity.fraction != null)
              '${(activity.fraction! * 100).round()}%',
            if (activity.eta != null)
              l10n.statusRemaining(formatClock(activity.eta!)),
          ].join(' • ');
    final right = [
      l10n.statusFileCount(filesOnDisk(jobs, stamp)),
      l10n.statusUsed(formatBytes(storedBytes(jobs, stamp))),
      free == null ? '—' : l10n.statusFree(formatBytes(free)),
    ].join(' • ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (activity.fraction != null)
          LinearProgressIndicator(
            value: activity.fraction,
            minHeight: 3,
            backgroundColor: scheme.surfaceContainerLow,
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SizedBox(
            height: 28,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: style,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
