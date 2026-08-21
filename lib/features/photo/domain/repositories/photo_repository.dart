import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/photo_entity.dart';

/// Read path only for now — the write side (upload) arrives with the photo
/// capture issue.
abstract interface class PhotoRepository {
  Future<Either<Failure, List<PhotoEntity>>> getPhotosForTrip(String tripId);
}
