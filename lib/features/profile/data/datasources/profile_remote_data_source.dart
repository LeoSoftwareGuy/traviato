import 'dart:typed_data';

import '../models/achievement_template_model.dart';
import '../models/profile_model.dart';

abstract interface class ProfileRemoteDataSource {
  Future<ProfileModel> getProfile();

  Future<ProfileModel> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  });

  /// Ordered by `position` — the design's fixed badge display order.
  Future<List<AchievementTemplateModel>> getAchievementTemplates();

  /// `template_id -> earned_at` for every achievement this user has earned.
  Future<Map<int, DateTime>> getEarnedAchievements();

  Future<String> uploadAvatar(Uint8List bytes);

  Future<String> getAvatarUrl(String storagePath);
}
