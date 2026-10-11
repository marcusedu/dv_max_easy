import 'package:flutter/widgets.dart';

enum ShellSection { queue, done, profiles, settings }

class FocusUrlIntent extends Intent {
  const FocusUrlIntent();
}

class DownloadIntent extends Intent {
  const DownloadIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class SelectSectionIntent extends Intent {
  const SelectSectionIntent(this.section);

  final ShellSection section;
}

class CancelJobIntent extends Intent {
  const CancelJobIntent();
}

class DismissBannerIntent extends Intent {
  const DismissBannerIntent();
}
