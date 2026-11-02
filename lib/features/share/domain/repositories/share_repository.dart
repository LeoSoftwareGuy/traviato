import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../../../photo/domain/entities/photo_entity.dart';
import '../entities/og_card_content.dart';
import '../entities/share_link.dart';

abstract interface class ShareRepository {
  /// The memory's active link, made if there is none (idempotent).
  Future<Either<Failure, ShareLink>> createLink(String tripId);

  /// The memory's active link, or null when it isn't shared.
  Future<Either<Failure, ShareLink?>> getActiveLink(String tripId);

  /// Turns [link] off, then removes its public preview files. A failed
  /// file removal doesn't fail the revoke: the preview RPC already returns
  /// null for the slug.
  Future<Either<Failure, void>> revokeLink(ShareLink link);

  /// Uploads [photos] (already in teaser order, ≤ 6) as `{slug}/0.jpg` …
  /// plus `{slug}/og.jpg`, removes teaser files a previous, bigger build
  /// left behind, and marks the link built.
  Future<Either<Failure, void>> buildPreview({
    required ShareLink link,
    required List<PhotoEntity> photos,
    required OgCardContent og,
  });
}
