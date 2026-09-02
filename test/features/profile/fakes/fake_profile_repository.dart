import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/home/domain/entities/profile_stats_entity.dart';
import 'package:traviato/features/profile/domain/entities/achievement_entity.dart';
import 'package:traviato/features/profile/domain/entities/profile_entity.dart';
import 'package:traviato/features/profile/domain/repositories/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  Either<Failure, ProfileEntity>? profileResult;
  Either<Failure, ProfileEntity>? updateProfileResult;
  Either<Failure, List<AchievementEntity>>? achievementsResult;
  Either<Failure, String>? uploadAvatarResult;
  Either<Failure, String>? avatarUrlResult;

  var getProfileCallCount = 0;
  var getAchievementsCallCount = 0;
  var uploadAvatarCallCount = 0;
  Map<String, dynamic>? lastUpdateArgs;

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    getProfileCallCount++;
    return profileResult ?? Right(buildProfile());
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    lastUpdateArgs = {
      'username': username,
      'bio': bio,
      'avatarUrl': avatarUrl,
    };
    return updateProfileResult ??
        Right(buildProfile(username: username, bio: bio, avatarUrl: avatarUrl));
  }

  @override
  Future<Either<Failure, List<AchievementEntity>>> getAchievements(
    ProfileStatsEntity stats,
  ) async {
    getAchievementsCallCount++;
    return achievementsResult ?? const Right([]);
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(Uint8List bytes) async {
    uploadAvatarCallCount++;
    return uploadAvatarResult ?? const Right('u1/avatar.jpg');
  }

  @override
  Future<Either<Failure, String>> getAvatarUrl(String storagePath) async {
    return avatarUrlResult ?? Right('https://example.com/$storagePath');
  }
}

ProfileEntity buildProfile({
  String id = 'u1',
  String? username = 'ada',
  String? bio,
  String? avatarUrl,
  DateTime? createdAt,
}) {
  return ProfileEntity(
    id: id,
    username: username,
    bio: bio,
    avatarUrl: avatarUrl,
    createdAt: createdAt ?? DateTime(2024, 3, 1),
  );
}

AchievementEntity buildAchievement({
  int id = 1,
  String code = 'first_adventure',
  String title = 'First Adventure',
  String description = 'Log your first memory.',
  AchievementMetric metric = AchievementMetric.trips,
  int target = 1,
  int position = 1,
  int currentValue = 0,
  DateTime? earnedAt,
}) {
  return AchievementEntity(
    id: id,
    code: code,
    title: title,
    description: description,
    metric: metric,
    target: target,
    position: position,
    currentValue: currentValue,
    earnedAt: earnedAt,
  );
}
