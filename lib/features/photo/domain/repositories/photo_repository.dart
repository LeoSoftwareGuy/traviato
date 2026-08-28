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
}
