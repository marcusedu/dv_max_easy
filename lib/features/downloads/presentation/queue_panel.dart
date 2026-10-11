import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/clipboard_offer.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/application/library_query.dart';
import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/downloads/domain/file_stamp.dart';
import 'package:dv_max_easy/features/downloads/domain/library.dart';
import 'package:dv_max_easy/features/downloads/domain/retention.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/io_file_stamp.dart';
import 'package:dv_max_easy/features/downloads/presentation/job_card.dart';
import 'package:dv_max_easy/features/downloads/presentation/source_favicon.dart';
import 'package:dv_max_easy/features/profiles/application/profile_controller.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
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
    required this.onConvert,
    required this.onOpenCompleted,
    super.key,
  });

  final TextEditingController urlController;
  final FocusNode urlFocus;
  final VoidCallback onSubmit;
  final Future<void> Function() onPaste;
  final ValueChanged<String> onDownload;
  final ValueChanged<String> onConvert;
  final ValueChanged<String> onOpenCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final jobs = ref.watch(downloadControllerProvider);
    final visible = queuePreview(jobs);
    final hidden = jobs.length - visible.length;
    final noticeId = ref.watch(duplicateNoticeProvider);
    DownloadJob? prior;
    if (noticeId != null) {
      for (final job in jobs) {
        if (job.id == noticeId) {
          prior = job;
        }
      }
    }
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
            _ActiveProfileMenu(name: profileName),
          ],
        ),
        const SizedBox(height: 6),
        Text(l10n.queueSubtitle, style: text.bodySmall),
        if (offer != null && isHttpUrl(offer)) ...[
          const SizedBox(height: AppSpacing.m),
          _ClipboardBanner(
            url: offer,
            onDownload: () => onDownload(offer),
            onDismiss: () =>
                ref.read(clipboardOfferProvider.notifier).dismiss(),
          ),
        ],
        if (offer != null && !isHttpUrl(offer)) ...[
          const SizedBox(height: AppSpacing.m),
          _LocalFileBanner(
            path: offer,
            onConvert: () => onConvert(offer),
            onDismiss: () =>
                ref.read(clipboardOfferProvider.notifier).dismiss(),
          ),
        ],
        if (prior != null) ...[
          const SizedBox(height: AppSpacing.m),
          _DuplicateBanner(
            onOpen: () {
              final url = prior!.url;
              ref.read(duplicateNoticeProvider.notifier).clear();
              onOpenCompleted(url);
            },
            onDismiss: () => ref.read(duplicateNoticeProvider.notifier).clear(),
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
        if (visible.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.l),
          Row(
            children: [
              Text(
                l10n.downloadsHeading,
                style: text.titleMedium?.copyWith(fontSize: 16),
              ),
              const SizedBox(width: 8),
              _Count(value: visible.length),
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
          if (hidden > 0) ...[
            const SizedBox(height: AppSpacing.s),
            Text(l10n.queuePreviewHint, style: text.bodySmall),
          ],
          const SizedBox(height: AppSpacing.m),
          Expanded(
            child: ListView.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
              itemBuilder: (_, index) => DownloadJobCard(job: visible[index]),
            ),
          ),
        ],
      ],
    );
  }
}

class CompletedPanel extends ConsumerStatefulWidget {
  const CompletedPanel({super.key});

  @override
  ConsumerState<CompletedPanel> createState() => _CompletedPanelState();
}

class _CompletedPanelState extends ConsumerState<CompletedPanel> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(libraryQueryProvider).text);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    ref.listen(libraryQueryProvider, (previous, next) {
      if (next.text != _search.text) {
        _search.text = next.text;
      }
    });
    final query = ref.watch(libraryQueryProvider);
    final jobs = ref.watch(downloadControllerProvider);
    final history = [
      for (final job in jobs)
        if (!job.running) job,
    ];
    if (history.isEmpty) {
      return Text(l10n.doneEmpty, style: text.bodyMedium);
    }
    final profiles =
        ref.watch(profileControllerProvider).asData?.value.profiles ??
        const <Profile>[];
    final reader = ref.watch(fileStampReaderProvider);
    final now = ref.watch(clockProvider).now();
    final shown = [
      for (final job in history)
        if (_matches(job, query, profiles, reader.stamp, now)) job,
    ];
    final notifier = ref.read(libraryQueryProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          decoration: InputDecoration(
            hintText: l10n.doneSearch,
            prefixIcon: const Icon(Icons.search, size: 18),
            isDense: true,
          ),
          onChanged: notifier.setText,
        ),
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
            _ChoiceFilter(
              label: l10n.filterSource,
              selected: query.host,
              options: distinctValues([
                for (final job in history) sourceHost(job.url),
              ]),
              onSelected: notifier.setHost,
            ),
            _ChoiceFilter(
              label: l10n.filterProfile,
              selected: query.profile,
              options: distinctValues([
                for (final job in history) job.profileName,
              ]),
              onSelected: notifier.setProfile,
            ),
            _ChoiceFilter(
              label: l10n.filterType,
              selected: query.type,
              options: distinctValues([
                for (final job in history) fileType(job),
              ]),
              onSelected: notifier.setType,
            ),
            _DiskFilter(disk: query.disk, onSelected: notifier.setDisk),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        if (shown.isEmpty)
          Text(l10n.doneEmptyFilter, style: text.bodyMedium)
        else
          Expanded(
            child: ListView.separated(
              itemCount: shown.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
              itemBuilder: (_, index) => DownloadJobCard(job: shown[index]),
            ),
          ),
      ],
    );
  }

  bool _matches(
    DownloadJob job,
    LibraryQuery query,
    List<Profile> profiles,
    FileStamp Function(String path) stampOf,
    DateTime now,
  ) {
    final path = job.outputPath;
    final stamp = path == null || path.isEmpty ? null : stampOf(path);
    final deleteAt = scheduledDelete(
      job: job,
      days: retentionDays(job, profiles),
      modified: stamp?.modified,
    );
    return libraryMatches(
      job,
      query,
      stamp: stamp,
      deleteAt: deleteAt,
      now: now,
    );
  }
}

class _ChoiceFilter extends StatelessWidget {
  const _ChoiceFilter({
    required this.label,
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final String? selected;
  final List<String> options;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: label,
      padding: EdgeInsets.zero,
      onSelected: (value) => onSelected(value.isEmpty ? null : value),
      itemBuilder: (context) => [
        PopupMenuItem(value: '', child: Text(l10n.filterAll)),
        for (final option in options)
          PopupMenuItem(value: option, child: Text(option)),
      ],
      child: _FilterFace(text: selected ?? label, active: selected != null),
    );
  }
}

class _DiskFilter extends StatelessWidget {
  const _DiskFilter({required this.disk, required this.onSelected});

  final DiskFilter disk;
  final ValueChanged<DiskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = {
      DiskFilter.any: l10n.filterDisk,
      DiskFilter.present: l10n.diskPresent,
      DiskFilter.missing: l10n.diskMissing,
      DiskFilter.scheduled: l10n.diskScheduled,
      DiskFilter.purged: l10n.diskPurged,
    };
    return PopupMenuButton<DiskFilter>(
      tooltip: l10n.filterDisk,
      padding: EdgeInsets.zero,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final value in DiskFilter.values)
          PopupMenuItem(
            value: value,
            child: Text(
              value == DiskFilter.any ? l10n.filterAll : labels[value]!,
            ),
          ),
      ],
      child: _FilterFace(text: labels[disk]!, active: disk != DiskFilter.any),
    );
  }
}

class _FilterFace extends StatelessWidget {
  const _FilterFace({required this.text, required this.active});

  final String text;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? scheme.primary.withValues(alpha: 0.16) : scheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: active ? scheme.primary : scheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 16,
              color: active ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DuplicateBanner extends StatelessWidget {
  const _DuplicateBanner({required this.onOpen, required this.onDismiss});

  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.tertiary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.history, size: 18, color: scheme.tertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.alreadyDownloaded,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: onDismiss,
              child: Text(l10n.duplicateDismiss),
            ),
            const SizedBox(width: 4),
            FilledButton(onPressed: onOpen, child: Text(l10n.seeCompleted)),
          ],
        ),
      ),
    );
  }
}

class _ActiveProfileMenu extends ConsumerWidget {
  const _ActiveProfileMenu({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final profiles =
        ref.watch(profileControllerProvider).asData?.value.profiles ?? const [];
    return PopupMenuButton<String>(
      tooltip: l10n.activeProfile,
      padding: EdgeInsets.zero,
      onSelected: (id) =>
          ref.read(profileControllerProvider.notifier).select(id),
      itemBuilder: (context) => [
        for (final profile in profiles)
          PopupMenuItem(value: profile.id, child: Text(profile.name)),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 6, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name ?? '…',
                style: text.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.expand_more, size: 18, color: scheme.primary),
            ],
          ),
        ),
      ),
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

class _LocalFileBanner extends StatelessWidget {
  const _LocalFileBanner({
    required this.path,
    required this.onConvert,
    required this.onDismiss,
  });

  final String path;
  final VoidCallback onConvert;
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
            Icon(Icons.movie_filter_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localOffer,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    path,
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
            FilledButton(onPressed: onConvert, child: Text(l10n.navConvert)),
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
