import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class TriageMarkdownPreview extends StatefulWidget {
  const TriageMarkdownPreview({
    required this.item,
    super.key,
  });

  final TriageItem item;

  @override
  State<TriageMarkdownPreview> createState() => _TriageMarkdownPreviewState();
}

class _TriageMarkdownPreviewState extends State<TriageMarkdownPreview> {
  String? _content;
  bool _isLoading = true;
  bool _showRaw = false;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
  }

  @override
  void didUpdateWidget(TriageMarkdownPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.path != widget.item.path) {
      _loadMarkdown();
    }
  }

  Future<void> _loadMarkdown() async {
    setState(() => _isLoading = true);
    try {
      final file = File(widget.item.path);
      if (!await file.exists()) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      const maxBytes = 256 * 1024;
      final bytes = await file.openRead(0, maxBytes).expand((i) => i).toList();
      final text = utf8.decode(bytes, allowMalformed: true);

      if (mounted) {
        setState(() {
          _content = text;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: scheme.primary),
      );
    }

    final markdownData = _content ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de ferramentas do Markdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 6),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'MARKDOWN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                widget.item.formatBytes(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              // Alternador entre Markdown Renderizado e Código Fonte
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Renderizado', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.preview_rounded, size: 13),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Fonte', style: TextStyle(fontSize: 11)),
                    icon: Icon(Icons.code_rounded, size: 13),
                  ),
                ],
                selected: {_showRaw},
                onSelectionChanged: (val) {
                  setState(() => _showRaw = val.first);
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              PressableScale(
                scaleDown: 0.95,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: markdownData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Markdown copiado para a área de transferência'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 13),
                  label: const Text('Copiar'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 24),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Área principal (Renderizada com flutter_markdown ou Texto Bruto)
        Expanded(
          child: _showRaw
              ? _buildRawView(scheme, markdownData)
              : _buildRenderedMarkdown(scheme, markdownData),
        ),
      ],
    );
  }

  Widget _buildRenderedMarkdown(ColorScheme scheme, String data) {
    return Markdown(
      data: data,
      selectable: true,
      padding: const EdgeInsets.all(AppSpacing.l),
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        h1: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
        h2: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
        h3: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
        code: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          backgroundColor: scheme.surfaceContainerHighest,
          color: scheme.primary,
        ),
        codeblockDecoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          border: Border.all(color: scheme.outlineVariant),
        ),
        blockquoteDecoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.06),
          border: Border(
            left: BorderSide(color: scheme.primary, width: 3),
          ),
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null && href.isNotEmpty) {
          const FileActions().openUrl(href);
        }
      },
    );
  }

  Widget _buildRawView(ColorScheme scheme, String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: SelectableText(
        text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          height: 1.5,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}
