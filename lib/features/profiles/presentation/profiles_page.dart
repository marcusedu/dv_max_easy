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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final profile in view.profiles)
                    ListTile(
                      selected: profile.id == view.selectedId,
                      title: Text(profile.name),
                      onTap: () => ref
                          .read(profileControllerProvider.notifier)
                          .select(profile.id),
                    ),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(profileControllerProvider.notifier).create(),
                    child: Text(l10n.profileNew),
                  ),
                  if (view.canRestoreMusic)
                    TextButton(
                      onPressed: () => ref
                          .read(profileControllerProvider.notifier)
                          .restoreMusic(),
                      child: Text(l10n.restoreMusic),
                    ),
                  if (view.canRestoreFilms)
                    TextButton(
                      onPressed: () => ref
                          .read(profileControllerProvider.notifier)
                          .restoreFilms(),
                      child: Text(l10n.restoreFilms),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.l),
            if (selected == null)
              Text(l10n.profilesEmpty)
            else
              Expanded(child: _Editor(profile: selected, error: view.errorCode)),
          ],
        );
      },
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
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    _fragments.dispose();
    _bitrate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.error != null)
          Text(profileMessage(l10n, widget.error!), style: text.bodyMedium),
        TextField(
          controller: _name,
          decoration: InputDecoration(labelText: l10n.profileName),
          onChanged: (value) => _draft = _draft.copyWith(name: value),
        ),
        const SizedBox(height: AppSpacing.m),
        Text(l10n.presetLabel, style: text.bodyMedium),
        Wrap(
          spacing: AppSpacing.s,
          children: [
            for (final preset in QualityPreset.values)
              ChoiceChip(
                label: Text(presetLabel(l10n, preset)),
                selected: _draft.preset == preset,
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
        const SizedBox(height: AppSpacing.m),
        DropdownButton<MediaContainer>(
          value: _draft.container,
          items: [
            for (final container in _containersFor(_draft.preset))
              DropdownMenuItem(value: container, child: Text(container.name)),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _draft = _draft.copyWith(container: value));
          },
        ),
        const SizedBox(height: AppSpacing.m),
        TextField(
          controller: _rate,
          decoration: InputDecoration(labelText: l10n.rateLimitLabel),
          onChanged: (value) => _draft = _draft.copyWith(
            rateLimit: value,
            clearRate: value.trim().isEmpty,
          ),
        ),
        TextField(
          controller: _fragments,
          decoration: InputDecoration(labelText: l10n.fragmentsLabel),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            final parsed = int.tryParse(value);
            _draft = _draft.copyWith(
              concurrentFragments: parsed,
              clearFragments: value.isEmpty,
            );
          },
        ),
        TextField(
          controller: _bitrate,
          decoration: InputDecoration(labelText: l10n.bitrateLabel),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (value) {
            final parsed = int.tryParse(value);
            _draft = _draft.copyWith(
              maxBitrateKbps: parsed,
              clearBitrate: value.isEmpty,
            );
          },
        ),
        const SizedBox(height: AppSpacing.m),
        Text(
          _draft.destinationFolder ?? l10n.folderEmpty,
          style: text.bodySmall,
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
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
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            FilledButton(
              onPressed: () =>
                  ref.read(profileControllerProvider.notifier).save(_draft),
              child: Text(l10n.profileSave),
            ),
            const SizedBox(width: AppSpacing.s),
            TextButton(
              onPressed: () => ref
                  .read(profileControllerProvider.notifier)
                  .delete(_draft.id),
              child: Text(l10n.profileDelete),
            ),
          ],
        ),
      ],
    );
  }
}

List<MediaContainer> _containersFor(QualityPreset preset) {
  if (preset == QualityPreset.audio) {
    return const [MediaContainer.mp3, MediaContainer.m4a];
  }
  return const [MediaContainer.mkv, MediaContainer.mp4];
}
