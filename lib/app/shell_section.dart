import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellSection { queue, done, gallery, convert, profiles, settings }

final shellSectionProvider =
    NotifierProvider<ShellSectionNotifier, ShellSection>(
      ShellSectionNotifier.new,
    );

final class ShellSectionNotifier extends Notifier<ShellSection> {
  @override
  ShellSection build() => ShellSection.queue;

  void select(ShellSection section) => state = section;
}

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
