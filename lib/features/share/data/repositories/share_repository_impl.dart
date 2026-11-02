import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../../domain/entities/og_card_content.dart';
import '../../domain/entities/share_link.dart';
import '../../domain/entities/shared_memory_preview.dart';
import '../../domain/repositories/share_repository.dart';
import '../../domain/share_teaser_photos.dart';
import '../datasources/share_remote_data_source.dart';
import '../services/share_image_service.dart';

/// Every file a link's preview can have: the teaser copies and og.jpg.
List<String> sharePreviewFiles(String slug) => [
  for (var n = 0; n < shareTeaserPhotoCount; n++) '$slug/$n.jpg',
  '$slug/og.jpg',
];

class ShareRepositoryImpl implements ShareRepository {
  ShareRepositoryImpl({
    required ShareRemoteDataSource remote,
    required ShareImageService images,
  }) : _remote = remote,
       _images = images;

  final ShareRemoteDataSource _remote;
  final ShareImageService _images;

  Future<Either<Failure, T>> _run<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ShareLink>> createLink(String tripId) =>
      _run(() => _remote.createLink(tripId));

  @override
  Future<Either<Failure, ShareLink?>> getActiveLink(String tripId) =>
      _run(() => _remote.getActiveLink(tripId));

  @override
  Future<Either<Failure, SharedMemoryPreview?>> getSharedPreview(
    String slug,
  ) => _run(() => _remote.getSharedPreview(slug));

  @override
  Future<Either<Failure, String?>> findOwnTripIdForSlug(String slug) =>
      _run(() => _remote.findOwnTripIdForSlug(slug));

  @override
  Future<Either<Failure, void>> revokeLink(ShareLink link) async {
    final revoked = await _run(() => _remote.revokeLink(link.tripId));
    if (revoked.isLeft()) return revoked;
    try {
      await _remote.removePreviewFiles(sharePreviewFiles(link.slug));
    } on AppException catch (e) {
      debugPrint('Share preview files left for ${link.slug}: ${e.message}');
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> buildPreview({
    required ShareLink link,
    required List<PhotoEntity> photos,
    required OgCardContent og,
  }) => _run(() async {
    final teaser = photos.take(shareTeaserPhotoCount).toList();
    Uint8List? cover;
    for (final (n, photo) in teaser.indexed) {
      final copy = await _images.downscale(
        await _remote.downloadPhoto(photo.storagePath),
      );
      cover ??= copy;
      await _remote.uploadPreviewFile('${link.slug}/$n.jpg', copy);
    }
    await _remote.uploadPreviewFile(
      '${link.slug}/og.jpg',
      await _images.renderOgCard(cover: cover, content: og),
    );
    if (link.previewPhotoCount > teaser.length) {
      await _remote.removePreviewFiles([
        for (var n = teaser.length; n < link.previewPhotoCount; n++)
          '${link.slug}/$n.jpg',
      ]);
    }
    await _remote.markPreviewBuilt(link.id, teaser.length);
  });
}
