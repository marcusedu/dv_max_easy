import 'dart:io';

import 'package:dv_max_easy/features/downloads/domain/batch_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseBatchFileContent', () {
    test('extracts clean urls and ignores comments and blank lines', () {
      const content = '''
# Lista de vídeos favoritos
https://www.youtube.com/watch?v=dQw4w9WgXcQ
; comentário estilo ini
https://youtu.be/abc123xyz00

] outro comentário aceito pelo yt-dlp
https://vimeo.com/123456789 # link com comentário no final

# Linha duplicada abaixo:
https://www.youtube.com/watch?v=dQw4w9WgXcQ
not-a-valid-url
''';

      final urls = parseBatchFileContent(content);
      expect(urls, [
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
        'https://youtu.be/abc123xyz00',
        'https://vimeo.com/123456789',
      ]);
    });

    test('returns empty list when file contains no valid urls', () {
      const content = '''
# Apenas comentários
; nada aqui
texto aleatório sem protocolo
''';
      expect(parseBatchFileContent(content), isEmpty);
    });
  });

  group('localBatchFilePath', () {
    test('identifies txt paths and expands home directory', () {
      expect(
        localBatchFilePath('~/Downloads/links.txt', home: '/Users/test'),
        '/Users/test/Downloads/links.txt',
      );
      expect(
        localBatchFilePath('/tmp/batch.txt', home: '/Users/test'),
        '/tmp/batch.txt',
      );
    });

    test('accepts file:// URIs pointing to txt files', () {
      expect(
        localBatchFilePath('file:///tmp/urls.txt', home: '/Users/test'),
        '/tmp/urls.txt',
      );
    });

    test('rejects non-txt files and web urls', () {
      expect(
        localBatchFilePath('https://example.com/links.txt', home: '/Users/test'),
        isNull,
      );
      expect(
        localBatchFilePath('/tmp/video.mp4', home: '/Users/test'),
        isNull,
      );
    });
  });

  group('readBatchFile', () {
    test('reads existing file and extracts urls', () async {
      final tempDir = await Directory.systemTemp.createTemp('batch_test_');
      addTearDown(() => tempDir.delete(recursive: true));

      final file = File('${tempDir.path}/links.txt');
      await file.writeAsString(
        '# Header\nhttps://example.com/1\nhttps://example.com/2\n',
      );

      final urls = await readBatchFile(file);
      expect(urls, ['https://example.com/1', 'https://example.com/2']);
    });

    test('returns empty list for non-existent file', () async {
      final urls = await readBatchFile(File('/non/existent/path/file.txt'));
      expect(urls, isEmpty);
    });
  });
}
