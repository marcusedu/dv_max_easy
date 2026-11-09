import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/presentation/job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showTrayDownloadsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const TrayDownloadsDialog(),
  );
}

class TrayDownloadsDialog extends ConsumerWidget {
  const TrayDownloadsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final jobs = ref.watch(downloadControllerProvider);

    // Latest 15 successfully downloaded files
    final finished = jobs.where(downloadSucceeded).take(15).toList();

    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(top: 40, right: 24, bottom: 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.download_done_rounded, color: scheme.primary, size: 22),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Últimos Downloads',
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Arraste para fora ou clique para abrir',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.m),
              if (finished.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          'Nenhum download concluído ainda',
                          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: finished.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
                    itemBuilder: (_, index) => DownloadJobCard(job: finished[index]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
