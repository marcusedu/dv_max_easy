import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/profiles/application/profile_controller.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/profiles/presentation/profile_copy.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfilesPage extends ConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(profileControllerProvider);
    final l10n = AppLocalizations.of(context);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('$error'),
      data: (view) {
        final selected = view.selected;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 248, child: _ProfileList(view: view)),
            const SizedBox(width: AppSpacing.l),
            if (selected == null)
              Text(l10n.profilesEmpty)
            else
              Expanded(
                child: _Editor(profile: selected, error: view.errorCode),
              ),
          ],
        );
      },
    );
  }
}

class _ProfileList extends ConsumerWidget {
  const _ProfileList({required this.view});

  final ProfileView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final notifier = ref.read(profileControllerProvider.notifier);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: view.profiles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final profile = view.profiles[index];
                  return _ProfileRow(
                    name: profile.name,
                    summary: profileSummary(l10n, profile),
                    selected: profile.id == view.selectedId,
                    onTap: () => notifier.select(profile.id),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            OutlinedButton.icon(
              onPressed: () => notifier.create(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.profileNew),
            ),
            if (view.canRestoreMusic) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => notifier.restoreMusic(),
                child: Text(l10n.restoreMusic),
              ),
            ],
            if (view.canRestoreFilms)
              TextButton(
                onPressed: () => notifier.restoreFilms(),
                child: Text(l10n.restoreFilms),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.name,
    required this.summary,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.16)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
        hoverColor: scheme.onSurface.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.profile, required this.error});

  final Profile profile;
  final String? error;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late Profile _draft;
  late final TextEditingController _name;
  late final TextEditingController _rate;
  late final TextEditingController _fragments;
  late final TextEditingController _bitrate;
  late final TextEditingController _days;

  @override
  void initState() {
    super.initState();
    _draft = widget.profile;
    _name = TextEditingController(text: _draft.name);
    _rate = TextEditingController(text: _draft.rateLimit ?? '');
    _fragments = TextEditingController(
      text: _draft.concurrentFragments?.toString() ?? '',
    );
    _bitrate = TextEditingController(
      text: _draft.maxBitrateKbps?.toString() ?? '',
    );
    _days = TextEditingController(
      text: _customDaysText(_draft.deleteAfterDays),
    );
  }

  @override
  void didUpdateWidget(covariant _Editor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.id != widget.profile.id) {
      _draft = widget.profile;
      _name.text = _draft.name;
      _rate.text = _draft.rateLimit ?? '';
      _fragments.text = _draft.concurrentFragments?.toString() ?? '';
      _bitrate.text = _draft.maxBitrateKbps?.toString() ?? '';
      _days.text = _customDaysText(_draft.deleteAfterDays);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    _fragments.dispose();
    _bitrate.dispose();
    _days.dispose();
    super.dispose();
  }

  bool get _customDays {
    final days = _draft.deleteAfterDays;
    return days != null && days != 2 && days != 30;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fieldFill = scheme.surface;
    final namePanel = _Panel(
      title: l10n.profileName,
      child: TextField(
        controller: _name,
        decoration: InputDecoration(
          labelText: l10n.profileName,
          fillColor: fieldFill,
          isDense: false,
        ),
        onChanged: (value) => _draft = _draft.copyWith(name: value),
      ),
    );
    final qualityPanel = _Panel(
      title: l10n.presetLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final preset in QualityPreset.values)
                ChoiceChip(
                  label: Text(presetLabel(l10n, preset)),
                  selected: _draft.preset == preset,
                  visualDensity: VisualDensity.comfortable,
                  onSelected: (_) => setState(() {
                    _draft = _draft.copyWith(
                      preset: preset,
                      container: preset == QualityPreset.audio
                          ? MediaContainer.mp3
                          : MediaContainer.mkv,
                      subtitleMode: preset == QualityPreset.audio
                          ? SubtitleMode.none
                          : _draft.subtitleMode,
                    );
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Text(l10n.containerLabel, style: text.bodySmall),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              for (final container in _containersFor(_draft.preset))
                ChoiceChip(
                  label: Text(container.name),
                  selected: _draft.container == container,
                  visualDensity: VisualDensity.comfortable,
                  onSelected: (_) => setState(
                    () => _draft = _draft.copyWith(container: container),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
    final ratePanel = _Panel(
      title: l10n.profileRate,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rate = _rateField(l10n, fieldFill);
          final fragments = _fragmentsField(l10n, fieldFill);
          final bitrate = _bitrateField(l10n, fieldFill);
          if (constraints.maxWidth < 480) {
            return Column(
              children: [
                rate,
                const SizedBox(height: AppSpacing.m),
                fragments,
                const SizedBox(height: AppSpacing.m),
                bitrate,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: rate),
              const SizedBox(width: AppSpacing.m),
              Expanded(child: fragments),
              const SizedBox(width: AppSpacing.m),
              Expanded(child: bitrate),
            ],
          );
        },
      ),
    );
    final folderPanel = _Panel(
      title: l10n.profileFolder,
      child: Row(
        children: [
          Icon(Icons.folder_outlined, size: 18, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _draft.destinationFolder ?? l10n.folderEmpty,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodyMedium?.copyWith(
                color: _draft.destinationFolder == null
                    ? scheme.onSurfaceVariant
                    : scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          OutlinedButton(
            onPressed: () async {
              final folder = await getDirectoryPath();
              if (folder == null) {
                return;
              }
              setState(
                () => _draft = _draft.copyWith(destinationFolder: folder),
              );
            },
            child: Text(l10n.chooseFolder),
          ),
        ],
      ),
    );
    final retentionPanel = _Panel(
      title: l10n.retentionLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.retentionHint, style: text.bodySmall),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: [
              ChoiceChip(
                label: Text(l10n.retentionNever),
                selected: _draft.deleteAfterDays == null,
                onSelected: (_) => setState(
                  () => _draft = _draft.copyWith(clearRetention: true),
                ),
              ),
              ChoiceChip(
                label: Text(l10n.retentionTwo),
                selected: _draft.deleteAfterDays == 2,
                onSelected: (_) => setState(
                  () => _draft = _draft.copyWith(deleteAfterDays: 2),
                ),
              ),
              ChoiceChip(
                label: Text(l10n.retentionThirty),
                selected: _draft.deleteAfterDays == 30,
                onSelected: (_) => setState(
                  () => _draft = _draft.copyWith(deleteAfterDays: 30),
                ),
              ),
              ChoiceChip(
                label: Text(l10n.retentionCustom),
                selected: _customDays,
                onSelected: (_) => setState(() {
                  if (_customDays) {
                    return;
                  }
                  _draft = _draft.copyWith(deleteAfterDays: 7);
                  _days.text = '7';
                }),
              ),
            ],
          ),
          if (_customDays) ...[
            const SizedBox(height: AppSpacing.m),
            TextField(
              controller: _days,
              decoration: InputDecoration(
                labelText: l10n.retentionDays,
                fillColor: fieldFill,
                isDense: false,
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final parsed = int.tryParse(value);
                setState(() {
                  _draft = _draft.copyWith(deleteAfterDays: parsed ?? 0);
                });
              },
            ),
          ],
        ],
      ),
    );
    final actions = Row(
      children: [
        FilledButton(
          onPressed: () =>
              ref.read(profileControllerProvider.notifier).save(_draft),
          child: Text(l10n.profileSave),
        ),
        const Spacer(),
        TextButton(
          onPressed: () =>
              ref.read(profileControllerProvider.notifier).delete(_draft.id),
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          child: Text(l10n.profileDelete),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.l),
          children: [
            if (widget.error != null) ...[
              Text(
                profileMessage(l10n, widget.error!),
                style: text.bodyMedium?.copyWith(color: scheme.error),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: namePanel),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(flex: 3, child: qualityPanel),
                ],
              )
            else ...[
              namePanel,
              const SizedBox(height: AppSpacing.m),
              qualityPanel,
            ],
            const SizedBox(height: AppSpacing.m),
            ratePanel,
            const SizedBox(height: AppSpacing.m),
            folderPanel,
            const SizedBox(height: AppSpacing.m),
            retentionPanel,
            const SizedBox(height: AppSpacing.l),
            actions,
          ],
        );
      },
    );
  }

  Widget _rateField(AppLocalizations l10n, Color fill) {
    return TextField(
      controller: _rate,
      decoration: InputDecoration(
        labelText: l10n.rateLimitLabel,
        helperText: l10n.rateLimitHint,
        fillColor: fill,
        isDense: false,
      ),
      onChanged: (value) => _draft = _draft.copyWith(
        rateLimit: value,
        clearRate: value.trim().isEmpty,
      ),
    );
  }

  Widget _fragmentsField(AppLocalizations l10n, Color fill) {
    return TextField(
      controller: _fragments,
      decoration: InputDecoration(
        labelText: l10n.fragmentsLabel,
        helperText: l10n.fragmentsHint,
        fillColor: fill,
        isDense: false,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        final parsed = int.tryParse(value);
        _draft = _draft.copyWith(
          concurrentFragments: parsed,
          clearFragments: value.isEmpty,
        );
      },
    );
  }

  Widget _bitrateField(AppLocalizations l10n, Color fill) {
    return TextField(
      controller: _bitrate,
      decoration: InputDecoration(
        labelText: l10n.bitrateLabel,
        helperText: l10n.bitrateHint,
        fillColor: fill,
        isDense: false,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        final parsed = int.tryParse(value);
        _draft = _draft.copyWith(
          maxBitrateKbps: parsed,
          clearBitrate: value.isEmpty,
        );
      },
    );
  }
}

String _customDaysText(int? days) {
  if (days == null || days == 2 || days == 30) {
    return '';
  }
  return '$days';
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

List<MediaContainer> _containersFor(QualityPreset preset) {
  if (preset == QualityPreset.audio) {
    return const [MediaContainer.mp3, MediaContainer.m4a];
  }
  return const [MediaContainer.mkv, MediaContainer.mp4];
}
