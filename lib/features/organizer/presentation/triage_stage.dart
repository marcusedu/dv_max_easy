import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/organizer/application/organizer_controller.dart';
import 'package:dv_max_easy/features/organizer/presentation/triage_card.dart';
import 'package:dv_max_easy/features/organizer/presentation/triage_completion_view.dart';
import 'package:dv_max_easy/features/organizer/presentation/triage_hud.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TriageStage extends ConsumerStatefulWidget {
  const TriageStage({super.key});

  @override
  ConsumerState<TriageStage> createState() => _TriageStageState();
}

class _TriageStageState extends ConsumerState<TriageStage> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isMeta = HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isControlPressed;

    if (isMeta && event.logicalKey == LogicalKeyboardKey.keyZ) {
      ref.read(organizerControllerProvider.notifier).undo();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.space) {
      ref.read(organizerControllerProvider.notifier).nextItem();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      ref.read(organizerControllerProvider.notifier).previousItem();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.delete ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      ref.read(organizerControllerProvider.notifier).trashCurrent();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyT) {
      ref.read(organizerControllerProvider.notifier).stashTemporaryCurrent();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.keyF ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      ref.read(organizerControllerProvider.notifier).toggleFavoriteCurrent();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      ref.read(organizerControllerProvider.notifier).exitTriage();
      return KeyEventResult.handled;
    }

    // Slots 1 a 9 (números do topo do teclado e teclado numérico)
    final keyId = event.logicalKey.keyId;
    if (keyId >= LogicalKeyboardKey.digit1.keyId &&
        keyId <= LogicalKeyboardKey.digit9.keyId) {
      final num = keyId - LogicalKeyboardKey.digit1.keyId + 1;
      ref.read(organizerControllerProvider.notifier).moveToSlot(num);
      return KeyEventResult.handled;
    }

    if (keyId >= LogicalKeyboardKey.numpad1.keyId &&
        keyId <= LogicalKeyboardKey.numpad9.keyId) {
      final num = keyId - LogicalKeyboardKey.numpad1.keyId + 1;
      ref.read(organizerControllerProvider.notifier).moveToSlot(num);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(organizerControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    if (state.isCompleted || state.queue.isEmpty) {
      return const TriageCompletionView();
    }

    final currentItem = state.currentItem;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
          children: [
            // Barra superior com botão Sair da Triagem e Toast de feedback
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: Row(
                children: [
                  PressableScale(
                    scaleDown: 0.95,
                    child: OutlinedButton.icon(
                      onPressed: () => ref
                          .read(organizerControllerProvider.notifier)
                          .exitTriage(),
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Voltar ao Painel (Esc)'),
                    ),
                  ),
                  const Spacer(),
                  if (state.errorNotice != null)
                    AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.errorNotice!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.redAccent,
                                ),
                          ),
                        ],
                      ),
                    )
                  else if (state.lastToast != null)
                    AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            state.lastToast!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Palco do Card de Mídia Central com transição física
            Expanded(
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                switchInCurve: AppMotion.easeOut,
                switchOutCurve: AppMotion.easeOut,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.96, end: 1.0).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: AppMotion.easeOut,
                        ),
                      ),
                      child: child,
                    ),
                  );
                },
                child: currentItem != null
                    ? KeyedSubtree(
                        key: ValueKey(currentItem.path),
                        child: TriageCard(item: currentItem),
                      )
                    : const SizedBox.shrink(),
              ),
            ),

            const SizedBox(height: AppSpacing.m),

            // HUD de atalhos e slots
            const TriageHud(),
          ],
        ),
      ),
    );
  }
}
