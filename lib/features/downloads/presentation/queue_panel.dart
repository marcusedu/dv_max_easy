import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/presentation/job_card.dart';
import 'package:dv_max_easy/features/profiles/application/profile_controller.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class QueuePanel extends ConsumerWidget {
  const QueuePanel({
    required this.urlController,
    required this.urlFocus,
    required this.onSubmit,
    required this.onPaste,
    super.key,
  });

  final TextEditingController urlController;
  final FocusNode urlFocus;
  final VoidCallback onSubmit;
  final Future<void> Function() onPaste;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final jobs = ref.watch(downloadControllerProvider);
    final profileName = ref
        .watch(profileControllerProvider)
        .asData
        ?.value
        .selected
        ?.name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.activeProfile, style: text.bodySmall),
                const SizedBox(height: 2),
                Text(
                  profileName ?? '…',
                  style: text.titleMedium?.copyWith(color: scheme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(l10n.dropHint, style: text.bodySmall),
                const SizedBox(height: AppSpacing.s),
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
                    FilledButton(
                      onPressed: () {
                        onPaste();
                      },
                      child: Text(l10n.downloadStart),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        if (jobs.isEmpty)
          Text(l10n.queueEmpty, style: text.bodySmall)
        else
          Expanded(
            child: ListView.separated(
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
              itemBuilder: (_, index) => DownloadJobCard(job: jobs[index]),
            ),
          ),
      ],
    );
  }
}

class CompletedPanel extends ConsumerWidget {
  const CompletedPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final jobs = ref
        .watch(downloadControllerProvider)
        .where(jobHasFile)
        .toList();
    if (jobs.isEmpty) {
      return Text(
        l10n.doneEmpty,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }
    return ListView.separated(
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
      itemBuilder: (_, index) => DownloadJobCard(job: jobs[index]),
    );
  }
}
