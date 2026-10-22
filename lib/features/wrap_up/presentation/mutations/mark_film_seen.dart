import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../trip/presentation/providers/trip_providers.dart';

/// Records that a kept memory's film was watched through (#279) and tells
/// Home, so its next tap opens the Kept Memory page. Not a `Mutation`: it
/// runs in the background with no UI of its own, and a failure only means
/// the film plays once more — logged, never shown.
Future<void> markFilmSeen({
  required WidgetRef ref,
  required String tripId,
}) async {
  final repo = ref.read(tripRepositoryProvider);
  final bus = ref.read(globalEventBusProvider);
  final result = await repo.markFilmSeen(tripId);
  result.fold(
    (failure) => debugPrint('Marking film seen failed for $tripId: $failure'),
    (_) => bus.add(FilmSeenDispatched(tripId: tripId, seenAt: DateTime.now())),
  );
}
