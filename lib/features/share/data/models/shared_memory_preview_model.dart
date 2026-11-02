import '../../domain/entities/shared_memory_preview.dart';

class SharedMemoryPreviewModel extends SharedMemoryPreview {
  const SharedMemoryPreviewModel({
    required super.slug,
    required super.title,
    super.destination,
    required super.startDate,
    required super.endDate,
    required super.dayCount,
    required super.photoCount,
    required super.hasFilm,
    super.coverUrl,
    super.photoUrls,
    super.ownerName,
    super.ownerHandle,
    super.ownerAvatarUrl,
    required super.isPreviewReady,
  });

  /// [publicUrl] turns a `share-previews` path into its public URL (the RPC
  /// returns paths — SQL doesn't know the project's URL).
  factory SharedMemoryPreviewModel.fromJson(
    Map<String, dynamic> json, {
    required String Function(String path) publicUrl,
  }) {
    final owner = (json['owner'] as Map?)?.cast<String, dynamic>() ?? const {};
    final coverPath = json['cover_path'] as String?;
    return SharedMemoryPreviewModel(
      slug: json['slug'] as String,
      title: json['title'] as String,
      destination: _nonBlank(json['destination']),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      dayCount: (json['day_count'] as num).toInt(),
      photoCount: (json['photo_count'] as num).toInt(),
      hasFilm: json['has_film'] as bool? ?? false,
      coverUrl: coverPath == null ? null : publicUrl(coverPath),
      photoUrls: [
        for (final path in (json['photos'] as List? ?? const []).cast<String>())
          publicUrl(path),
      ],
      ownerName: _nonBlank(owner['display_name']),
      ownerHandle: _nonBlank(owner['handle']),
      ownerAvatarUrl: _nonBlank(owner['avatar_url']),
      isPreviewReady: json['preview_ready'] as bool? ?? false,
    );
  }

  static String? _nonBlank(Object? value) {
    final text = (value as String?)?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
