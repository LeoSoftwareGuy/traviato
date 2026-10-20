import 'package:flutter/foundation.dart';

import '../../domain/entities/star_ledger_group_entity.dart';

/// Maps a `star_breakdown_view` row.
class StarLedgerGroupModel extends StarLedgerGroupEntity {
  const StarLedgerGroupModel({
    required super.tripId,
    required super.source,
    required super.entryCount,
    required super.points,
  });

  factory StarLedgerGroupModel.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as String;
    if (!StarSource.isKnownDbValue(source)) {
      debugPrint('Unknown points_ledger source "$source"; counted as bonus.');
    }
    return StarLedgerGroupModel(
      tripId: json['trip_id'] as String?,
      source: StarSource.fromDbValue(source),
      entryCount: (json['entry_count'] as num).toInt(),
      points: (json['points_total'] as num).toInt(),
    );
  }
}
