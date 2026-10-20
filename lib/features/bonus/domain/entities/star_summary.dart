import 'package:equatable/equatable.dart';

import '../../../trip/domain/entities/trip_card_entity.dart';
import 'star_ledger_group_entity.dart';

/// Stars from one source: [count] ledger entries worth [points] in total.
class StarSourceTotal extends Equatable {
  const StarSourceTotal({
    required this.source,
    required this.count,
    required this.points,
  });

  final StarSource source;
  final int count;
  final int points;

  @override
  List<Object?> get props => [source, count, points];
}

/// Stars earned on one memory. [trip] is null for the "Earlier memories"
/// row — stars whose memory no longer exists.
class StarMemoryTotal extends Equatable {
  const StarMemoryTotal({required this.trip, required this.points});

  final TripCardEntity? trip;
  final int points;

  bool get isEarlierMemories => trip == null;

  @override
  List<Object?> get props => [trip, points];
}

/// The Bonus page's star summary (#219): by type first, then by memory.
class StarSummary extends Equatable {
  const StarSummary({
    required this.totalStars,
    required this.bySource,
    required this.byMemory,
    required this.memoryCount,
  });

  const StarSummary.empty()
    : totalStars = 0,
      bySource = const [],
      byMemory = const [],
      memoryCount = 0;

  /// Folds ledger [groups] into totals. Groups whose memory isn't among
  /// [trips] (null, or deleted since) collapse into one "Earlier memories"
  /// row that [memoryCount] leaves out.
  factory StarSummary.fromGroups(
    List<StarLedgerGroupEntity> groups,
    List<TripCardEntity> trips,
  ) {
    final tripsById = {for (final t in trips) t.id: t};
    final countBySource = <StarSource, int>{};
    final pointsBySource = <StarSource, int>{};
    final pointsByTrip = <String, int>{};
    var earlierPoints = 0;
    var total = 0;

    for (final g in groups) {
      total += g.points;
      countBySource[g.source] = (countBySource[g.source] ?? 0) + g.entryCount;
      pointsBySource[g.source] = (pointsBySource[g.source] ?? 0) + g.points;
      final tripId = g.tripId;
      if (tripId != null && tripsById.containsKey(tripId)) {
        pointsByTrip[tripId] = (pointsByTrip[tripId] ?? 0) + g.points;
      } else {
        earlierPoints += g.points;
      }
    }

    final byMemory = [
      for (final e in pointsByTrip.entries)
        if (e.value > 0)
          StarMemoryTotal(trip: tripsById[e.key], points: e.value),
      if (earlierPoints > 0) StarMemoryTotal(trip: null, points: earlierPoints),
    ]..sort((a, b) => b.points.compareTo(a.points));

    return StarSummary(
      totalStars: total,
      bySource: [
        for (final source in StarSource.values)
          if ((pointsBySource[source] ?? 0) > 0)
            StarSourceTotal(
              source: source,
              count: countBySource[source]!,
              points: pointsBySource[source]!,
            ),
      ],
      byMemory: byMemory,
      memoryCount: byMemory.where((m) => !m.isEarlierMemories).length,
    );
  }

  final int totalStars;

  /// Non-zero sources, in [StarSource] order.
  final List<StarSourceTotal> bySource;

  /// Most stars first.
  final List<StarMemoryTotal> byMemory;

  /// Memories that still exist and earned at least one star.
  final int memoryCount;

  bool get hasStars => totalStars > 0;

  @override
  List<Object?> get props => [totalStars, bySource, byMemory, memoryCount];
}
