import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
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

class DownloadJobCard extends ConsumerStatefulWidget {
  const DownloadJobCard({required this.job, super.key});

  final DownloadJob job;

  @override
  ConsumerState<DownloadJobCard> createState() => _DownloadJobCardState();
}

class _DownloadJobCardState extends ConsumerState<DownloadJobCard> {
  var _hover = false;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final title = fileTitle(job.outputPath, job.url);
    final path = job.outputPath;
    final status = _status(l10n);
    final failed = job.error != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: AppSpacing.motion,
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppSpacing.m),
        decoration: BoxDecoration(
          color: _hover
              ? Color.alphaBlend(
                  scheme.onSurface.withValues(alpha: 0.04),
                  scheme.surfaceContainerHighest,
                )
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Text(
                  status,
                  style: text.bodySmall?.copyWith(
                    color: failed ? scheme.error : scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              job.profileName.isEmpty
                  ? job.url
                  : '${job.profileName} · ${job.url}',
              style: text.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (job.running) ...[
              const SizedBox(height: AppSpacing.m),
              LinearProgressIndicator(value: job.fraction),
            ],
            if (job.running || (path != null && jobHasFile(job))) ...[
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  if (job.running)
                    TextButton(
                      onPressed: () => ref
                          .read(downloadControllerProvider.notifier)
                          .cancel(job.id),
                      child: Text(l10n.downloadCancel),
                    ),
                  if (path != null && jobHasFile(job)) ...[
                    _Action(
                      icon: Icons.open_in_new_rounded,
                      label: l10n.fileOpen,
                      onPressed: () => _run(_actions.open(path)),
                    ),
                    _Action(
                      icon: Icons.copy_rounded,
                      label: l10n.fileCopy,
                      onPressed: () =>
                          _run(_actions.copy(path), notice: l10n.fileCopied),
                    ),
                    _Action(
                      icon: Icons.folder_open_rounded,
                      label: l10n.fileReveal,
                      onPressed: () => _run(_actions.reveal(path)),
                    ),
                    _Action(
                      icon: Icons.ios_share_rounded,
                      label: l10n.fileShare,
                      onPressed: () => _run(_actions.share(path)),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _status(AppLocalizations l10n) {
    return switch (job.error) {
      'missing_folder' => l10n.downloadNeedFolder,
      'missing_binary' => l10n.downloadNeedBinary,
      null when job.running && job.fraction != null =>
        '${(job.fraction! * 100).round()}%',
      null when job.running => l10n.downloadStarting,
      null when job.detail == 'cancelled' => l10n.statusCancelled,
      null => l10n.statusDone,
      _ => l10n.statusFailed,
    };
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}
