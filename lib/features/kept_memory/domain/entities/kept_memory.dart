import 'package:equatable/equatable.dart';

import '../../../trip/domain/entities/trip_card_entity.dart';
import 'kept_memory_day.dart';
import 'kept_memory_photo.dart';
import 'kept_memory_plan_item.dart';

/// Everything the Kept Memory page shows (#279): the trip, its days as
/// chapters, every photo in viewer order, and the plan.
class KeptMemory extends Equatable {
  const KeptMemory({
    required this.trip,
    required this.days,
    required this.photos,
    required this.plan,
  });

  /// Title, cover, dates, kept date ([TripCardEntity.wrapUpPublishedAt])
  /// and star total ([TripCardEntity.stars], the sum of `points_ledger`).
  final TripCardEntity trip;

  /// Only days with at least one photo or note, in day order.
  final List<KeptMemoryDay> days;

  /// Every photo across every day, in day order then time order — the
  /// viewer's list.
  final List<KeptMemoryPhoto> photos;

  /// Quests by day then position. Empty when the memory had no plan.
  final List<KeptMemoryPlanItem> plan;

  int get photoCount => photos.length;
  int get noteCount => days.fold(0, (sum, day) => sum + day.notes.length);
  int get planDoneCount => plan.where((item) => item.isDone).length;

  /// Days in the memory (its date range), not just days with content.
  int get dayCount => trip.durationDays ?? days.length;

  @override
  List<Object?> get props => [trip, days, photos, plan];
}
