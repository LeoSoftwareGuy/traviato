import 'package:equatable/equatable.dart';

/// A shared memory's public teaser (#309's `get_shared_memory_preview`),
/// with its images resolved to public `share-previews` URLs. Never holds
/// notes, places' coordinates, expenses, quests or ids.
class SharedMemoryPreview extends Equatable {
  const SharedMemoryPreview({
    required this.slug,
    required this.title,
    this.destination,
    required this.startDate,
    required this.endDate,
    required this.dayCount,
    required this.photoCount,
    required this.hasFilm,
    this.coverUrl,
    this.photoUrls = const [],
    this.ownerName,
    this.ownerHandle,
    this.ownerAvatarUrl,
    required this.isPreviewReady,
  });

  final String slug;
  final String title;
  final String? destination;
  final DateTime startDate;
  final DateTime endDate;
  final int dayCount;

  /// Every photo of the memory — the "+N more" hook.
  final int photoCount;

  /// Whether the memory has a kept film.
  final bool hasFilm;
  final String? coverUrl;

  /// Up to 6 teaser photos; empty until the owner's app built them.
  final List<String> photoUrls;
  final String? ownerName;
  final String? ownerHandle;

  /// Only an external (OAuth) picture; uploaded avatars stay private.
  final String? ownerAvatarUrl;
  final bool isPreviewReady;

  @override
  List<Object?> get props => [
    slug,
    title,
    destination,
    startDate,
    endDate,
    dayCount,
    photoCount,
    hasFilm,
    coverUrl,
    photoUrls,
    ownerName,
    ownerHandle,
    ownerAvatarUrl,
    isPreviewReady,
  ];
}
