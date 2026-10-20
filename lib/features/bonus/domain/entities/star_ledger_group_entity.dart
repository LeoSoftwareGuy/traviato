import 'package:equatable/equatable.dart';

/// Where a star came from — `points_ledger.source`. Shown in this fixed
/// order on the Bonus page's star summary (#219).
enum StarSource {
  photo,
  note,
  quest,
  bonusTask;

  /// An unknown [value] (see [isKnownDbValue]) counts as a bonus task, so
  /// its stars still add up to the total instead of vanishing.
  static StarSource fromDbValue(String value) => switch (value) {
    'photo' => photo,
    'note' => note,
    'quest' => quest,
    _ => bonusTask,
  };

  static bool isKnownDbValue(String value) =>
      const {'photo', 'note', 'quest', 'bonus_task'}.contains(value);
}

/// One `star_breakdown_view` row: the stars a memory earned from one
/// source. [tripId] is null for rows orphaned before #247 made the ledger
/// cascade on memory delete.
class StarLedgerGroupEntity extends Equatable {
  const StarLedgerGroupEntity({
    required this.tripId,
    required this.source,
    required this.entryCount,
    required this.points,
  });

  final String? tripId;
  final StarSource source;
  final int entryCount;
  final int points;

  @override
  List<Object?> get props => [tripId, source, entryCount, points];
}
