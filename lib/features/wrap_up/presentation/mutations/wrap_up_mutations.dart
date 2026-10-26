import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../settings/presentation/controllers/app_language_controller.dart';
import '../controllers/wrap_up_controller.dart';
import '../providers/wrap_up_providers.dart';

final publishWrapUpMutation = Mutation<void>();
final rebuildKeptFilmMutation = Mutation<void>();

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
    result.fold((failure) => throw PresentationFailureException(failure), (_) {
      final publishedAt = DateTime.now();
      controller.applyPublished(publishedAt);
      tsx
          .get(globalEventBusProvider)
          .add(
            WrapUpPublishedDispatched(
              tripId: tripId,
              publishedAt: publishedAt,
            ),
          );
    });
  });
}

/// "Photos changed · Rebuild film" (#294): re-assembles a kept film from the
/// current photos and picks, keeping its AI lines (no AI call) and keeping
/// it kept, then reloads the film.
Future<void> runRebuildKeptFilm({
  required WidgetRef ref,
  required String tripId,
}) {
  return rebuildKeptFilmMutation.run(ref, (tsx) async {
    final repo = tsx.get(wrapUpRepositoryProvider);
    final controller = tsx.get(wrapUpControllerProvider(tripId).notifier);
    final result = await repo.rebuildKept(
      tripId,
      language: tsx.get(resolvedAppLanguageProvider).code!,
    );
    result.fold(
      (failure) => throw PresentationFailureException(failure),
      (_) => controller.reloadRebuilt(),
    );
  });
}
