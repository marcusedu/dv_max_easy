import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/settings/presentation/settings_form.dart';
import 'package:flutter/material.dart';

class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: const SettingsForm(showIntro: true),
      ),
    );
  }
}
