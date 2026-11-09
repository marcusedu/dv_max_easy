import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';
import 'package:dv_max_easy/features/organizer/infrastructure/quicklook_thumbnail_service.dart';
import 'package:flutter/material.dart';

class TriageDocumentPreview extends StatefulWidget {
  const TriageDocumentPreview({
    required this.item,
    super.key,
  });

  final TriageItem item;

  @override
  State<TriageDocumentPreview> createState() => _TriageDocumentPreviewState();
}

class _TriageDocumentPreviewState extends State<TriageDocumentPreview> {
  final _service = const QuicklookThumbnailService();
  String? _thumbnailPath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(TriageDocumentPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.path != widget.item.path) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    setState(() {
      _isLoading = true;
      _thumbnailPath = null;
    });

    final thumb = await _service.generateThumbnail(widget.item.path);

    if (mounted) {
      setState(() {
        _thumbnailPath = thumb;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra superior com formato e ação de abrir
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
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.item.extension.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                widget.item.formatBytes(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              PressableScale(
                scaleDown: 0.95,
                child: TextButton.icon(
                  onPressed: () => const FileActions().open(widget.item.path),
                  icon: const Icon(Icons.open_in_new_rounded, size: 13),
                  label: const Text('Abrir no leitor'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 24),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Área central: Renderização da página / documento
        Expanded(
          child: Center(
            child: _isLoading
                ? CircularProgressIndicator(color: scheme.primary)
                : (_thumbnailPath != null
                    ? _buildDocumentSheet(_thumbnailPath!)
                    : _buildFallbackCard(scheme)),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentSheet(String thumbPath) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(thumbPath),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _buildFallbackCard(Theme.of(context).colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackCard(ColorScheme scheme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.l),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.picture_as_pdf_outlined,
            size: 56,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          'Documento (${widget.item.extension.toUpperCase()})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.item.name,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.l),
        PressableScale(
          scaleDown: 0.95,
          child: OutlinedButton.icon(
            onPressed: () => const FileActions().open(widget.item.path),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Abrir no aplicativo padrão'),
          ),
        ),
      ],
    );
  }
}
