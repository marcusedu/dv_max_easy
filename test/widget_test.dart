import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/settings/domain/app_settings.dart';

import 'support/settings_harness.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sidebar lists sections and the window title', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
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

    await tester.tap(find.text('Perfis'));
    await tester.pumpAndSettle();

    expect(find.text('Filmes'), findsWidgets);
    expect(find.text('1080p · mkv'), findsOneWidget);
    expect(find.text('Só áudio · mp3'), findsOneWidget);
    expect(find.text('Qualidade'), findsOneWidget);
    expect(find.text('Taxa'), findsOneWidget);
    expect(find.text('Contêiner'), findsOneWidget);
    expect(find.text('Pasta deste perfil'), findsOneWidget);

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

    await tester.pumpWidget(
      appWithSettings(
        readySettings(),
        jobs: const [
          DownloadJob(
            id: '1',
            url: 'https://x.com/birinaite80/status/1',
            profileName: 'Filmes',
            running: false,
            detail: 'done',
            outputPath:
                '/Users/me/Downloads/Biri - Sabe pq o PT não vai virar.mkv',
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Biri - Sabe pq o PT não vai virar.mkv'), findsOneWidget);
    expect(
      find.text('/Users/me/Downloads/Biri - Sabe pq o PT não vai virar.mkv'),
      findsNothing,
    );
    expect(find.text('Abrir pasta'), findsOneWidget);
    expect(find.byTooltip('Abrir'), findsOneWidget);
    expect(find.text('Vídeo'), findsOneWidget);
    expect(find.text('mkv'), findsOneWidget);

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
}
