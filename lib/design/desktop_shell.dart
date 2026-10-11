import 'package:dv_max_easy/app/app_identity.dart';
import 'package:dv_max_easy/app/shell_section.dart';
import 'package:dv_max_easy/app/window_drag.dart';
import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/clipboard_offer.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/application/library_query.dart';
import 'package:dv_max_easy/features/downloads/domain/download_plan.dart';
import 'package:dv_max_easy/features/downloads/infrastructure/system_clipboard.dart';
import 'package:dv_max_easy/features/downloads/presentation/download_status_bar.dart';
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

class DesktopShellState extends ConsumerState<DesktopShell>
    with WidgetsBindingObserver {
  ShellSection section = ShellSection.queue;
  final urlFocus = FocusNode();
  final urlController = TextEditingController();
  String _urlBefore = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowChannel.setMethodCallHandler((call) async {
      if (call.method == 'focus') {
        await _offerClipboard();
      }
    });
    urlController.addListener(_onUrlEdited);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _offerClipboard();
      ref.read(downloadControllerProvider.notifier).purgeExpired();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    windowChannel.setMethodCallHandler(null);
    urlController.removeListener(_onUrlEdited);
    urlFocus.dispose();
    urlController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _offerClipboard();
    }
  }

  Future<void> _offerClipboard() async {
    final settings = ref.read(settingsControllerProvider).asData?.value;
    if (settings == null) {
      return;
    }
    final text = await ref.read(clipboardReaderProvider).readText();
    if (!mounted) {
      return;
    }
    ref
        .read(clipboardOfferProvider.notifier)
        .offer(text, enabled: settings.settings.clipboardPromptEnabled);
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
    final data = await ref.read(clipboardReaderProvider).readText();
    final url = downloadUrl(field: urlController.text, clipboard: data);
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
    ref.listen(settingsControllerProvider, (previous, next) {
      if (next.hasValue && previous?.hasValue != true) {
        _offerClipboard();
      }
    });
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
            onInvoke: (_) {
              ref.read(clipboardOfferProvider.notifier).dismiss();
              return null;
            },
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
                _TitleBar(
                  status: version == null
                      ? l10n.binariesPending
                      : l10n.binariesReady(version),
                  onSettings: () => _select(ShellSection.settings),
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
                              urlFocus: urlFocus,
                              urlController: urlController,
                              onSubmit: _start,
                              onPaste: _pasteAndStart,
                              onDownload: _start,
                              onOpenCompleted: (url) {
                                ref
                                    .read(libraryQueryProvider.notifier)
                                    .focusUrl(url);
                                _select(ShellSection.done);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const DownloadStatusBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.status, required this.onSettings});

  final String status;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SizedBox(
        height: mac ? 40 : 48,
        child: Padding(
          padding: EdgeInsets.only(left: mac ? 78 : 16, right: 4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => beginWindowDrag(),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppIdentity.displayName,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              Text(status, style: text.bodySmall),
              IconButton(
                tooltip: l10n.navSettings,
                onPressed: onSettings,
                icon: Icon(
                  Icons.settings_outlined,
                  size: 18,
                  color: scheme.onSurfaceVariant,
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
                  style: pageTitle(scheme.onSurface).copyWith(fontSize: 22),
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
  Icons.check_circle_outline,
  Icons.layers_outlined,
  Icons.settings_outlined,
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
    final dark = scheme.brightness == Brightness.dark;
    final color = selected ? scheme.onSurface : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? (dark
                  ? const Color(0xFF143844)
                  : scheme.primary.withValues(alpha: 0.14))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        child: InkWell(
          onTap: onPressed,
          hoverColor: scheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? scheme.primary : color,
                  ),
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
    required this.onDownload,
    required this.onOpenCompleted,
  });

  final ShellSection section;
  final FocusNode urlFocus;
  final TextEditingController urlController;
  final VoidCallback onSubmit;
  final Future<void> Function() onPaste;
  final ValueChanged<String> onDownload;
  final ValueChanged<String> onOpenCompleted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: switch (section) {
        ShellSection.queue => QueuePanel(
          urlController: urlController,
          urlFocus: urlFocus,
          onSubmit: onSubmit,
          onPaste: onPaste,
          onDownload: onDownload,
          onOpenCompleted: onOpenCompleted,
        ),
        ShellSection.done => _Page(
          title: l10n.navDone,
          child: const CompletedPanel(),
        ),
        ShellSection.profiles => _Page(
          title: l10n.navProfiles,
          child: const ProfilesPage(),
        ),
        ShellSection.settings => _Page(
          title: l10n.navSettings,
          child: const SettingsForm(),
        ),
      },
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: pageTitle(Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: AppSpacing.l),
        Expanded(child: child),
      ],
    );
  }
}
