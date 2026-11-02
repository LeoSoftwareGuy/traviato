import '../../domain/entities/share_link.dart';

class ShareLinkModel extends ShareLink {
  const ShareLinkModel({
    required super.id,
    required super.tripId,
    required super.slug,
    required super.createdAt,
    super.revokedAt,
    super.previewBuiltAt,
    super.previewPhotoCount,
  });

  factory ShareLinkModel.fromJson(Map<String, dynamic> json) => ShareLinkModel(
    id: json['id'] as String,
    tripId: json['trip_id'] as String,
    slug: json['slug'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    revokedAt: _parseTime(json['revoked_at']),
    previewBuiltAt: _parseTime(json['preview_built_at']),
    previewPhotoCount: (json['preview_photo_count'] as num?)?.toInt() ?? 0,
  );

  static DateTime? _parseTime(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}
