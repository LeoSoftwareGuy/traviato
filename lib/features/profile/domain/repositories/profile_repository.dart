import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../home/domain/entities/profile_stats_entity.dart';
import '../entities/achievement_entity.dart';
import '../entities/profile_entity.dart';

abstract interface class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();

  /// Plain authenticated update. Pass only the field(s) being changed.
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  });

  /// The full `achievement_templates` catalog, joined with which ones this
  /// user has earned and each one's current progress against [stats] — see
  /// `AchievementEntity`'s doc comment for how the join is done. Takes
  /// [stats] rather than fetching it itself so a caller already loading
  /// `profile_stats_view` for the stats row (`ProfileStatsRepository`)
  /// doesn't pay for it twice.
  Future<Either<Failure, List<AchievementEntity>>> getAchievements(
    ProfileStatsEntity stats,
  );

  /// Uploads [bytes] as this user's avatar at a stable `{user_id}/avatar.jpg`
  /// path in the `avatars` bucket (issue #96). Returns the raw storage path
  /// to persist via [updateProfile]; does not update the profile row itself.
  Future<Either<Failure, String>> uploadAvatar(Uint8List bytes);

  /// Signs a stored avatar path (as persisted by [uploadAvatar]) into a
  /// short-lived URL the UI can load — `avatars` is a private bucket. Never
  /// call this on an OAuth-provided `avatarUrl` (already a public URL).
  Future<Either<Failure, String>> getAvatarUrl(String storagePath);
}
