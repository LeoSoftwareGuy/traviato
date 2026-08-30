import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../domain/entities/trip_card_entity.dart';
import '../providers/trip_providers.dart';

const _freeTierMemoryLimit = 3;

final createMemoryMutation = Mutation<TripCardEntity>();
final deleteMemoryMutation = Mutation<void>();

Future<TripCardEntity> runCreateMemory({
  required WidgetRef ref,
  required String name,
  String? destination,
  DateTime? startDate,
  DateTime? endDate,
  List<String> vibes = const [],
  String? coverImagePath,
  Uint8List? coverImageBytes,
}) {
  return createMemoryMutation.run(ref, (tsx) async {
    final repo = tsx.get(tripRepositoryProvider);

    // App-side free-tier check (server-side enforcement is post-MVP). Only
    // block on a count we actually know — a failed read shouldn't stop
    // someone from creating a memory.
    final existing = await repo.getTripCards();
    final tooManyMemories = existing.fold(
      (_) => false,
      (trips) => trips.length >= _freeTierMemoryLimit,
    );
    if (tooManyMemories) {
      throw PresentationFailureException(const FreeTierLimitFailure());
    }

    final result = await repo.createTrip(
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      vibes: vibes,
      coverImagePath: coverImagePath,
    );
    var card = result.fold(
      (failure) => throw PresentationFailureException(failure),
      (trip) => TripCardEntity.fromNewTrip(trip),
    );

    // Trip creation and a custom cover upload aren't atomic. Deliberately
    // quiet on failure here (never throws) rather than the usual
    // PresentationFailureException: creation already succeeded, so a loud
    // failure would leave the user on a form whose "stay and retry" UX
    // would create a *second* trip — the bundled coverImagePath set above
    // is already a sensible fallback (issue #81's plan comment).
    if (coverImageBytes != null) {
      final uploaded = await repo.uploadCoverImage(
        tripId: card.id,
        bytes: coverImageBytes,
      );
      final path = uploaded.fold((failure) {
        debugPrint('Cover upload failed, keeping bundled fallback: $failure');
        return null;
      }, (p) => p);
      if (path != null) {
        final updated = await repo.updateTrip(
          id: card.id,
          coverImagePath: path,
        );
        card = updated.fold((failure) {
          debugPrint(
            'Cover-path update failed, keeping bundled fallback: '
            '$failure',
          );
          return card;
        }, card.mergeUpdatedTrip);
      }
    }

    tsx.get(globalEventBusProvider).add(TripCreatedDispatched(trip: card));
    return card;
  });
}

Future<void> runDeleteMemory({required WidgetRef ref, required String tripId}) {
  return deleteMemoryMutation.run(ref, (tsx) async {
    final repo = tsx.get(tripRepositoryProvider);
    (await repo.deleteTrip(tripId)).fold(
      (failure) => throw PresentationFailureException(failure),
      (_) => tsx
          .get(globalEventBusProvider)
          .add(TripDeletedDispatched(tripId: tripId)),
    );
  });
}
