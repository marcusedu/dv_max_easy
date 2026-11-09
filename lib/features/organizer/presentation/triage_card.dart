import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';
import 'package:dv_max_easy/features/organizer/presentation/triage_document_preview.dart';
import 'package:dv_max_easy/features/organizer/presentation/triage_html_preview.dart';
import 'package:dv_max_easy/features/organizer/presentation/triage_markdown_preview.dart';
import 'package:dv_max_easy/features/organizer/presentation/triage_media_player.dart';
import 'package:dv_max_easy/features/organizer/presentation/triage_text_preview.dart';
import 'package:flutter/material.dart';

class TriageCard extends StatelessWidget {
  const TriageCard({
    required this.item,
    super.key,
  });

  final TriageItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com metadados do arquivo
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.s,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Row(
              children: [
                _CategoryBadge(category: item.category),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    item.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Text(
                  item.formatBytes(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (item.isFavorite) ...[
                  const SizedBox(width: AppSpacing.s),
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                ],
              ],
            ),
          ),

          // Área de visualização de conteúdo
          Expanded(
            child: Container(
              color: scheme.surface,
              child: Center(
                child: _buildMediaPreview(context),
              ),
            ),
          ),

          // Rodapé do card com caminho
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: 6,
            ),
            child: Text(
              item.path,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch (item.category) {
      case FileCategory.image:
        return Image.file(
          File(item.path),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _genericFallback(
            Icons.broken_image_outlined,
            'Não foi possível carregar a imagem',
            scheme,
          ),
        );

      case FileCategory.video:
        return TriageMediaPlayer(
          key: ValueKey(item.path),
          path: item.path,
          name: item.name,
          isVideo: true,
        );

      case FileCategory.audio:
        return TriageMediaPlayer(
          key: ValueKey(item.path),
          path: item.path,
          name: item.name,
          isVideo: false,
        );

      case FileCategory.document:
        if (item.isHtml) {
          return TriageHtmlPreview(
            key: ValueKey(item.path),
            item: item,
          );
        }
        if (item.isMarkdown) {
          return TriageMarkdownPreview(
            key: ValueKey(item.path),
            item: item,
          );
        }
        if (item.isTextFile) {
          return TriageTextPreview(
            key: ValueKey(item.path),
            item: item,
          );
        }
        if (item.isRichDocument) {
          return TriageDocumentPreview(
            key: ValueKey(item.path),
            item: item,
          );
        }
        return _genericFallback(
          Icons.description_outlined,
          'Documento (${item.extension.toUpperCase()})',
          scheme,
        );

      case FileCategory.archive:
        return _genericFallback(
          Icons.folder_zip_outlined,
          'Arquivo Compactado (${item.extension.toUpperCase()})',
          scheme,
        );

      case FileCategory.installer:
        return _genericFallback(
          Icons.install_desktop_outlined,
          'Instalador / Pacote (${item.extension.toUpperCase()})',
          scheme,
        );

      case FileCategory.other:
        if (item.isHtml) {
          return TriageHtmlPreview(
            key: ValueKey(item.path),
            item: item,
          );
        }
        if (item.isMarkdown) {
          return TriageMarkdownPreview(
            key: ValueKey(item.path),
            item: item,
          );
        }
        if (item.isTextFile) {
          return TriageTextPreview(
            key: ValueKey(item.path),
            item: item,
          );
        }
        return _genericFallback(
          Icons.insert_drive_file_outlined,
          'Arquivo (${item.extension})',
          scheme,
        );
    }
  }

  Widget _genericFallback(IconData icon, String label, ColorScheme scheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: scheme.onSurfaceVariant),
        const SizedBox(height: AppSpacing.m),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final FileCategory category;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (category) {
      FileCategory.video => ('Vídeo', Colors.blue),
      FileCategory.image => ('Imagem', Colors.teal),
      FileCategory.audio => ('Áudio', Colors.purple),
      FileCategory.document => ('Doc', Colors.orange),
      FileCategory.archive => ('Zip', Colors.brown),
      FileCategory.installer => ('Instalador', Colors.red),
      FileCategory.other => ('Outro', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
