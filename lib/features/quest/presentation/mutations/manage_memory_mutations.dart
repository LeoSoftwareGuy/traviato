import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../../trip/presentation/widgets/cover_options.dart';
import '../controllers/plan_controller.dart';

/// The manage-memory-sheet edits (rename, cover change, date shift). Live
/// alongside the Plan feature — not `trip_mutations.dart` — because each
/// one updates `planControllerProvider(tripId)` directly for instant
/// feedback on the screen that triggered it, the same pattern the quest
/// mutations already use.
final renameMemoryMutation = Mutation<TripCardEntity>();
final changeCoverMutation = Mutation<TripCardEntity>();
final shiftMemoryDatesMutation = Mutation<TripCardEntity>();

Future<TripCardEntity> runRenameMemory({
  required WidgetRef ref,
  required String tripId,
  required String name,
}) {
  return renameMemoryMutation.run(ref, (tsx) async {
    final repo = tsx.get(tripRepositoryProvider);
    final result = await repo.updateTrip(id: tripId, name: name);
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (trip) {
        final controller = tsx.get(planControllerProvider(tripId).notifier);
        final current = tsx.get(planControllerProvider(tripId)).value?.trip;
        final updated =
            current?.mergeUpdatedTrip(trip) ?? TripCardEntity.fromNewTrip(trip);
        controller.applyTripUpdated(updated);
        tsx
            .get(globalEventBusProvider)
            .add(TripUpdatedDispatched(trip: updated));
        return updated;
      },
    );
  });
}

/// Selects a bundled cover. If the trip's previous cover was a custom
/// upload (never for a bundled `asset:` one), cleans up its now-orphaned
/// storage object after the switch succeeds — best-effort, never blocks
/// or fails the cover change itself (issue #81).
Future<TripCardEntity> runChangeCover({
  required WidgetRef ref,
  required String tripId,
  required String coverImagePath,
}) {
  return changeCoverMutation.run(ref, (tsx) async {
    final repo = tsx.get(tripRepositoryProvider);
    final previousCoverPath = tsx
        .get(planControllerProvider(tripId))
        .value
        ?.trip
        .coverImagePath;

    final result = await repo.updateTrip(
      id: tripId,
      coverImagePath: coverImagePath,
    );
    final updated = result.fold(
      (failure) => throw PresentationFailureException(failure),
      (trip) {
        final controller = tsx.get(planControllerProvider(tripId).notifier);
        final current = tsx.get(planControllerProvider(tripId)).value?.trip;
        final merged =
            current?.mergeUpdatedTrip(trip) ?? TripCardEntity.fromNewTrip(trip);
        controller.applyTripUpdated(merged);
        tsx
            .get(globalEventBusProvider)
            .add(TripUpdatedDispatched(trip: merged));
        return merged;
      },
    );

    if (previousCoverPath != null &&
        coverIdFromPath(previousCoverPath) == null) {
      await repo.deleteCoverImage(tripId);
    }

    return updated;
  });
}

/// Uploads a custom photo as the trip's cover. Unlike the create flow's
/// quiet degrade, a failure here surfaces normally (loud) — the trip
/// already exists, so retrying carries no duplicate-creation risk
/// (issue #81's plan comment).
Future<TripCardEntity> runUploadCover({
  required WidgetRef ref,
  required String tripId,
  required Uint8List bytes,
}) {
  return changeCoverMutation.run(ref, (tsx) async {
    final repo = tsx.get(tripRepositoryProvider);

    final uploaded = await repo.uploadCoverImage(tripId: tripId, bytes: bytes);
    final path = uploaded.fold(
      (failure) => throw PresentationFailureException(failure),
      (p) => p,
    );

    final result = await repo.updateTrip(id: tripId, coverImagePath: path);
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (trip) {
        final controller = tsx.get(planControllerProvider(tripId).notifier);
        final current = tsx.get(planControllerProvider(tripId)).value?.trip;
        final updated =
            current?.mergeUpdatedTrip(trip) ?? TripCardEntity.fromNewTrip(trip);
        controller.applyTripUpdated(updated);
        tsx
            .get(globalEventBusProvider)
            .add(TripUpdatedDispatched(trip: updated));
        return updated;
      },
    );
  });
}

Future<TripCardEntity> runShiftMemoryDates({
  required WidgetRef ref,
  required String tripId,
  required int deltaDays,
}) {
  return shiftMemoryDatesMutation.run(ref, (tsx) async {
    final repo = tsx.get(tripRepositoryProvider);
    final result = await repo.shiftTripDates(id: tripId, deltaDays: deltaDays);
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (trip) {
        final controller = tsx.get(planControllerProvider(tripId).notifier);
        final current = tsx.get(planControllerProvider(tripId)).value?.trip;
        final updated =
            current?.mergeUpdatedTrip(trip) ?? TripCardEntity.fromNewTrip(trip);
        controller.applyDatesShifted(updated, deltaDays);
        tsx
            .get(globalEventBusProvider)
            .add(TripUpdatedDispatched(trip: updated));
        return updated;
      },
    );
  });
}
