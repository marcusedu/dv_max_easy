import 'package:dv_max_easy/app/app_identity.dart';
import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/design/desktop_shell.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/features/settings/presentation/setup_screen.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      home: const SettingsGate(),
    );
  }
}

class SettingsGate extends ConsumerWidget {
  const SettingsGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return settings.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(body: Center(child: Text('$error'))),
      data: (view) =>
          view.binariesReady ? const DesktopShell() : const SetupScreen(),
    );
  }
}
