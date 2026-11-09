import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/json_job_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Tags parsing & persistence', () {
    test('parseTags handles hashes, commas, spaces, uppercase, and deduplicates', () {
      final tags = parseTags('#engracado, #Politica meme #engracado');
      expect(tags, equals(['#engracado', '#politica', '#meme']));
    });

    test('parseTags adds hash prefix if missing', () {
      final tags = parseTags('musica tutorial');
      expect(tags, equals(['#musica', '#tutorial']));
    });

    test('DownloadJob stores tags and serializes to and from json', () {
      const job = DownloadJob(
        id: 'job_1',
        url: 'https://youtube.com/watch?v=123',
        profileName: 'Filmes',
        running: false,
        tags: ['#perfil:filmes', '#engracado', '#politica'],
      );

      final json = jobToJson(job);
      expect(json['tags'], equals(['#perfil:filmes', '#engracado', '#politica']));

      final restored = jobFromJson(json);
      expect(restored, isNotNull);
      expect(restored!.tags, equals(['#perfil:filmes', '#engracado', '#politica']));
    });
  });
}
