import 'package:equatable/equatable.dart';

import 'trip_entity.dart';

/// What changing a memory's dates removes (#271): the per-type counts of
/// rows that fall outside the new range. From a preview (dry run) [trip]
/// is null; from a save it's the updated trip.
class TripDatesChangeEntity extends Equatable {
  const TripDatesChangeEntity({
    required this.quests,
    required this.notes,
    required this.photos,
    required this.bonusTasks,
    this.trip,
  });

  final int quests;
  final int notes;
  final int photos;
  final int bonusTasks;
  final TripEntity? trip;

  /// Whether the change deletes anything — if not, it saves without the
  /// two-step warning.
  bool get removesAnything =>
      quests > 0 || notes > 0 || photos > 0 || bonusTasks > 0;

  @override
  List<Object?> get props => [quests, notes, photos, bonusTasks, trip];
}
