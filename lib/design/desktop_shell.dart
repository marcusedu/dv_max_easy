import 'package:dv_max_easy/app/app_identity.dart';
import 'package:dv_max_easy/app/shell_section.dart';
import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/downloads/presentation/queue_panel.dart';
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
  String _urlBefore = '';

  @override
  void initState() {
    super.initState();
    urlController.addListener(_onUrlEdited);
  }

  @override
  void dispose() {
    urlController.removeListener(_onUrlEdited);
    urlFocus.dispose();
    urlController.dispose();
    super.dispose();
  }

  void _onUrlEdited() {
    final next = urlController.text;
    if (looksLikePastedUrl(_urlBefore, next)) {
      _urlBefore = '';
      final url = next.trim();
      urlController.clear();
      _start(url);
      return;
    }
    _urlBefore = next;
  }

  void _start([String? raw]) {
    final url = (raw ?? urlController.text).trim();
    if (raw == null) {
      _urlBefore = '';
      urlController.clear();
    }
    ref.read(downloadControllerProvider.notifier).enqueue(url);
  }

  Future<void> _pasteAndStart() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final url = downloadUrl(field: urlController.text, clipboard: data?.text);
    if (url == null) {
      return;
    }
    _urlBefore = '';
    urlController.clear();
    _start(url);
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
    final version = ref
        .watch(settingsControllerProvider)
        .asData
        ?.value
        .ytDlpVersion;
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
            onInvoke: (_) {
              _start();
              return null;
            },
          ),
          CancelJobIntent: CallbackAction<CancelJobIntent>(
            onInvoke: (_) {
              ref.read(downloadControllerProvider.notifier).cancelNewest();
              return null;
            },
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
            body: Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Toolbar(
                        title: _sectionTitle(l10n),
                        status: version == null
                            ? l10n.binariesPending
                            : l10n.binariesReady(version),
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
                              urlFocus: urlFocus,
                              urlController: urlController,
                              onSubmit: _start,
                              onPaste: _pasteAndStart,
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
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
          child: Row(
            children: [
              Text(title, style: text.titleMedium),
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Text(status, style: text.bodySmall),
                ),
              ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.m,
                  AppSpacing.s,
                  AppSpacing.m,
                  AppSpacing.l,
                ),
                child: Text(
                  AppIdentity.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final (index, value) in ShellSection.values.indexed)
                _NavButton(
                  label: labels[index],
                  icon: _navIcons[index],
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

const _navIcons = [
  Icons.download_rounded,
  Icons.check_rounded,
  Icons.tune_rounded,
  Icons.settings_rounded,
];

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: InkWell(
          onTap: onPressed,
          hoverColor: scheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
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
    required this.urlFocus,
    required this.urlController,
    required this.onSubmit,
    required this.onPaste,
  });

  final ShellSection section;
  final FocusNode urlFocus;
  final TextEditingController urlController;
  final VoidCallback onSubmit;
  final Future<void> Function() onPaste;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: switch (section) {
        ShellSection.queue => QueuePanel(
          urlController: urlController,
          urlFocus: urlFocus,
          onSubmit: onSubmit,
          onPaste: onPaste,
        ),
        ShellSection.done => const CompletedPanel(),
        ShellSection.profiles => const ProfilesPage(),
        ShellSection.settings => const SettingsForm(),
      },
    );
  }
}
