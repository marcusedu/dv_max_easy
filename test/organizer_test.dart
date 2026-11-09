import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/organizer/domain/folder_report.dart';
import 'package:dv_max_easy/features/organizer/domain/target_folder_slot.dart';
import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';
import 'package:dv_max_easy/features/organizer/infrastructure/io_file_mover.dart';
import 'package:dv_max_easy/features/organizer/infrastructure/system_trash_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Classificação de Extensões', () {
    test('identifica corretamente vídeos', () {
      expect(classifyExtension('mp4'), FileCategory.video);
      expect(classifyExtension('.mkv'), FileCategory.video);
      expect(classifyExtension('MOV'), FileCategory.video);
      expect(classifyExtension('webm'), FileCategory.video);
    });

    test('identifica corretamente imagens', () {
      expect(classifyExtension('jpg'), FileCategory.image);
      expect(classifyExtension('.PNG'), FileCategory.image);
      expect(classifyExtension('webp'), FileCategory.image);
      expect(classifyExtension('gif'), FileCategory.image);
    });

    test('identifica áudios, instaladores e compactados', () {
      expect(classifyExtension('mp3'), FileCategory.audio);
      expect(classifyExtension('flac'), FileCategory.audio);
      expect(classifyExtension('dmg'), FileCategory.installer);
      expect(classifyExtension('exe'), FileCategory.installer);
      expect(classifyExtension('pkg'), FileCategory.installer);
      expect(classifyExtension('zip'), FileCategory.archive);
      expect(classifyExtension('tar.gz'), FileCategory.other);
      expect(classifyExtension('gz'), FileCategory.archive);
    });

    test('identifica arquivos de texto, CSV e documentos ricos', () {
      final txt = TriageItem(
        path: '/a/doc.txt',
        name: 'doc.txt',
        extension: 'txt',
        bytes: 100,
        modifiedAt: DateTime.now(),
        category: FileCategory.document,
      );
      expect(txt.isTextFile, isTrue);
      expect(txt.isCsv, isFalse);
      expect(txt.isRichDocument, isFalse);

      final md = txt.copyWith(name: 'README.md', extension: 'md');
      expect(md.isTextFile, isTrue);
      expect(md.isMarkdown, isTrue);

      final html = txt.copyWith(name: 'index.html', extension: 'html');
      expect(html.isTextFile, isTrue);
      expect(html.isHtml, isTrue);

      final csv = txt.copyWith(name: 'dados.csv', extension: 'csv');
      expect(csv.isTextFile, isTrue);
      expect(csv.isCsv, isTrue);

      final pdf = txt.copyWith(name: 'manual.pdf', extension: 'pdf');
      expect(pdf.isTextFile, isFalse);
      expect(pdf.isRichDocument, isTrue);

      final docx = txt.copyWith(name: 'contrato.docx', extension: 'docx');
      expect(docx.isRichDocument, isTrue);
    });
  });

  group('TriageItem e FolderReport', () {
    test('formata bytes adequadamente', () {
      final item1 = TriageItem(
        path: '/tmp/test.mp4',
        name: 'test.mp4',
        extension: 'mp4',
        bytes: 500,
        modifiedAt: DateTime.now(),
        category: FileCategory.video,
      );
      expect(item1.formatBytes(), '500 B');

      final item2 = item1.copyWith(bytes: 1024 * 1024 * 5); // 5 MB
      expect(item2.formatBytes(), '5.0 MB');

      final item3 = item1.copyWith(bytes: 1024 * 1024 * 1024 * 2); // 2 GB
      expect(item3.formatBytes(), '2.00 GB');
    });

    test('FolderReport agrega contagens e tamanhos', () {
      final items = [
        TriageItem(
          path: '/a/v1.mp4',
          name: 'v1.mp4',
          extension: 'mp4',
          bytes: 1000,
          modifiedAt: DateTime.now(),
          category: FileCategory.video,
        ),
        TriageItem(
          path: '/a/p1.png',
          name: 'p1.png',
          extension: 'png',
          bytes: 500,
          modifiedAt: DateTime.now(),
          category: FileCategory.image,
        ),
        TriageItem(
          path: '/a/setup.dmg',
          name: 'setup.dmg',
          extension: 'dmg',
          bytes: 2000,
          modifiedAt: DateTime.now(),
          category: FileCategory.installer,
        ),
      ];

      final report = FolderReport.fromItems(
        folderPath: '/a',
        items: items,
      );

      expect(report.totalFiles, 3);
      expect(report.totalBytes, 3500);
      expect(report.mediaItems.length, 2);
      expect(report.installerItems.length, 1);
      expect(report.countByCategory[FileCategory.video], 1);
      expect(report.countByCategory[FileCategory.image], 1);
      expect(report.countByCategory[FileCategory.installer], 1);
      expect(report.countByCategory[FileCategory.document], 0);
    });
  });

  group('Argumentos de Lixeira do SO (System Trash)', () {
    test('gera comando seguro para macOS com AppleScript argv', () {
      final args = trashArguments('/Users/user/Downloads/test.mp4', operatingSystem: 'macos');
      expect(args.first, 'osascript');
      expect(args, contains('set filePath to POSIX file (item 1 of argv)'));
      expect(args, contains('tell application "Finder" to delete filePath'));
      expect(args.last, '/Users/user/Downloads/test.mp4');
    });

    test('gera comando seguro para Windows com PowerShell', () {
      final args = trashArguments(r'C:\Downloads\test.mp4', operatingSystem: 'windows');
      expect(args.first, 'powershell');
      expect(args.any((a) => a.contains('SendToRecycleBin')), isTrue);
      final env = trashEnvironment(r'C:\Downloads\test.mp4', operatingSystem: 'windows');
      expect(env?['DVMAX_FILE'], r'C:\Downloads\test.mp4');
    });

    test('gera comando gio trash para Linux', () {
      final args = trashArguments('/home/user/Downloads/test.mp4', operatingSystem: 'linux');
      expect(args, ['gio', 'trash', '/home/user/Downloads/test.mp4']);
    });
  });

  group('TargetFolderSlot', () {
    test('cria slots iniciais com 4 primeiros configurados', () {
      final slots = createDefaultSlots(
        picturesPath: '/home/Pictures',
        moviesPath: '/home/Movies',
        musicPath: '/home/Music',
        documentsPath: '/home/Documents',
      );

      expect(slots.length, 9);
      expect(slots[0].slotNumber, 1);
      expect(slots[0].label, 'Fotos');
      expect(slots[0].path, '/home/Pictures');
      expect(slots[0].isConfigured, isTrue);

      expect(slots[1].slotNumber, 2);
      expect(slots[1].label, 'Vídeos');

      expect(slots[4].slotNumber, 5);
      expect(slots[4].isConfigured, isFalse);
    });

    test('serializa e desserializa JSON', () {
      const slot = TargetFolderSlot(
        slotNumber: 1,
        label: 'Projetos',
        path: '/tmp/projetos',
        iconName: 'folder',
      );

      final json = slot.toJson();
      final restored = TargetFolderSlot.fromJson(json);

      expect(restored.slotNumber, 1);
      expect(restored.label, 'Projetos');
      expect(restored.path, '/tmp/projetos');
      expect(restored.iconName, 'folder');
    });
  });

  group('Evitar Colisão de Nomes (uniqueDestinationPath)', () {
    test('preserva nome quando destino não existe', () {
      final path = uniqueDestinationPath('/nao_existe_dir_123', 'video.mp4');
      expect(path, '/nao_existe_dir_123/video.mp4');
    });
  });

  group('Sincronização de Caminho com Banco de Downloads (DownloadController)', () {
    test('atualiza outputPath do job baixado quando o arquivo é movido', () {
      final initialJob = DownloadJob(
        id: 'job_1',
        url: 'https://example.com/video',
        profileName: 'Filmes',
        running: false,
        outputPath: '/Users/test/Downloads/video.mp4',
      );
      final otherJob = DownloadJob(
        id: 'job_2',
        url: 'https://example.com/other',
        profileName: 'Música',
        running: false,
        outputPath: '/Users/test/Downloads/music.mp3',
      );

      final container = ProviderContainer(
        overrides: [
          initialDownloadsProvider.overrideWithValue([initialJob, otherJob]),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(downloadControllerProvider.notifier);

      // Move o arquivo para a pasta Filmes
      controller.updateOutputPath(
        oldPath: '/Users/test/Downloads/video.mp4',
        newPath: '/Users/test/Movies/video.mp4',
      );

      final jobs = container.read(downloadControllerProvider);
      final updatedJob = jobs.firstWhere((j) => j.id == 'job_1');
      final untouchedJob = jobs.firstWhere((j) => j.id == 'job_2');

      expect(updatedJob.outputPath, '/Users/test/Movies/video.mp4');
      expect(untouchedJob.outputPath, '/Users/test/Downloads/music.mp3');

      // Testa restauração (Desfazer / Undo)
      controller.updateOutputPath(
        oldPath: '/Users/test/Movies/video.mp4',
        newPath: '/Users/test/Downloads/video.mp4',
      );

      final restoredJob = container.read(downloadControllerProvider).firstWhere((j) => j.id == 'job_1');
      expect(restoredJob.outputPath, '/Users/test/Downloads/video.mp4');
    });
  });
}
