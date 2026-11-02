import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/share/domain/entities/og_card_content.dart';
import 'package:traviato/features/share/domain/entities/share_link.dart';
import 'package:traviato/features/share/domain/entities/shared_memory_preview.dart';
import 'package:traviato/features/share/domain/repositories/share_repository.dart';

/// Configurable [ShareRepository] for widget tests; records calls.
class FakeShareRepository implements ShareRepository {
  Either<Failure, ShareLink> createResult = Right(buildShareLink());
  Either<Failure, ShareLink?> activeResult = const Right(null);
  Either<Failure, void> revokeResult = const Right(null);
  Either<Failure, SharedMemoryPreview?> previewResult = Right(
    buildSharedMemoryPreview(),
  );
  Either<Failure, String?> ownTripIdResult = const Right(null);

  final calls = <String>[];

  @override
  Future<Either<Failure, ShareLink>> createLink(String tripId) async {
    calls.add('create $tripId');
    return createResult;
  }

  @override
  Future<Either<Failure, ShareLink?>> getActiveLink(String tripId) async =>
      activeResult;

  @override
  Future<Either<Failure, void>> revokeLink(ShareLink link) async {
    calls.add('revoke ${link.slug}');
    return revokeResult;
  }

  @override
  Future<Either<Failure, void>> buildPreview({
    required ShareLink link,
    required List<PhotoEntity> photos,
    required OgCardContent og,
  }) async {
    calls.add('build ${link.slug}');
    return const Right(null);
  }

  @override
  Future<Either<Failure, SharedMemoryPreview?>> getSharedPreview(
    String slug,
  ) async {
    calls.add('preview $slug');
    return previewResult;
  }

  @override
  Future<Either<Failure, String?>> findOwnTripIdForSlug(String slug) async {
    calls.add('own $slug');
    return ownTripIdResult;
  }
}

ShareLink buildShareLink({
  String id = 'l1',
  String tripId = 't1',
  String slug = 'k7Qm2xPa9c',
  DateTime? revokedAt,
  DateTime? previewBuiltAt,
}) => ShareLink(
  id: id,
  tripId: tripId,
  slug: slug,
  createdAt: DateTime.utc(2026, 11, 2),
  revokedAt: revokedAt,
  previewBuiltAt: previewBuiltAt,
);

SharedMemoryPreview buildSharedMemoryPreview({
  String title = 'One long road',
  String? ownerName = 'Leo',
  bool hasFilm = true,
  List<String> photoUrls = const [],
}) => SharedMemoryPreview(
  slug: 'k7Qm2xPa9c',
  title: title,
  destination: 'Highlands',
  startDate: DateTime(2026, 8, 12),
  endDate: DateTime(2026, 8, 16),
  dayCount: 5,
  photoCount: 84,
  hasFilm: hasFilm,
  photoUrls: photoUrls,
  ownerName: ownerName,
  ownerHandle: ownerName?.toLowerCase(),
  isPreviewReady: photoUrls.isNotEmpty,
);
