import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/profile_stats_entity.dart';
import '../../domain/entities/achievement_entity.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileState extends Equatable {
  const ProfileState({
    required this.profile,
    required this.stats,
    required this.achievements,
  });

  final ProfileEntity profile;
  final ProfileStatsEntity stats;
  final List<AchievementEntity> achievements;

  int get earnedCount => achievements.where((a) => a.isEarned).length;

  ProfileState copyWith({ProfileEntity? profile}) => ProfileState(
    profile: profile ?? this.profile,
    stats: stats,
    achievements: achievements,
  );

  @override
  List<Object?> get props => [profile, stats, achievements];
}
