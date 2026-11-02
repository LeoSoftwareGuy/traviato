import 'package:equatable/equatable.dart';

import '../../../../core/constants/app_constants.dart';

/// A `trip_share_links` row (#309): the memory's public link,
/// `storyni.app/m/{slug}`. One active link per memory at a time.
class ShareLink extends Equatable {
  const ShareLink({
    required this.id,
    required this.tripId,
    required this.slug,
    required this.createdAt,
    this.revokedAt,
    this.previewBuiltAt,
    this.previewPhotoCount = 0,
  });

  final String id;
  final String tripId;
  final String slug;
  final DateTime createdAt;
  final DateTime? revokedAt;

  /// When the app last uploaded the teaser copies; null = not built yet
  /// (the web page then shows a title-only teaser).
  final DateTime? previewBuiltAt;

  /// How many teaser photos the last build uploaded.
  final int previewPhotoCount;

  bool get isRevoked => revokedAt != null;
  bool get isPreviewBuilt => previewBuiltAt != null;

  String get url => AppConstants.shareUrl(slug);

  @override
  List<Object?> get props => [
    id,
    tripId,
    slug,
    createdAt,
    revokedAt,
    previewBuiltAt,
    previewPhotoCount,
  ];
}
