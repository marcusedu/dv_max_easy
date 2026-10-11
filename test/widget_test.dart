import 'package:dv_max_easy/app/dv_max_app.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sidebar lists sections and the window title', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DvMaxApp());

    expect(find.text('DV Max'), findsOneWidget);
    expect(find.text('Fila'), findsWidgets);
    expect(find.text('Concluídos'), findsOneWidget);
    expect(find.text('Cole ou solte um link para baixar.'), findsOneWidget);

    await tester.tap(find.text('Perfis'));
    await tester.pumpAndSettle();

    expect(find.text('Os perfis entram no próximo passo.'), findsOneWidget);
  });

  testWidgets('control 4 opens settings', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const DvMaxApp());
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pumpAndSettle();

    expect(find.text('Os ajustes entram no próximo passo.'), findsOneWidget);
  });
}
