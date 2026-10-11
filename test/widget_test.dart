import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/settings/domain/app_settings.dart';

import 'support/settings_harness.dart';

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

    expect(find.text('DV Max'), findsOneWidget);
    expect(find.text('Fila'), findsWidgets);
    expect(find.text('Concluídos'), findsOneWidget);
    expect(find.text('Cole ou solte um link para baixar.'), findsOneWidget);

    await tester.tap(find.text('Perfis'));
    await tester.pumpAndSettle();

    expect(find.text('Filmes'), findsWidgets);
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
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('Mostrar na pasta'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);

    await tester.tap(find.text('Concluídos'));
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
