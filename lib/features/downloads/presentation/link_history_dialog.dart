import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/clipboard_monitor.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/presentation/source_favicon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showLinkHistoryDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const LinkHistoryDialog(),
  );
}

class LinkHistoryDialog extends ConsumerStatefulWidget {
  const LinkHistoryDialog({super.key});

  @override
  ConsumerState<LinkHistoryDialog> createState() => _LinkHistoryDialogState();
}

class _LinkHistoryDialogState extends ConsumerState<LinkHistoryDialog> {
  bool _onlyUndownloaded = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final history = ref.watch(clipboardHistoryProvider);
    final jobs = ref.watch(downloadControllerProvider);

    final filtered = history.where((link) {
      if (!_onlyUndownloaded) return true;
      return !isAlreadyDownloaded(url: link.url, jobs: jobs);
    }).toList();

    final pendingCount = history.where((link) => !isAlreadyDownloaded(url: link.url, jobs: jobs)).length;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, color: scheme.primary, size: 24),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Histórico de Links Detectados',
                          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '$pendingCount ${pendingCount == 1 ? 'link pendente' : 'links pendentes'} para download',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  FilterChip(
                    label: const Text('Apenas não baixados'),
                    selected: _onlyUndownloaded,
                    onSelected: (val) => setState(() => _onlyUndownloaded = val),
                    avatar: Icon(
                      _onlyUndownloaded ? Icons.check_circle : Icons.circle_outlined,
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  if (pendingCount > 0)
                    PressableScale(
                      child: FilledButton.tonalIcon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onPressed: () {
                          final pendingUrls = history
                              .where((l) => !isAlreadyDownloaded(url: l.url, jobs: jobs))
                              .map((l) => l.url)
                              .toList();
                          ref.read(downloadControllerProvider.notifier).enqueueAll(pendingUrls);
                        },
                        icon: const Icon(Icons.download_rounded, size: 16),
                        label: const Text('Baixar Todos'),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.s),
                  if (history.isNotEmpty)
                    IconButton(
                      tooltip: 'Limpar histórico',
                      icon: const Icon(Icons.delete_sweep_outlined, size: 20),
                      onPressed: () => ref.read(clipboardHistoryProvider.notifier).clear(),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.m),
              if (filtered.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link_off_rounded,
                          size: 48,
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          _onlyUndownloaded
                              ? 'Todos os links detectados já foram baixados!'
                              : 'Nenhum link copiado foi detectado ainda.',
                          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Copie links de vídeos (YouTube, TikTok, Instagram...) para vê-los aqui.',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final alreadyDownloaded = isAlreadyDownloaded(url: item.url, jobs: jobs);
                      final inQueue = jobs.any(
                        (j) => j.url == item.url && (j.running || j.error == null && j.outputPath == null),
                      );

                      return _DetectedLinkCard(
                        link: item,
                        alreadyDownloaded: alreadyDownloaded,
                        inQueue: inQueue,
                        onDownload: () {
                          // Start download immediately without closing modal
                          ref.read(downloadControllerProvider.notifier).enqueue(item.url);
                        },
                        onRemove: () {
                          ref.read(clipboardHistoryProvider.notifier).remove(item.url);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectedLinkCard extends StatelessWidget {
  const _DetectedLinkCard({
    required this.link,
    required this.alreadyDownloaded,
    required this.inQueue,
    required this.onDownload,
    required this.onRemove,
  });

  final DetectedLink link;
  final bool alreadyDownloaded;
  final bool inQueue;
  final VoidCallback onDownload;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          SourceFavicon(url: link.url, size: 18),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  link.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (alreadyDownloaded)
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 13, color: Colors.green.shade400),
                          const SizedBox(width: 4),
                          Text('Já baixado', style: text.bodySmall?.copyWith(color: Colors.green.shade400)),
                        ],
                      )
                    else if (inQueue)
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
                          ),
                          const SizedBox(width: 6),
                          Text('Na fila...', style: text.bodySmall?.copyWith(color: scheme.primary)),
                        ],
                      )
                    else
                      Text('Pendente', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    Text('• ${_timeAgo(link.detectedAt)}', style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          if (!alreadyDownloaded && !inQueue)
            PressableScale(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Baixar'),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            tooltip: 'Remover do histórico',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}
