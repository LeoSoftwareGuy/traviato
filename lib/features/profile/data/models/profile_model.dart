import '../../domain/entities/profile_entity.dart';

/// Maps a `profiles` row.
class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    super.username,
    super.bio,
    super.avatarUrl,
    required super.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json['id'] as String,
    username: json['username'] as String?,
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
