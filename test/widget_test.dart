import 'dart:io';

import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/settings/domain/app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/settings_harness.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sidebar lists sections and the window title', (tester) async {
    tester.view.physicalSize = const Size(1200, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(appWithSettings(readySettings()));
    await tester.pumpAndSettle();

    expect(find.text('DV Max'), findsNWidgets(2));
    expect(find.text('Fila'), findsWidgets);
    expect(find.text('Concluídos'), findsOneWidget);
    expect(
      find.text('Baixe vídeos e áudios de redes sociais com facilidade.'),
      findsOneWidget,
    );
    expect(find.text('Arraste um link ou cole aqui'), findsNothing);
    expect(find.text('Perfil ativo'), findsOneWidget);
    expect(find.text('Filmes'), findsOneWidget);
    expect(find.text('Baixar'), findsOneWidget);
    expect(find.text('Nada baixando'), findsOneWidget);
    expect(find.textContaining('0 arquivos'), findsOneWidget);
    expect(find.textContaining('50,0 GB livres'), findsOneWidget);

    await tester.tap(find.text('Filmes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Música').last);
    await tester.pumpAndSettle();
    expect(find.text('Música'), findsOneWidget);
    expect(find.text('Filmes'), findsNothing);

    await tester.tap(find.text('Perfis'));
    await tester.pumpAndSettle();

    expect(find.text('Filmes'), findsWidgets);
    expect(find.text('1080p · mkv'), findsOneWidget);
    expect(find.text('Só áudio · mp3'), findsOneWidget);
    expect(find.text('Qualidade'), findsOneWidget);
    expect(find.text('Taxa'), findsOneWidget);
    expect(find.text('Contêiner'), findsOneWidget);
    expect(find.text('Pasta deste perfil'), findsOneWidget);
    expect(find.text('Apagar o arquivo'), findsOneWidget);

    final films = tester.getRect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'Filmes',
      ),
    );
    final add = tester.getRect(find.text('Novo perfil'));
    expect(add.top, greaterThan(films.bottom + 12));

    final save = tester.getRect(find.text('Salvar perfil'));
    final delete = tester.getRect(find.text('Apagar'));
    expect(delete.left, greaterThan(save.right + 24));
    expect(
      save.top,
      greaterThan(tester.getRect(find.text('Qualidade')).bottom),
    );
  });

  testWidgets('a finished file offers open, copy, reveal and share', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final directory = Directory.systemTemp.createTempSync('dv-card');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/Biri - Sabe pq o PT não vai virar.mkv')
      ..writeAsStringSync('video');
    await tester.pumpWidget(
      appWithSettings(
        readySettings(),
        jobs: [
          DownloadJob(
            id: '1',
            url: 'https://x.com/birinaite80/status/1',
            profileName: 'Filmes',
            running: false,
            detail: 'done',
            outputPath: file.path,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Biri - Sabe pq o PT não vai virar.mkv'), findsOneWidget);
    expect(find.text(file.path), findsNothing);
    expect(find.text('Abrir pasta'), findsOneWidget);
    expect(find.byTooltip('Abrir'), findsOneWidget);
    expect(find.byTooltip('Abrir no navegador'), findsOneWidget);
    expect(find.text('Cortar'), findsOneWidget);
    expect(find.text('Vídeo'), findsOneWidget);
    expect(find.text('mkv'), findsOneWidget);

    await tester.tap(
      find.text('https://x.com/birinaite80/status/1'),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
    expect(find.text('Abrir pasta'), findsNWidgets(2));

    await tester.tapAt(const Offset(420, 160));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);

    await tester.tapAt(const Offset(420, 160));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluídos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('control 4 opens settings', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(appWithSettings(readySettings()));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    expect(find.text('Pasta padrão'), findsOneWidget);
  });

  testWidgets('a copied link is offered once and does not start alone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      appWithSettings(readySettings(), clipboard: 'https://example.com/video'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tem um link copiado'), findsOneWidget);
    expect(find.text('https://example.com/video'), findsOneWidget);
    expect(find.text('Downloads'), findsNothing);

    await tester.tap(find.text('Agora não'));
    await tester.pumpAndSettle();
    expect(find.text('Tem um link copiado'), findsNothing);
  });

  testWidgets('a filename error explains itself and offers retry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      appWithSettings(
        readySettings(),
        jobs: const [
          DownloadJob(
            id: '1',
            url: 'https://x.com/a/status/1',
            profileName: 'Filmes',
            running: false,
            error: 'filename_too_long',
            errorDetail: 'ERROR: [Errno 63] File name too long',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('nome do arquivo'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
    expect(find.textContaining('Errno 63'), findsNothing);
  });

  testWidgets('missing binaries replace the shell', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(appWithSettings(const AppSettings()));
    await tester.pumpAndSettle();

    expect(find.text('Fila'), findsNothing);
    expect(
      find.text('Para baixar, aponte o yt-dlp e o FFmpeg.'),
      findsOneWidget,
    );
  });

  testWidgets('the queue keeps ten cards and completed can filter the rest', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final jobs = [
      for (var index = 0; index < 11; index++)
        DownloadJob(
          id: '$index',
          url: index == 3
              ? 'https://music.example/song'
              : 'https://videos.example/$index',
          profileName: index == 3 ? 'Música' : 'Filmes',
          running: false,
          detail: 'done',
          containerLabel: index == 3 ? 'mp3' : 'mkv',
          outputPath: '/tmp/$index.${index == 3 ? 'mp3' : 'mkv'}',
        ),
    ];

    await tester.pumpWidget(appWithSettings(readySettings(), jobs: jobs));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A fila mostra os 10 mais recentes. O restante está em Concluídos.',
      ),
      findsOneWidget,
    );
    expect(find.text('https://videos.example/10'), findsNothing);
    expect(find.text('https://videos.example/0'), findsOneWidget);

    await tester.tap(find.text('Concluídos'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'videos.example/10');
    await tester.pumpAndSettle();
    expect(find.text('https://videos.example/10'), findsOneWidget);
    expect(find.text('https://videos.example/0'), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tipo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('mp3').last);
    await tester.pumpAndSettle();
    expect(find.text('https://music.example/song'), findsOneWidget);
    expect(find.text('https://videos.example/0'), findsNothing);
  });

  testWidgets('a missing file is faded and can be downloaded again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      appWithSettings(
        readySettings(),
        jobs: const [
          DownloadJob(
            id: 'gone',
            url: 'https://x.com/status/gone',
            profileName: 'Filmes',
            running: false,
            detail: 'done',
            outputPath: '/tmp/dv-max-missing-file.mkv',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('O arquivo não está mais na pasta em que foi salvo.'),
      findsOneWidget,
    );
    expect(find.text('Baixar de novo'), findsOneWidget);
    expect(find.byTooltip('Abrir'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Opacity && widget.opacity == 0.55,
      ),
      findsOneWidget,
    );
  });

  testWidgets('a repeated link opens the earlier download in completed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const repeated = 'https://x.com/status/again';
    const other = 'https://vimeo.com/other';

    await tester.pumpWidget(
      appWithSettings(
        readySettings(),
        jobs: const [
          DownloadJob(
            id: '1',
            url: repeated,
            profileName: 'Filmes',
            running: false,
            detail: 'done',
            outputPath: '/tmp/again.mkv',
          ),
          DownloadJob(
            id: '2',
            url: other,
            profileName: 'Filmes',
            running: false,
            detail: 'done',
            outputPath: '/tmp/other.mkv',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    ProviderScope.containerOf(tester.element(find.text('Perfil ativo')))
        .read(duplicateNoticeProvider.notifier)
        .show('1');
    await tester.pumpAndSettle();

    expect(find.text('Este link já foi baixado'), findsOneWidget);
    await tester.tap(find.text('Ver nos concluídos'));
    await tester.pumpAndSettle();
    expect(find.text(repeated), findsWidgets);
    expect(find.text(other), findsNothing);
    expect(find.text('Este link já foi baixado'), findsNothing);
  });

  testWidgets('a profile deadline shows a clock and one file can be kept', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = Directory.systemTemp.createTempSync('dv-keep');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/song.mp3')..writeAsStringSync('mp3');

    await tester.pumpWidget(
      appWithSettings(
        readySettings(),
        profiles: [musicPreset().copyWith(deleteAfterDays: 2), filmsPreset()],
        jobs: [
          DownloadJob(
            id: 'song',
            url: 'https://music.example/song',
            profileName: 'Música',
            running: false,
            detail: 'done',
            audio: true,
            containerLabel: 'mp3',
            outputPath: file.path,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Apaga em'), findsOneWidget);
    expect(find.textContaining('Baixado em'), findsOneWidget);
    expect(file.existsSync(), isTrue);

    await tester.tap(
      find.text('https://music.example/song'),
      buttons: kSecondaryMouseButton,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manter este arquivo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Apaga em'), findsNothing);
    expect(file.existsSync(), isTrue);
  });

  testWidgets('opening the app deletes a file past the profile deadline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = Directory.systemTemp.createTempSync('dv-open-purge');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File('${directory.path}/old.mkv')..writeAsStringSync('old');
    file.setLastModifiedSync(DateTime.now().subtract(const Duration(days: 5)));

    await tester.pumpWidget(
      appWithSettings(
        readySettings(),
        profiles: [filmsPreset().copyWith(deleteAfterDays: 2)],
        jobs: [
          DownloadJob(
            id: 'old',
            url: 'https://videos.example/old',
            profileName: 'Filmes',
            running: false,
            detail: 'done',
            outputPath: file.path,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    expect(file.existsSync(), isFalse);
    expect(
      find.text('O app apagou este arquivo. O histórico fica.'),
      findsOneWidget,
    );
    expect(find.text('https://videos.example/old'), findsOneWidget);
  });
}
