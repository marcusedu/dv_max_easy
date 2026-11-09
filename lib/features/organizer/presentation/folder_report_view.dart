import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/organizer/application/organizer_controller.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FolderReportView extends ConsumerWidget {
  const FolderReportView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(organizerControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state.isScanning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Analisando arquivos da pasta…',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final report = state.report;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de seleção de pasta
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, color: scheme.primary),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pasta em Análise',
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.folderPath.isEmpty
                            ? 'Nenhuma pasta selecionada'
                            : state.folderPath,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                PressableScale(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final chosen = await getDirectoryPath();
                      if (chosen != null) {
                        ref
                            .read(organizerControllerProvider.notifier)
                            .setFolderPath(chosen);
                      }
                    },
                    icon: const Icon(Icons.folder_open_outlined, size: 16),
                    label: const Text('Trocar pasta'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                IconButton(
                  tooltip: 'Atualizar análise',
                  onPressed: () => ref
                      .read(organizerControllerProvider.notifier)
                      .scanCurrentFolder(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.l),

          if (report == null || report.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.folder_off_outlined,
                      size: 48,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      'Nenhum arquivo encontrado nesta pasta',
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Métricas gerais
            Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Espaço Total Ocupado',
                    value: report.formatTotalBytes(),
                    icon: Icons.pie_chart_outline_rounded,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _MetricCard(
                    title: 'Total de Arquivos',
                    value: '${report.totalFiles} itens',
                    icon: Icons.file_copy_outlined,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: _MetricCard(
                    title: 'Arquivos de Mídia',
                    value: '${report.mediaItems.length} itens',
                    icon: Icons.perm_media_outlined,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.l),

            // Distribuição por categoria e ações
            Container(
              padding: const EdgeInsets.all(AppSpacing.m),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Distribuição por Categoria',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  for (final cat in FileCategory.values)
                    if ((report.countByCategory[cat] ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s),
                        child: _CategoryRow(
                          category: cat,
                          count: report.countByCategory[cat] ?? 0,
                          bytes: report.bytesByCategory[cat] ?? 0,
                          onAction: cat == FileCategory.installer
                              ? () => _confirmPurgeInstallers(context, ref)
                              : null,
                        ),
                      ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Botões de Ação Principal
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (report.mediaItems.isNotEmpty)
                  PressableScale(
                    scaleDown: 0.96,
                    child: FilledButton.icon(
                      onPressed: () => ref
                          .read(organizerControllerProvider.notifier)
                          .startTriage(mediaOnly: true),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        'Iniciar Triagem de Mídia (${report.mediaItems.length} itens)',
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.l,
                          vertical: 16,
                        ),
                        textStyle: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.m),
                PressableScale(
                  scaleDown: 0.96,
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(organizerControllerProvider.notifier)
                        .startTriage(mediaOnly: false),
                    icon: const Icon(Icons.sort_rounded),
                    label: Text(
                      'Triar Todos os Arquivos (${report.totalFiles})',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmPurgeInstallers(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar Instaladores?'),
        content: const Text(
          'Deseja mover todos os pacotes e instaladores (.dmg, .pkg, .exe) desta pasta para a Lixeira do sistema operacional?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(organizerControllerProvider.notifier).purgeInstallers();
            },
            child: const Text('Mover para Lixeira'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.count,
    required this.bytes,
    this.onAction,
  });

  final FileCategory category;
  final int count;
  final int bytes;
  final VoidCallback? onAction;

  String _format(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1024 * 1024 * 1024) {
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(b / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (label, icon, color) = switch (category) {
      FileCategory.video => ('Vídeos', Icons.movie_outlined, Colors.blue),
      FileCategory.image => ('Fotos e Imagens', Icons.photo_outlined, Colors.teal),
      FileCategory.audio => ('Músicas e Áudios', Icons.audiotrack_outlined, Colors.purple),
      FileCategory.document => ('Documentos', Icons.description_outlined, Colors.orange),
      FileCategory.archive => ('Compactados (.zip, .rar)', Icons.folder_zip_outlined, Colors.brown),
      FileCategory.installer => ('Instaladores (.dmg, .pkg, .exe)', Icons.install_desktop_outlined, Colors.red),
      FileCategory.other => ('Outros Arquivos', Icons.insert_drive_file_outlined, Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            '$count itens • ${_format(bytes)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: AppSpacing.m),
            PressableScale(
              child: TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.delete_sweep_outlined, size: 15),
                label: const Text('Limpar para Lixeira'),
                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
