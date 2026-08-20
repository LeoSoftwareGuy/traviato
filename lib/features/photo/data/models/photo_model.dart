import '../../domain/entities/photo_entity.dart';

class PhotoModel extends PhotoEntity {
  const PhotoModel({
    required super.id,
    required super.tripId,
    super.dayDate,
    required super.storagePath,
    super.caption,
    super.lat,
    super.lng,
    super.placeText,
    super.peopleTags,
    super.takenAt,
    required super.createdAt,
    super.imageUrl,
  });

  factory PhotoModel.fromJson(Map<String, dynamic> json) => PhotoModel(
    id: json['id'] as String,
    tripId: json['trip_id'] as String,
    dayDate: json['day_date'] == null
        ? null
        : DateTime.parse(json['day_date'] as String),
    storagePath: json['storage_path'] as String,
    caption: json['caption'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    placeText: json['place_text'] as String?,
    peopleTags:
        (json['people_tags'] as List<dynamic>?)?.cast<String>() ?? const [],
    takenAt: json['taken_at'] == null
        ? null
        : DateTime.parse(json['taken_at'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  /// The row carries no `image_url` column — this attaches the signed URL
  /// resolved separately via `createSignedUrlsResult`.
  PhotoModel withImageUrl(String? imageUrl) => PhotoModel(
    id: id,
    tripId: tripId,
    dayDate: dayDate,
    storagePath: storagePath,
    caption: caption,
    lat: lat,
    lng: lng,
    placeText: placeText,
    peopleTags: peopleTags,
    takenAt: takenAt,
    createdAt: createdAt,
    imageUrl: imageUrl,
  );
}
