import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';

/// Analisa o conteúdo de um arquivo de texto no formato aceito pelo yt-dlp (-a / --batch-file).
///
/// Arquivo contendo URLs, uma por linha.
/// Linhas iniciadas com '#', ';' ou ']' são comentários e são ignoradas.
/// Linhas vazias são ignoradas.
/// URLs válidas (http/https) são extraídas e deduplicadas preservando a ordem.
List<String> parseBatchFileContent(String content) {
  final lines = const LineSplitter().convert(content);
  final urls = <String>[];
  final seen = <String>{};
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty ||
        line.startsWith('#') ||
        line.startsWith(';') ||
        line.startsWith(']')) {
      continue;
    }
    final match = RegExp(r'https?://[^\s#;]+').firstMatch(line);
    if (match != null) {
      final candidate = match.group(0)!;
      if (isHttpUrl(candidate) && seen.add(candidate)) {
        urls.add(candidate);
      }
    }
  }
  return urls;
}

/// Identifica se um caminho ou texto se refere a um arquivo local de lista (.txt).
String? localBatchFilePath(String raw, {required String home}) {
  final clean = raw.trim();
  if (clean.isEmpty ||
      clean.startsWith('http://') ||
      clean.startsWith('https://')) {
    return null;
  }
  String path = clean;
  if (path.startsWith('file://')) {
    final uri = Uri.tryParse(path);
    if (uri != null) {
      try {
        path = uri.toFilePath();
      } on Object {
        // Ignora URI malformado.
      }
    }
  }
  if (path.startsWith('~/') && home.isNotEmpty) {
    path = '$home/${path.substring(2)}';
  }
  if (path.toLowerCase().endsWith('.txt')) {
    return path;
  }
  return null;
}

/// Lê um arquivo local e extrai os links se ele existir.
Future<List<String>> readBatchFile(File file) async {
  if (!await file.exists()) {
    return const [];
  }
  try {
    final content = await file.readAsString();
    return parseBatchFileContent(content);
  } on Object {
    return const [];
  }
}
