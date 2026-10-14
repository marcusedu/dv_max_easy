import 'package:dv_max_easy/features/downloads/domain/cut_plan.dart';
import 'package:dv_max_easy/features/downloads/presentation/cut_editor.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/features/settings/domain/app_settings.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/settings_harness.dart';

Widget _buildCutEditor({
  required String path,
  MediaFacts? facts,
}) {
  return ProviderScope(
    overrides: [
      settingsStoreProvider.overrideWithValue(
        MemorySettingsStore(
          const AppSettings(
            defaultDownloadFolder: '/Users/me/Movies',
            uiLanguage: 'pt-BR',
            ytDlpPath: '/usr/local/bin/yt-dlp',
            ffmpegPath: '/usr/local/bin/ffmpeg',
          ),
        ),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('pt', 'BR'),
      home: CutEditorPage(
        path: path,
        initialFacts: facts,
      ),
    ),
  );
}

void main() {
  testWidgets('cut editor renders media facts, visual timeline, and initial values', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildCutEditor(
        path: '/tmp/meu_video.mp4',
        facts: const MediaFacts(
          duration: Duration(minutes: 5), // 05:00
          audio: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Header & media info
    expect(find.text('Cortar vídeo'), findsOneWidget);
    expect(find.text('meu_video.mp4'), findsOneWidget);
    expect(find.text('/tmp/meu_video.mp4'), findsOneWidget);
    expect(find.text('05:00'), findsWidgets);
    expect(find.text('Com áudio'), findsOneWidget);

    // 2. Timeline card & legends
    expect(find.text('Linha do tempo'), findsOneWidget);
    expect(find.text('Mantido'), findsOneWidget);
    expect(find.text('Removido'), findsNWidgets(2));
    expect(find.text('Seleção'), findsOneWidget);

    // 3. Range slider
    expect(find.byType(RangeSlider), findsOneWidget);

    // 4. Time inputs
    expect(find.text('00:00'), findsWidgets);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Fim'), findsOneWidget);

    // 5. Action buttons
    expect(find.text('Tirar trecho'), findsOneWidget);
    expect(find.text('Ficar só com este trecho'), findsOneWidget);

    // 6. Stats card initial state
    expect(find.text('Duração original'), findsOneWidget);
    expect(find.text('Duração final'), findsOneWidget);

    // 7. Output preview card
    expect(find.text('Salvar como'), findsOneWidget);
    expect(find.text('meu_video-corte.mp4'), findsOneWidget);
    expect(find.text('Salvar novo vídeo'), findsOneWidget);
  });

  testWidgets('stepper buttons adjust start and end times smoothly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildCutEditor(
        path: '/tmp/video.mp4',
        facts: const MediaFacts(
          duration: Duration(minutes: 2), // 02:00
          audio: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check Sem áudio
    expect(find.text('Sem áudio'), findsOneWidget);

    // Click '+5s' on Start stepper
    final plus5Buttons = find.widgetWithText(OutlinedButton, '+5s');
    await tester.tap(plus5Buttons.first); // start stepper
    await tester.pumpAndSettle();

    expect(find.text('00:05'), findsOneWidget);

    // Click '+1s' on Start stepper
    final plus1Buttons = find.widgetWithText(OutlinedButton, '+1s');
    await tester.tap(plus1Buttons.first);
    await tester.pumpAndSettle();

    expect(find.text('00:06'), findsOneWidget);

    // Click 'Início' button to reset start to 00:00
    await tester.tap(find.widgetWithText(OutlinedButton, 'Início'));
    await tester.pumpAndSettle();

    expect(find.text('00:00'), findsWidgets);

    // Click '-5s' on End stepper
    final minus5Buttons = find.widgetWithText(OutlinedButton, '-5s');
    await tester.tap(minus5Buttons.last);
    await tester.pumpAndSettle();

    expect(find.text('01:55'), findsOneWidget);

    // Click 'Fim' button to reset end to 02:00
    await tester.tap(find.widgetWithText(OutlinedButton, 'Fim'));
    await tester.pumpAndSettle();

    expect(find.text('02:00'), findsWidgets);
  });

  testWidgets('adding and deleting cuts updates stats and segment list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildCutEditor(
        path: '/tmp/video.mp4',
        facts: const MediaFacts(
          duration: Duration(minutes: 5), // 05:00
          audio: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially, no cuts added
    expect(find.text('Nenhum trecho marcado para remoção.'), findsOneWidget);

    // Adjust start to 00:10
    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, '00:10');
    // Adjust end to 00:40
    await tester.enterText(textFields.last, '00:40');
    await tester.pumpAndSettle();

    // Tap 'Tirar trecho'
    await tester.tap(find.text('Tirar trecho'));
    await tester.pumpAndSettle();

    // Now removed list contains the cut
    expect(find.text('1 trecho a remover'), findsOneWidget);
    expect(find.text('00:10  →  00:40'), findsOneWidget);
    expect(find.text('-00:30'), findsNWidgets(2)); // Segment pill + Stats card
    expect(find.text('04:30'), findsOneWidget);
    expect(find.textContaining('2 partes unidas'), findsOneWidget);

    // Delete the cut via trash icon
    final deleteButton = find.byIcon(Icons.delete_outline);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Reverts to no cuts
    expect(find.text('Nenhum trecho marcado para remoção.'), findsOneWidget);
  });

  testWidgets('keep only selected range trims ends and can be cleared', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildCutEditor(
        path: '/tmp/filme.mp4',
        facts: const MediaFacts(
          duration: Duration(minutes: 10), // 10:00
          audio: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFields = find.byType(TextField);
    await tester.enterText(textFields.first, '01:00');
    await tester.enterText(textFields.last, '03:00');
    await tester.pumpAndSettle();

    // Tap 'Ficar só com este trecho'
    await tester.tap(find.text('Ficar só com este trecho'));
    await tester.pumpAndSettle();

    // Result should keep only 01:00-03:00 (duration: 02:00)
    // Removed is 08:00 (00:00-01:00 and 03:00-10:00)
    expect(find.text('2 trechos a remover'), findsOneWidget);
    expect(find.text('02:00'), findsWidgets);
    expect(find.text('-08:00'), findsOneWidget);

    // Top bar now shows 'Limpar cortes' button
    expect(find.text('Limpar cortes'), findsWidgets);
    await tester.tap(find.text('Limpar cortes').first);
    await tester.pumpAndSettle();

    // All cuts cleared
    expect(find.text('Nenhum trecho marcado para remoção.'), findsOneWidget);
    expect(find.text('10:00'), findsWidgets);
  });
}
