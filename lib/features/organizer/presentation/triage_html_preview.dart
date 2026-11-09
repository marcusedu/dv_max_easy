import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/file_actions.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class TriageHtmlPreview extends StatefulWidget {
  const TriageHtmlPreview({
    required this.item,
    super.key,
  });

  final TriageItem item;

  @override
  State<TriageHtmlPreview> createState() => _TriageHtmlPreviewState();
}

class _TriageHtmlPreviewState extends State<TriageHtmlPreview> {
  InAppWebViewController? _webViewController;
  String? _htmlContent;
  bool _isLoadingSource = true;
  double _webProgress = 0.0;
  bool _showRaw = false;

  @override
  void initState() {
    super.initState();
    _loadSource();
  }

  @override
  void didUpdateWidget(TriageHtmlPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.path != widget.item.path) {
      _loadSource();
      _reloadWebView();
    }
  }

  Future<void> _loadSource() async {
    setState(() => _isLoadingSource = true);
    try {
      final file = File(widget.item.path);
      if (await file.exists()) {
        const maxBytes = 256 * 1024;
        final bytes = await file.openRead(0, maxBytes).expand((i) => i).toList();
        final text = utf8.decode(bytes, allowMalformed: true);
        if (mounted) {
          setState(() {
            _htmlContent = text;
            _isLoadingSource = false;
          });
        }
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingSource = false);
  }

  void _reloadWebView() {
    final controller = _webViewController;
    if (controller != null) {
      controller.loadUrl(
        urlRequest: URLRequest(url: WebUri.uri(Uri.file(widget.item.path))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra superior com controles da WebView
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
                  color: Colors.deepOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'HTML',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                widget.item.formatBytes(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              if (!isTest)
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('WebView', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.language_rounded, size: 13),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Código', style: TextStyle(fontSize: 11)),
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
                  onPressed: () => const FileActions().open(widget.item.path),
                  icon: const Icon(Icons.open_in_browser_rounded, size: 14),
                  label: const Text('Abrir no navegador'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 24),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Barra de progresso de carregamento da WebView
        if (_webProgress > 0 && _webProgress < 1.0 && !_showRaw)
          LinearProgressIndicator(
            value: _webProgress,
            minHeight: 2,
            backgroundColor: Colors.transparent,
            color: scheme.primary,
          ),

        // Conteúdo central: WebView embutida ou Código Fonte
        Expanded(
          child: (isTest || _showRaw)
              ? _buildSourceView(scheme)
              : _buildWebView(),
        ),
      ],
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri.uri(Uri.file(widget.item.path)),
      ),
      initialSettings: InAppWebViewSettings(
        transparentBackground: false,
        isInspectable: kDebugMode,
        supportZoom: true,
        useShouldOverrideUrlLoading: true,
      ),
      onWebViewCreated: (controller) {
        _webViewController = controller;
      },
      onProgressChanged: (controller, progress) {
        if (mounted) {
          setState(() {
            _webProgress = progress / 100.0;
          });
        }
      },
    );
  }

  Widget _buildSourceView(ColorScheme scheme) {
    if (_isLoadingSource) {
      return Center(
        child: CircularProgressIndicator(color: scheme.primary),
      );
    }

    final code = _htmlContent ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: SelectableText(
        code,
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
