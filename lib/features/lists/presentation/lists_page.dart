import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/downloads/application/download_controller.dart';
import 'package:dv_max_easy/features/lists/application/link_list_controller.dart';
import 'package:dv_max_easy/features/lists/domain/link_list.dart';
import 'package:dv_max_easy/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const listsUrlFieldKey = Key('lists-url');

class ListsPage extends ConsumerStatefulWidget {
  const ListsPage({required this.onQueued, super.key});

  final VoidCallback onQueued;

  @override
  ConsumerState<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends ConsumerState<ListsPage> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  String? _boundId;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  void _bind(LinkList? list) {
    if (list == null || list.id == _boundId) {
      return;
    }
    _boundId = list.id;
    _name.text = list.name;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final view = ref.watch(linkListControllerProvider);
    return view.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (data) {
        final selected = data.selected;
        _bind(selected);
        if (data.lists.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.listsEmpty,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.m),
              FilledButton.icon(
                onPressed: () =>
                    ref.read(linkListControllerProvider.notifier).create(),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.listsNew),
              ),
              if (data.errorCode != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error(l10n, data.errorCode!),
                  style: TextStyle(color: scheme.error),
                ),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 220,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        for (final list in data.lists)
                          ListTile(
                            selected: list.id == selected?.id,
                            title: Text(
                              list.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(l10n.listsCount(list.urls.length)),
                            onTap: () => ref
                                .read(linkListControllerProvider.notifier)
                                .select(list.id),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(linkListControllerProvider.notifier).create(),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.listsNew),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: selected == null
                  ? const SizedBox.shrink()
                  : _Editor(
                      key: ValueKey(selected.id),
                      list: selected,
                      name: _name,
                      url: _url,
                      errorCode: data.errorCode,
                      onQueued: widget.onQueued,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Editor extends ConsumerWidget {
  const _Editor({
    required this.list,
    required this.name,
    required this.url,
    required this.errorCode,
    required this.onQueued,
    super.key,
  });

  final LinkList list;
  final TextEditingController name;
  final TextEditingController url;
  final String? errorCode;
  final VoidCallback onQueued;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final controller = ref.read(linkListControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: name,
          decoration: InputDecoration(labelText: l10n.listsName),
          onSubmitted: (value) => controller.rename(list.id, value),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: listsUrlFieldKey,
                controller: url,
                decoration: InputDecoration(hintText: l10n.listsUrlHint),
                onSubmitted: (value) => _add(controller),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () => _add(controller),
              child: Text(l10n.listsAdd),
            ),
          ],
        ),
        if (errorCode != null) ...[
          const SizedBox(height: 8),
          Text(_error(l10n, errorCode!), style: TextStyle(color: scheme.error)),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              for (final item in list.urls)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    tooltip: l10n.listsRemove,
                    onPressed: () => controller.removeUrl(list.id, item),
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.icon(
              onPressed: list.urls.isEmpty
                  ? null
                  : () async {
                      for (final item in list.urls) {
                        await ref
                            .read(downloadControllerProvider.notifier)
                            .enqueue(item);
                      }
                      onQueued();
                    },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(l10n.listsDownloadAll),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => controller.delete(list.id),
              child: Text(l10n.listsDelete),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _add(LinkListController controller) async {
    final added = await controller.addUrl(list.id, url.text);
    if (added) {
      url.clear();
    }
  }
}

String _error(AppLocalizations l10n, String code) {
  return switch (code) {
    'duplicate' => l10n.listsDuplicate,
    'full' => l10n.listsFull,
    'too_many' => l10n.listsTooMany,
    'empty_name' => l10n.listsEmptyName,
    _ => l10n.listsBadUrl,
  };
}
