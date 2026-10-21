import 'dart:typed_data';

import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../bonus/presentation/controllers/bonus_tray_controller.dart';
import '../../../journal/presentation/controllers/journal_controller.dart';
import '../../../trip/domain/entities/trip_card_entity.dart';
import '../../../trip/domain/entities/trip_dates_change_entity.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../../trip/presentation/widgets/cover_options.dart';
import '../controllers/plan_controller.dart';

/// The manage-memory-sheet edits (rename, cover change, dates). Live
/// alongside the Plan feature — not `trip_mutations.dart` — because each
/// one updates `planControllerProvider(tripId)` directly for instant
/// feedback on the screen that triggered it, the same pattern the quest
/// mutations already use.
final renameMemoryMutation = Mutation<TripCardEntity>();
final changeCoverMutation = Mutation<TripCardEntity>();
final previewMemoryDatesMutation = Mutation<TripDatesChangeEntity>();
final editMemoryDatesMutation = Mutation<TripDatesChangeEntity>();

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

/// Asks the server what saving these dates would delete, without changing
/// anything (#271) — the Manage sheet shows its two-step warning from this.
Future<TripDatesChangeEntity> runPreviewMemoryDates({
  required WidgetRef ref,
  required String tripId,
  required DateTime startDate,
  required DateTime endDate,
}) {
  return previewMemoryDatesMutation.run(ref, (tsx) async {
    final result = await tsx
        .get(tripRepositoryProvider)
        .previewTripDates(id: tripId, startDate: startDate, endDate: endDate);
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (impact) => impact,
    );
  });
}

/// Saves new dates via `set_trip_dates` (#271): quests move with the start
/// date, notes/photos/bonus tasks keep theirs, and anything outside the new
/// range is deleted. Plan updates in place; Journal and the bonus tray are
/// refetched, since their notes/photos/tasks may have been deleted.
Future<TripDatesChangeEntity> runEditMemoryDates({
  required WidgetRef ref,
  required String tripId,
  required DateTime startDate,
  required DateTime endDate,
}) {
  return editMemoryDatesMutation.run(ref, (tsx) async {
    final previousStart = tsx
        .get(planControllerProvider(tripId))
        .value
        ?.trip
        .startDate;
    final result = await tsx
        .get(tripRepositoryProvider)
        .setTripDates(id: tripId, startDate: startDate, endDate: endDate);
    final change = result.fold(
      (failure) => throw PresentationFailureException(failure),
      (change) => change,
    );

    final controller = tsx.get(planControllerProvider(tripId).notifier);
    final current = tsx.get(planControllerProvider(tripId)).value?.trip;
    final trip = change.trip;
    if (trip != null) {
      final updated =
          current?.mergeUpdatedTrip(
            trip,
            removedPhotos: change.photos,
            removedQuests: change.quests,
          ) ??
          TripCardEntity.fromNewTrip(trip);
      controller.applyDatesChanged(
        updated,
        previousStart == null ? 0 : _daysBetween(previousStart, startDate),
      );
      tsx.get(globalEventBusProvider).add(TripUpdatedDispatched(trip: updated));
    }
    if (change.removesAnything) {
      // Deleted notes/photos take their stars back; totals refetch on this.
      tsx.get(globalEventBusProvider).add(const StarsAwardedDispatched());
    }
    ref
      ..invalidate(journalControllerProvider(tripId))
      ..invalidate(bonusTrayControllerProvider(tripId));
    return change;
  });
}

/// Whole calendar days from [from] to [to]. Compared as UTC dates so a DST
/// change in between can't turn a day into 23 hours and round to zero.
int _daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
