import 'dart:convert';
import 'dart:io';

import 'package:dv_max_easy/core/clock.dart';
import 'package:dv_max_easy/core/log.dart';
import 'package:path/path.dart' as p;

final class JsonRead {
  const JsonRead(this.document, {this.backupPath});

  final Map<String, dynamic>? document;
  final String? backupPath;

  bool get isEmpty => document == null;
}

/// Lê JSON com `schemaVersion` e grava em arquivo temporário antes de trocar.
final class JsonFile {
  JsonFile({required this.file, required this.clock, required this.log});

  final File file;
  final Clock clock;
  final Log log;

  Future<JsonRead> read({required int schemaVersion}) async {
    if (!await file.exists()) {
      return const JsonRead(null);
    }
    Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } on FormatException catch (error) {
      log.error('json inválido', cause: error);
      return _preserveAndClear();
    }
    if (decoded is! Map || decoded['schemaVersion'] != schemaVersion) {
      log.info('schemaVersion inesperada em ${p.basename(file.path)}');
      return _preserveAndClear();
    }
    return JsonRead(Map<String, dynamic>.from(decoded));
  }

  Future<void> write(Map<String, dynamic> document) async {
    final encoded = jsonEncode(document);
    final temp = File('${file.path}.tmp');
    await temp.parent.create(recursive: true);
    await temp.writeAsString(encoded, flush: true);
    if (await file.exists()) {
      final previous = File('${file.path}.replacing');
      if (await previous.exists()) {
        await previous.delete();
      }
      await file.rename(previous.path);
      try {
        await temp.rename(file.path);
      } catch (error) {
        await previous.rename(file.path);
        log.error('troca do json falhou', cause: error);
        rethrow;
      }
      await previous.delete();
      return;
    }
    await temp.rename(file.path);
  }

  Future<JsonRead> _preserveAndClear() async {
    final backup = File(
      '${file.path}.bak-${clock.now().millisecondsSinceEpoch}',
    );
    await file.rename(backup.path);
    return JsonRead(null, backupPath: backup.path);
  }
}
