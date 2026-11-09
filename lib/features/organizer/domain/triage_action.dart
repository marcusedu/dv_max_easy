import 'package:dv_max_easy/features/organizer/domain/triage_item.dart';

enum TriageActionType {
  movedToSlot,
  movedToTrash,
  stashedTemporary,
  favorited,
  skipped,
}

final class TriageAction {
  const TriageAction({
    required this.id,
    required this.item,
    required this.type,
    required this.timestamp,
    this.destinationPath,
    this.slotNumber,
  });

  final String id;
  final TriageItem item;
  final TriageActionType type;
  final DateTime timestamp;
  final String? destinationPath;
  final int? slotNumber;

  bool get canUndo =>
      type == TriageActionType.movedToSlot ||
      type == TriageActionType.movedToTrash ||
      type == TriageActionType.stashedTemporary;
}
