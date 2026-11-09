import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TriageTextPreview extends StatefulWidget {
  const TriageTextPreview({
    required this.item,
    super.key,
  });

  final TriageItem item;

  @override
  State<TriageTextPreview> createState() => _TriageTextPreviewState();
}

class _TriageTextPreviewState extends State<TriageTextPreview> {
  String? _content;
  List<String> _lines = const [];
  List<List<String>> _csvRows = const [];
  bool _isLoading = true;
  bool _isBinary = false;
  bool _truncated = false;
  bool _showRaw = false;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  @override
  void didUpdateWidget(TriageTextPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.path != widget.item.path) {
      _loadFile();
    }
  }

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _isBinary = false;
      _truncated = false;
      _showRaw = false;
      _content = null;
      _lines = const [];
      _csvRows = const [];
    });

    try {
      final file = File(widget.item.path);
      if (!await file.exists()) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Lê no máximo 128 KB para manter performance fluida
      const maxBytes = 128 * 1024;
      final bytes = await file.openRead(0, maxBytes).expand((i) => i).toList();

      // Checa se é binário (procura por bytes nulos)
      if (bytes.contains(0)) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isBinary = true;
          });
        }
        return;
      }

      final text = utf8.decode(bytes, allowMalformed: true);
      final lines = const LineSplitter().convert(text);

      List<List<String>> csvRows = const [];
      if (widget.item.isCsv) {
        csvRows = _parseCsv(lines.take(150).toList());
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _content = text;
          _lines = lines;
          _csvRows = csvRows;
          _truncated = widget.item.bytes > maxBytes;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isBinary = true;
        });
      }
    }
  }

  List<List<String>> _parseCsv(List<String> rawLines) {
    if (rawLines.isEmpty) return const [];

    // Detecta o separador mais provável usando a primeira linha não vazia
    final first = rawLines.firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
    if (first.isEmpty) return const [];

    final separator = first.contains('\t')
        ? '\t'
        : (first.contains(';') && !first.contains(',') ? ';' : ',');

    final parsedRows = <List<String>>[];
    var maxCols = 0;

    for (final line in rawLines) {
      if (line.trim().isEmpty) continue;
      final cols = _splitCsvLine(line, separator);
      if (cols.length > maxCols) {
        maxCols = cols.length;
      }
      parsedRows.add(cols);
    }

    if (maxCols == 0) return const [];

    // IMPORTANTE: Normaliza o comprimento de todas as linhas adicionando células vazias.
    // Isso previne o erro "Table contains irregular row lengths" do Flutter Table.
    final normalized = <List<String>>[];
    for (final row in parsedRows) {
      final padded = List<String>.from(row);
      while (padded.length < maxCols) {
        padded.add('');
      }
      normalized.add(padded);
    }

    return normalized;
  }

  List<String> _splitCsvLine(String line, String separator) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == separator && !inQuotes) {
        result.add(buffer.toString().trim().replaceAll('"', ''));
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    result.add(buffer.toString().trim().replaceAll('"', ''));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: scheme.primary),
      );
    }

    if (_isBinary || _content == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.m),
            Text(
              'Arquivo binário ou codificação não suportada',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Barra de ferramentas do documento
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
                child: Text(
                  widget.item.extension.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                '${_lines.length} linhas',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_truncated) ...[
                const SizedBox(width: AppSpacing.s),
                Text(
                  '• Prévia parcial (primeiros 128 KB)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                ),
              ],
              const Spacer(),
              // Alternador de Visualização para CSV (Tabela / Texto)
              if (widget.item.isCsv && _csvRows.isNotEmpty) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Tabela', style: TextStyle(fontSize: 11)),
                      icon: Icon(Icons.table_chart_rounded, size: 13),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Texto', style: TextStyle(fontSize: 11)),
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
              ],
              PressableScale(
                scaleDown: 0.95,
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _content ?? ''));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Texto copiado para a área de transferência'),
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

        // Área de visualização (Tabela normalizada para CSV ou Texto com linhas numeradas)
        Expanded(
          child: widget.item.isCsv && _csvRows.isNotEmpty && !_showRaw
              ? _buildCsvTable(scheme)
              : _buildTextEditorView(scheme),
        ),
      ],
    );
  }

  Widget _buildCsvTable(ColorScheme scheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            children: [
              for (var r = 0; r < _csvRows.length; r++)
                TableRow(
                  decoration: BoxDecoration(
                    color: r == 0
                        ? scheme.primary.withValues(alpha: 0.1)
                        : (r.isEven
                            ? scheme.surfaceContainerLow.withValues(alpha: 0.5)
                            : scheme.surface),
                  ),
                  children: [
                    // Coluna número de linha
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${r + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    for (final cell in _csvRows[r])
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: Text(
                          cell,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: r == 0 ? FontWeight.bold : FontWeight.normal,
                            fontFamily: r == 0 ? null : 'monospace',
                            color: r == 0 ? scheme.primary : scheme.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextEditorView(ColorScheme scheme) {
    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Números de linha à esquerda
            SelectableText(
              List.generate(_lines.length, (i) => '${i + 1}').join('\n'),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.5,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Container(
              width: 1,
              height: _lines.length * 18.0,
              color: scheme.outlineVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(width: AppSpacing.m),
            // Conteúdo do texto
            Expanded(
              child: SelectableText(
                _content ?? '',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.5,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
