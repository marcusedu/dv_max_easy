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
