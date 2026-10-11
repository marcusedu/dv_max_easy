import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QueuePanel extends ConsumerWidget {
  const QueuePanel({
    required this.urlController,
    required this.urlFocus,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController urlController;
  final FocusNode urlFocus;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final jobs = ref.watch(downloadControllerProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(l10n.dropHint, style: text.bodyMedium),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: urlController,
                focusNode: urlFocus,
                decoration: InputDecoration(hintText: l10n.urlHint),
                style: text.bodyMedium,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            FilledButton(onPressed: onSubmit, child: Text(l10n.downloadStart)),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        if (jobs.isEmpty)
          Text(l10n.queueEmpty, style: text.bodySmall)
        else
          for (final job in jobs) _JobRow(job: job),
      ],
    );
  }
}

class _JobRow extends ConsumerWidget {
  const _JobRow({required this.job});

  final DownloadJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final detail = switch (job.error) {
      'missing_folder' => l10n.downloadNeedFolder,
      'missing_binary' => l10n.downloadNeedBinary,
      null => job.detail == 'starting'
          ? l10n.downloadStarting
          : job.detail == 'cancelled'
          ? l10n.downloadCancelled
          : job.detail == 'done'
          ? l10n.downloadDone
          : job.detail ?? '',
      _ => l10n.downloadFailed,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(job.url, style: text.bodyMedium, maxLines: 2),
          const SizedBox(height: AppSpacing.s),
          LinearProgressIndicator(value: job.running ? job.fraction : 1),
          const SizedBox(height: AppSpacing.s),
          Row(
            children: [
              Expanded(child: Text(detail, style: text.bodySmall)),
              if (job.running)
                TextButton(
                  onPressed: () =>
                      ref.read(downloadControllerProvider.notifier).cancel(job.id),
                  child: Text(l10n.downloadCancel),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
