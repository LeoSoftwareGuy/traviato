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

Future<TripCardEntity> runCreateMemory({
  required WidgetRef ref,
  required String name,
  String? destination,
  DateTime? startDate,
  DateTime? endDate,
  List<String> vibes = const [],
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
    );
    return result.fold(
      (failure) => throw PresentationFailureException(failure),
      (
        trip,
      ) {
        final card = TripCardEntity.fromNewTrip(trip);
        tsx.get(globalEventBusProvider).add(TripCreatedDispatched(trip: card));
        return card;
      },
    );
  });
}
