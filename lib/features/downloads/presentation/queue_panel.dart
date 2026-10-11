import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/clipboard_offer.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/presentation/job_card.dart';
import 'package:dv_max_easy/features/downloads/presentation/source_favicon.dart';
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
    required this.onDownload,
    super.key,
  });

  final TextEditingController urlController;
  final FocusNode urlFocus;
  final VoidCallback onSubmit;
  final Future<void> Function() onPaste;
  final ValueChanged<String> onDownload;

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
    final finished = jobs.where((job) => !job.running && job.error == null);
    final offer = ref.watch(clipboardOfferProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(l10n.navQueue, style: pageTitle(scheme.onSurface)),
            const Spacer(),
            Text(l10n.activeProfile, style: text.bodySmall),
            const SizedBox(width: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                child: Text(
                  profileName ?? '…',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(l10n.queueSubtitle, style: text.bodySmall),
        if (offer != null) ...[
          const SizedBox(height: AppSpacing.m),
          _ClipboardBanner(
            url: offer,
            onDownload: () => onDownload(offer),
            onDismiss: () =>
                ref.read(clipboardOfferProvider.notifier).dismiss(),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: _LinkField(
                controller: urlController,
                focus: urlFocus,
                onSubmit: onSubmit,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () {
                onPaste();
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(l10n.downloadStart),
            ),
          ],
        ),
        if (jobs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Text(
                l10n.downloadsHeading,
                style: text.titleMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(width: 8),
              _Count(value: jobs.length),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: finished.isEmpty
                    ? null
                    : () => ref
                          .read(downloadControllerProvider.notifier)
                          .clearFinished(),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: Text(l10n.clearFinished),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: ListView.separated(
              itemCount: jobs.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
              itemBuilder: (_, index) => DownloadJobCard(job: jobs[index]),
            ),
          ),
        ],
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

class _LinkField extends StatelessWidget {
  const _LinkField({
    required this.controller,
    required this.focus,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return TextField(
          controller: controller,
          focusNode: focus,
          style: Theme.of(context).textTheme.bodyMedium,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            hintText: l10n.urlHint,
            prefixIcon: SourceFavicon(url: controller.text, size: 18),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: controller.clear,
                    icon: const Icon(Icons.close_rounded, size: 16),
                  ),
            fillColor: scheme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        );
      },
    );
  }
}

class _ClipboardBanner extends StatelessWidget {
  const _ClipboardBanner({
    required this.url,
    required this.onDownload,
    required this.onDismiss,
  });

  final String url;
  final VoidCallback onDownload;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SourceFavicon(url: url, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.clipboardOffer,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onDismiss,
              child: Text(l10n.clipboardDismiss),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: onDownload,
              child: Text(l10n.downloadStart),
            ),
          ],
        ),
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: SizedBox(
        width: 22,
        height: 22,
        child: Center(
          child: Text('$value', style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    );
  }
}

TextStyle pageTitle(Color color) {
  return TextStyle(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
    color: color,
  );
}
