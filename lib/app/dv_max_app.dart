import 'package:dv_max_easy/app/app_identity.dart';
import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/design/desktop_shell.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class DvMaxApp extends StatelessWidget {
  const DvMaxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppIdentity.displayName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // O ARB é `pt` porque o gen-l10n exige o locale base.
      // O ajuste persiste a etiqueta pt-BR.
      locale: const Locale('pt'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const DesktopShell(),
    );
  }
}
