import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/downloads/application/link_meta_probe.dart';
import 'package:dv_max_easy/features/downloads/presentation/source_favicon.dart';
import 'package:dv_max_easy/features/profiles/domain/profile.dart';
import 'package:dv_max_easy/features/profiles/application/profile_controller.dart';
import 'package:dv_max_easy/features/settings/application/settings_controller.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<bool?> showDownloadDialog({
  required BuildContext context,
  required String url,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => DownloadDialog(url: url),
  );
}

class DownloadDialog extends ConsumerStatefulWidget {
  const DownloadDialog({required this.url, super.key});

  final String url;

  @override
  ConsumerState<DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends ConsumerState<DownloadDialog> {
  final _tagsController = TextEditingController();
  final _focusNode = FocusNode();
  List<String> _parsedTags = const [];

  @override
  void initState() {
    super.initState();
    _tagsController.addListener(_onTagsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _tagsController.removeListener(_onTagsChanged);
    _tagsController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTagsChanged() {
    setState(() {
      _parsedTags = parseTags(_tagsController.text);
    });
  }

  void _confirm() {
    final tags = parseTags(_tagsController.text);
    ref.read(downloadControllerProvider.notifier).enqueue(widget.url, tags: tags);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final metaAsync = ref.watch(linkMetaProvider(widget.url));
    final quickThumb = quickThumbnailUrl(widget.url);
    final thumb = metaAsync.asData?.value.thumbnailUrl ?? quickThumb;
    final title = metaAsync.asData?.value.title;

    final settings = ref.watch(settingsControllerProvider).asData?.value;
    final profileDoc = ref.watch(profileControllerProvider).asData?.value;
    final activeProfile = profileDoc?.profiles.cast<Profile?>().firstWhere(
      (p) => p?.id == settings?.settings.selectedProfileId,
      orElse: () => profileDoc.profiles.isNotEmpty ? profileDoc.profiles.first : null,
    );
    final profileTag = activeProfile != null
        ? '#perfil:${activeProfile.name.toLowerCase().trim().replaceAll(RegExp(r'\s+'), '_')}'
        : '#perfil:filmes';

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SourceFavicon(url: widget.url, size: 20),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      'Iniciar Download',
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.m),
              if (thumb != null || title != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (thumb != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          thumb,
                          width: 100,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title ?? widget.url,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.url,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
              ],
              Text('Tags do Vídeo', style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Defina tags manuais separadas por espaço (ex: #engracado #politica). A tag do perfil será adicionada automaticamente.',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.s),
              TextField(
                controller: _tagsController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'ex: #engracado #politica',
                  prefixIcon: Icon(Icons.tag_rounded, size: 18),
                  isDense: true,
                ),
                onSubmitted: (_) => _confirm(),
              ),
              const SizedBox(height: AppSpacing.s),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Chip(
                    avatar: const Icon(Icons.lock_outline, size: 14),
                    label: Text(profileTag),
                    backgroundColor: scheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: scheme.onPrimaryContainer,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  for (final tag in _parsedTags)
                    Chip(
                      label: Text(tag),
                      backgroundColor: scheme.surfaceContainerHighest,
                      labelStyle: text.bodySmall,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(l10n.downloadCancel),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  PressableScale(
                    child: FilledButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: Text(l10n.downloadStart),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
