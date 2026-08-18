import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_stats_provider.g.dart';

/// Home stats-bar totals (Memories / Places / Days) and the stars badge.
class ProfileStats extends Equatable {
  const ProfileStats({
    required this.memories,
    required this.places,
    required this.days,
    required this.stars,
  });

  const ProfileStats.zero() : this(memories: 0, places: 0, days: 0, stars: 0);

  final int memories;
  final int places;
  final int days;
  final int stars;

  @override
  List<Object?> get props => [memories, places, days, stars];
}

/// Stubbed until `profile_stats_view` lands (data-model.md, milestone 3).
/// This is the single place that will swap to a real repository call.
@riverpod
ProfileStats profileStats(Ref ref) => const ProfileStats.zero();
