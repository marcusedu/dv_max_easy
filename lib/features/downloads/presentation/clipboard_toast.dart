import 'dart:io';

import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/link_meta_probe.dart';
import 'package:dv_max_easy/features/downloads/presentation/source_favicon.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ClipboardToast extends ConsumerWidget {
  const ClipboardToast({
    required this.url,
    required this.onDownload,
    required this.onDismiss,
    super.key,
  });

  final String url;
  final VoidCallback onDownload;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final dark = scheme.brightness == Brightness.dark;
    final metaAsync = ref.watch(linkMetaProvider(url));
    final quickThumb = quickThumbnailUrl(url);
    final thumb = metaAsync.asData?.value.thumbnailUrl ?? quickThumb;
    final title = metaAsync.asData?.value.title;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.45 : 0.14),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 360, maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ToastThumb(thumbUrl: thumb, sourceUrl: url),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SourceFavicon(url: url, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              l10n.clipboardOffer,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        title ?? url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium?.copyWith(
                          fontWeight:
                              title != null ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                PressableScale(
                  child: FilledButton.icon(
                    onPressed: onDownload,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 34),
                    ),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: Text(l10n.downloadStart),
                  ),
                ),
                const SizedBox(width: 4),
                PressableScale(
                  child: IconButton(
                    tooltip: l10n.clipboardDismiss,
                    onPressed: onDismiss,
                    style: IconButton.styleFrom(
                      minimumSize: const Size(28, 28),
                      padding: EdgeInsets.zero,
                    ),
                    icon: Icon(
                      Icons.close,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToastThumb extends StatelessWidget {
  const _ToastThumb({required this.thumbUrl, required this.sourceUrl});

  final String? thumbUrl;
  final String sourceUrl;

  static bool get _loadsNetwork =>
      !Platform.environment.containsKey('FLUTTER_TEST');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 76,
        height: 48,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: scheme.surfaceContainerLow),
            if (thumbUrl != null && _loadsNetwork)
              Image.network(
                thumbUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Center(
                  child: SourceFavicon(url: sourceUrl, size: 24),
                ),
              )
            else
              Center(
                child: SourceFavicon(url: sourceUrl, size: 24),
              ),
          ],
        ),
      ),
    );
  }
}
