import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/features/settings/domain/binary_path.dart';
import 'package:dv_max_easy/features/settings/presentation/settings_copy.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsForm extends ConsumerWidget {
  const SettingsForm({super.key, this.showIntro = false});

  final bool showIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsControllerProvider);
    final l10n = AppLocalizations.of(context);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Text('$error'),
      data: (view) {
        final text = Theme.of(context).textTheme;
        return Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showIntro) ...[
                  Text(l10n.setupTitle, style: text.titleMedium),
                  const SizedBox(height: AppSpacing.s),
                  Text(_hint(l10n), style: text.bodySmall),
                  const SizedBox(height: AppSpacing.l),
                ],
                if (view.noticeCode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Text(
                      settingsMessage(
                        l10n,
                        view.noticeCode!,
                        detail: view.noticeDetail,
                      ),
                      style: text.bodyMedium,
                    ),
                  ),
                if (view.errorCode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Text(
                      settingsMessage(l10n, view.errorCode!),
                      style: text.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                _BinaryRow(
                  label: l10n.ytDlpPathLabel,
                  path: view.settings.ytDlpPath,
                  version: view.ytDlpVersion,
                  pending: view.pendingKind == BinaryKind.ytDlp
                      ? view.pendingPath
                      : null,
                  onChoose: () => _pickFile(ref, BinaryKind.ytDlp),
                  onSearch: () => ref
                      .read(settingsControllerProvider.notifier)
                      .search(BinaryKind.ytDlp),
                  onConfirm: () => ref
                      .read(settingsControllerProvider.notifier)
                      .acceptPending(),
                ),
                const SizedBox(height: AppSpacing.m),
                _BinaryRow(
                  label: l10n.ffmpegPathLabel,
                  path: view.settings.ffmpegPath,
                  version: view.ffmpegVersion,
                  pending: view.pendingKind == BinaryKind.ffmpeg
                      ? view.pendingPath
                      : null,
                  onChoose: () => _pickFile(ref, BinaryKind.ffmpeg),
                  onSearch: () => ref
                      .read(settingsControllerProvider.notifier)
                      .search(BinaryKind.ffmpeg),
                  onConfirm: () => ref
                      .read(settingsControllerProvider.notifier)
                      .acceptPending(),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(l10n.folderLabel, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.s),
                Text(
                  view.settings.defaultDownloadFolder ?? l10n.folderEmpty,
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.s),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton(
                    onPressed: () => _pickFolder(ref),
                    child: Text(l10n.chooseFolder),
                  ),
                ),
                const SizedBox(height: AppSpacing.l),
                Text(l10n.concurrentLabel, style: text.bodyMedium),
                const SizedBox(height: AppSpacing.s),
                Wrap(
                  spacing: AppSpacing.s,
                  children: [
                    for (final value in [1, 2, 3, 4])
                      ChoiceChip(
                        label: Text('$value'),
                        selected: view.settings.maxConcurrentDownloads == value,
                        onSelected: (_) => ref
                            .read(settingsControllerProvider.notifier)
                            .setConcurrent(value),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.clipboardLabel, style: text.bodyMedium),
                  value: view.settings.clipboardPromptEnabled,
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .setClipboardPrompt(value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.redactLabel, style: text.bodyMedium),
                  value: view.settings.redactUrlsInLog,
                  onChanged: (value) => ref
                      .read(settingsControllerProvider.notifier)
                      .setRedactUrls(value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _hint(AppLocalizations l10n) {
    return switch (defaultTargetPlatform) {
      TargetPlatform.macOS => l10n.setupHintMac,
      TargetPlatform.windows => l10n.setupHintWindows,
      _ => l10n.setupHintLinux,
    };
  }

  Future<void> _pickFile(WidgetRef ref, BinaryKind kind) async {
    final file = await openFile();
    if (file == null) {
      return;
    }
    await ref.read(settingsControllerProvider.notifier).acceptBinary(kind, file.path);
  }

  Future<void> _pickFolder(WidgetRef ref) async {
    final folder = await getDirectoryPath();
    if (folder == null) {
      return;
    }
    await ref.read(settingsControllerProvider.notifier).setFolder(folder);
  }
}

class _BinaryRow extends StatelessWidget {
  const _BinaryRow({
    required this.label,
    required this.path,
    required this.version,
    required this.pending,
    required this.onChoose,
    required this.onSearch,
    required this.onConfirm,
  });

  final String label;
  final String? path;
  final String? version;
  final String? pending;
  final VoidCallback onChoose;
  final VoidCallback onSearch;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.bodyMedium),
        const SizedBox(height: AppSpacing.s),
        Text(path ?? l10n.binaryEmpty, style: text.bodySmall),
        if (version != null)
          Text(version!, style: text.bodySmall),
        if (pending != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(l10n.foundPath(pending!), style: text.bodyMedium),
          const SizedBox(height: AppSpacing.s),
          OutlinedButton(onPressed: onConfirm, child: Text(l10n.confirmPath)),
        ],
        const SizedBox(height: AppSpacing.s),
        Wrap(
          spacing: AppSpacing.s,
          children: [
            OutlinedButton(onPressed: onChoose, child: Text(l10n.chooseFile)),
            OutlinedButton(onPressed: onSearch, child: Text(l10n.searchPath)),
          ],
        ),
      ],
    );
  }
}
