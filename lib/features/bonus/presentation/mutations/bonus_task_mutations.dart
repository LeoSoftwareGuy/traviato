import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/bonus_task_assignment_entity.dart';
import '../controllers/bonus_tray_controller.dart';
import '../providers/bonus_task_providers.dart';

final completeBonusTaskMutation = Mutation<BonusTaskAssignmentEntity>();
final claimStretchTaskMutation = Mutation<BonusTaskAssignmentEntity>();

/// Called after the M3-6 capture flow returns a saved photo: marks the
/// assignment complete with that photo, awards its stars, and re-checks
/// achievements (all server-side, inside `completeAssignment`).
Future<BonusTaskAssignmentEntity> runCompleteBonusTask({
  required WidgetRef ref,
  required String tripId,
  required String assignmentId,
  required String photoId,
}) {
  return completeBonusTaskMutation(assignmentId).run(ref, (tsx) async {
    final repo = tsx.get(bonusTaskRepositoryProvider);
    final controller = tsx.get(bonusTrayControllerProvider(tripId).notifier);
    final result = await repo.completeAssignment(
      id: assignmentId,
      tripId: tripId,
      photoId: photoId,
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (assignment) {
        controller.applyAssignmentUpserted(assignment);
        tsx.get(globalEventBusProvider).add(const StarsAwardedDispatched());
        return assignment;
      },
    );
  });
}

/// Inserts the opt-in stretch assignment when the user taps its offer card.
/// Never called automatically — accepting is the only way a stretch task
/// gets persisted (functionality.md §12).
Future<BonusTaskAssignmentEntity> runClaimStretchTask({
  required WidgetRef ref,
  required String tripId,
  required DateTime dayDate,
  required int templateId,
}) {
  return claimStretchTaskMutation.run(ref, (tsx) async {
    final repo = tsx.get(bonusTaskRepositoryProvider);
    final controller = tsx.get(bonusTrayControllerProvider(tripId).notifier);
    final result = await repo.assignForDay(
      tripId: tripId,
      dayDate: dayDate,
      templateIds: [templateId],
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (rows) {
        final claimed = rows.firstWhere((a) => a.templateId == templateId);
        controller.applyAssignmentUpserted(claimed);
        return claimed;
      },
    );
  });
}
