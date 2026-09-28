import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/photo_entity.dart';

abstract interface class PhotoRepository {
  Future<Either<Failure, List<PhotoEntity>>> getPhotosForTrip(String tripId);

  /// Uploads [bytes] to the trip's storage folder, inserts the row, and
  /// awards ✦2 for the trip (award failure does not fail the upload).
  Future<Either<Failure, PhotoEntity>> addPhoto({
    required String tripId,
    DateTime? dayDate,
    required Uint8List bytes,
    required String fileExtension,
    String? caption,
    String? placeText,
    double? lat,
    double? lng,
    DateTime? takenAt,
  });

  /// Deletes the photo's row, then its storage file (#165). The photo's ✦2
  /// is taken back, unless it completed a bonus task — then all its stars
  /// stay. Only a failed row delete is a [Failure] — once the row is
  /// gone the photo is gone for the user, so a failed file removal is
  /// logged rather than surfaced.
  Future<Either<Failure, void>> deletePhoto(PhotoEntity photo);
}
