import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../controllers/wrap_up_controller.dart';
import '../providers/wrap_up_providers.dart';

final publishWrapUpMutation = Mutation<void>();

/// "Keep forever" — sets `published_at`. Editing/reordering the screenplay
/// is a separate, not-yet-designed feature (M4-3); this only flips the flag.
Future<void> runPublishWrapUp({
  required WidgetRef ref,
  required String tripId,
}) {
  return publishWrapUpMutation.run(ref, (tsx) async {
    final repo = tsx.get(wrapUpRepositoryProvider);
    final controller = tsx.get(wrapUpControllerProvider(tripId).notifier);
    final result = await repo.publish(tripId);
    result.fold(
      (failure) => throw PresentationFailureException(failure),
      (_) => controller.applyPublished(DateTime.now()),
    );
  });
}
