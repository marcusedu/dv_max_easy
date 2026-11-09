import 'package:dv_max_easy/design/app_theme.dart';
import 'package:dv_max_easy/features/organizer/application/organizer_controller.dart';
import 'package:dv_max_easy/features/organizer/presentation/folder_report_view.dart';
import 'package:dv_max_easy/features/organizer/presentation/triage_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizerPage extends ConsumerWidget {
  const OrganizerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(organizerControllerProvider);

    return AnimatedSwitcher(
      duration: AppMotion.medium,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: AppMotion.easeOut),
            ),
            child: child,
          ),
        );
      },
      child: state.isTriageActive
          ? const TriageStage(key: ValueKey('triage_active'))
          : const FolderReportView(key: ValueKey('folder_report')),
    );
  }
}
