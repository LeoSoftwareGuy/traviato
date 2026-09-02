import 'package:equatable/equatable.dart';

/// A `profiles` row (docs/data-model.md). There is only ever one identity
/// string, `username` — the Profile screen's "name" and "@handle" are two
/// renderings of it, not separate fields (issue #96's plan comment).
class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.id,
    this.username,
    this.bio,
    this.avatarUrl,
    required this.createdAt,
  });

  final String id;
  final String? username;
  final String? bio;

  /// Either a signed `avatars` storage path (this app's own upload) or a
  /// full external URL (an OAuth provider's picture, set at signup) — the
  /// avatar-rendering widget distinguishes by prefix, same convention as
  /// `trips.cover_image_path`'s `asset:`/storage-path split.
  final String? avatarUrl;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, username, bio, avatarUrl, createdAt];
}
