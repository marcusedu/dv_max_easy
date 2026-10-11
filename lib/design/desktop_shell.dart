import 'package:dv_max_easy/app/app_identity.dart';
import 'package:dv_max_easy/app/shell_section.dart';
import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/profiles/presentation/profiles_page.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/features/settings/presentation/settings_form.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => DesktopShellState();
}

class DesktopShellState extends ConsumerState<DesktopShell> {
  ShellSection section = ShellSection.queue;
  final urlFocus = FocusNode();
  final urlController = TextEditingController();

  @override
  void dispose() {
    urlFocus.dispose();
    urlController.dispose();
    super.dispose();
  }

  bool get _meta =>
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;

  SingleActivator _mod(LogicalKeyboardKey key) {
    return SingleActivator(key, meta: _meta, control: !_meta);
  }

  void _select(ShellSection next) {
    setState(() => section = next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final version = ref.watch(settingsControllerProvider).asData?.value.ytDlpVersion;
    return Shortcuts(
      shortcuts: {
        _mod(LogicalKeyboardKey.keyL): const FocusUrlIntent(),
        _mod(LogicalKeyboardKey.enter): const DownloadIntent(),
        _mod(LogicalKeyboardKey.comma): const OpenSettingsIntent(),
        _mod(LogicalKeyboardKey.digit1): const SelectSectionIntent(
          ShellSection.queue,
        ),
        _mod(LogicalKeyboardKey.digit2): const SelectSectionIntent(
          ShellSection.done,
        ),
        _mod(LogicalKeyboardKey.digit3): const SelectSectionIntent(
          ShellSection.profiles,
        ),
        _mod(LogicalKeyboardKey.digit4): const SelectSectionIntent(
          ShellSection.settings,
        ),
        _mod(LogicalKeyboardKey.period): const CancelJobIntent(),
        const SingleActivator(LogicalKeyboardKey.escape):
            const DismissBannerIntent(),
      },
      child: Actions(
        actions: {
          FocusUrlIntent: CallbackAction<FocusUrlIntent>(
            onInvoke: (_) {
              urlFocus.requestFocus();
              return null;
            },
          ),
          DownloadIntent: CallbackAction<DownloadIntent>(
            onInvoke: (_) => null,
          ),
          CancelJobIntent: CallbackAction<CancelJobIntent>(
            onInvoke: (_) => null,
          ),
          DismissBannerIntent: CallbackAction<DismissBannerIntent>(
            onInvoke: (_) => null,
          ),
          OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
            onInvoke: (_) {
              _select(ShellSection.settings);
              return null;
            },
          ),
          SelectSectionIntent: CallbackAction<SelectSectionIntent>(
            onInvoke: (intent) {
              _select(intent.section);
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: scheme.surface,
            body: Column(
              children: [
                _Toolbar(
                  title: _sectionTitle(l10n),
                  status: version == null
                      ? l10n.binariesPending
                      : l10n.binariesReady(version),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Sidebar(
                        section: section,
                        onSelect: _select,
                        labels: [
                          l10n.navQueue,
                          l10n.navDone,
                          l10n.navProfiles,
                          l10n.navSettings,
                        ],
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: AppSpacing.motion,
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeOut,
                          child: KeyedSubtree(
                            key: ValueKey(section),
                            child: _SectionBody(
                              section: section,
                              l10n: l10n,
                              urlFocus: urlFocus,
                              urlController: urlController,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _sectionTitle(AppLocalizations l10n) {
    return switch (section) {
      ShellSection.queue => l10n.navQueue,
      ShellSection.done => l10n.navDone,
      ShellSection.profiles => l10n.navProfiles,
      ShellSection.settings => l10n.navSettings,
    };
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({required this.title, required this.status});

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        height: 52,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Row(
            children: [
              Text(AppIdentity.displayName, style: text.titleLarge),
              const SizedBox(width: AppSpacing.l),
              Text(title, style: text.titleMedium),
              const Spacer(),
              Text(status, style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.section,
    required this.onSelect,
    required this.labels,
  });

  final ShellSection section;
  final ValueChanged<ShellSection> onSelect;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        width: AppSpacing.sidebar,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s,
            vertical: AppSpacing.m,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, value) in ShellSection.values.indexed)
                _NavButton(
                  label: labels[index],
                  selected: section == value,
                  onPressed: () => onSelect(value),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: Material(
        color: selected ? scheme.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.hit),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({
    required this.section,
    required this.l10n,
    required this.urlFocus,
    required this.urlController,
  });

  final ShellSection section;
  final AppLocalizations l10n;
  final FocusNode urlFocus;
  final TextEditingController urlController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: switch (section) {
        ShellSection.queue => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(l10n.dropHint, style: text.bodyMedium),
              ),
            ),
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: urlController,
              focusNode: urlFocus,
              decoration: InputDecoration(hintText: l10n.urlHint),
              style: text.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.m),
            Text(l10n.queueEmpty, style: text.bodySmall),
          ],
        ),
        ShellSection.done => Text(l10n.doneEmpty, style: text.bodyMedium),
        ShellSection.profiles => const ProfilesPage(),
        ShellSection.settings => const SettingsForm(),
      },
    );
  }
}
