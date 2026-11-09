import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/organizer/application/organizer_controller.dart';
import 'package:dv_max_easy/features/organizer/domain/target_folder_slot.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TriageHud extends ConsumerWidget {
  const TriageHud({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(organizerControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final total = state.queue.length;
    final current = state.currentIndex.clamp(0, total);
    final progress = total > 0 ? current / total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.m,
        vertical: AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppSpacing.panelRadius),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra de progresso contínua e status
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SmoothProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: scheme.outlineVariant.withValues(alpha: 0.3),
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Text(
                '$current / $total (${(progress * 100).toInt()}%)',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              IconButton(
                tooltip: 'Arquivo anterior (←)',
                onPressed: state.hasPrevious
                    ? () => ref
                        .read(organizerControllerProvider.notifier)
                        .previousItem()
                    : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Próximo arquivo (→ / Espaço)',
                onPressed: () =>
                    ref.read(organizerControllerProvider.notifier).nextItem(),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Guardar na Lista Temporária (T)',
                onPressed: () => ref
                    .read(organizerControllerProvider.notifier)
                    .stashTemporaryCurrent(),
                icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                visualDensity: VisualDensity.compact,
              ),
              PressableScale(
                scaleDown: 0.95,
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(organizerControllerProvider.notifier)
                      .trashCurrent(),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 14,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    'Lixeira (Del)',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 26),
                    side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
              if (state.canUndo) ...[
                const SizedBox(width: AppSpacing.s),
                PressableScale(
                  scaleDown: 0.95,
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(organizerControllerProvider.notifier).undo(),
                    icon: const Icon(Icons.undo_rounded, size: 14),
                    label: const Text('Desfazer (⌘Z)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 26),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s),

          // Slots 1 a 9 para mover arquivos
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final slot in state.slots)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _SlotChip(
                      slot: slot,
                      onTrigger: () => ref
                          .read(organizerControllerProvider.notifier)
                          .moveToSlot(slot.slotNumber),
                      onEdit: () => _editSlotDialog(context, ref, slot),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),
          // Legenda compacta de atalhos
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _KeyBadge(label: '←', desc: 'Anterior'),
              const SizedBox(width: 8),
              _KeyBadge(label: '→ / Espaço', desc: 'Próximo'),
              const SizedBox(width: 8),
              _KeyBadge(label: 'Del', desc: 'Lixeira'),
              const SizedBox(width: 8),
              _KeyBadge(label: 'T', desc: 'Temporário'),
              const SizedBox(width: 8),
              _KeyBadge(label: 'F', desc: 'Favoritar'),
              const SizedBox(width: 8),
              _KeyBadge(label: '1–9', desc: 'Mover'),
              const SizedBox(width: 8),
              _KeyBadge(label: 'Esc', desc: 'Sair'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editSlotDialog(
    BuildContext context,
    WidgetRef ref,
    TargetFolderSlot slot,
  ) async {
    final labelController = TextEditingController(text: slot.label);
    var path = slot.path;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Configurar Slot ${slot.slotNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Rótulo da pasta'),
              ),
              const SizedBox(height: AppSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      path.isEmpty ? 'Nenhuma pasta selecionada' : path,
                      style: Theme.of(ctx).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  OutlinedButton(
                    onPressed: () async {
                      final chosen = await getDirectoryPath();
                      if (chosen != null) {
                        setDialogState(() => path = chosen);
                      }
                    },
                    child: const Text('Escolher...'),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                ref.read(organizerControllerProvider.notifier).updateSlot(
                      slot.slotNumber,
                      label: labelController.text.trim().isEmpty
                          ? 'Slot ${slot.slotNumber}'
                          : labelController.text.trim(),
                      path: path,
                    );
                Navigator.of(ctx).pop();
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.slot,
    required this.onTrigger,
    required this.onEdit,
  });

  final TargetFolderSlot slot;
  final VoidCallback onTrigger;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final configured = slot.isConfigured;

    return PressableScale(
      scaleDown: 0.94,
      child: Tooltip(
        message: configured
            ? 'Pressione [${slot.slotNumber}] para mover para:\n${slot.path}\n(Clique com botão direito para editar)'
            : 'Slot [${slot.slotNumber}] não configurado. Clique para escolher pasta.',
        child: InkWell(
          onTap: onTrigger,
          onSecondaryTap: onEdit,
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: configured
                  ? scheme.primary.withValues(alpha: 0.12)
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
              border: Border.all(
                color: configured
                    ? scheme.primary.withValues(alpha: 0.3)
                    : scheme.outlineVariant,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: configured ? scheme.primary : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${slot.slotNumber}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: configured
                          ? scheme.onPrimary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  slot.label.isEmpty ? 'Slot ${slot.slotNumber}' : slot.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: configured
                            ? scheme.onSurface
                            : scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(10),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 12,
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
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

class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.label, required this.desc});

  final String label;
  final String desc;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          desc,
          style: TextStyle(
            fontSize: 10,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
