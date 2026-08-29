import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/bonus_task_assignment_entity.dart';
import 'bonus_tray_loader.dart';
import 'bonus_tray_state.dart';

part 'bonus_tray_controller.g.dart';

@riverpod
class BonusTrayController extends _$BonusTrayController {
  @override
  Future<BonusTrayState> build(String tripId) =>
      loadBonusTrayState(ref, tripId);

  /// Called by the completion/stretch-claim mutations after a successful
  /// insert/update so the tray reflects it instantly.
  void applyAssignmentUpserted(BonusTaskAssignmentEntity assignment) {
    final current = state.value;
    if (current == null) return;
    final exists = current.assignments.any((a) => a.id == assignment.id);
    final updated = exists
        ? [
            for (final a in current.assignments)
              if (a.id == assignment.id) assignment else a,
          ]
        : [...current.assignments, assignment];
    state = AsyncData(current.copyWith(assignments: updated));
  }
}
