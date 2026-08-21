import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/photo/domain/repositories/photo_repository.dart';

class FakePhotoRepository implements PhotoRepository {
  Either<Failure, List<PhotoEntity>>? photosResult;
  var getPhotosCallCount = 0;

  @override
  Future<Either<Failure, List<PhotoEntity>>> getPhotosForTrip(
    String tripId,
  ) async {
    getPhotosCallCount++;
    return photosResult ?? const Right([]);
  }
}

PhotoEntity buildPhotoEntity({
  String id = 'p1',
  String tripId = 't1',
  DateTime? dayDate,
  String storagePath = 'u1/t1/p1.jpg',
  String? imageUrl,
}) {
  return PhotoEntity(
    id: id,
    tripId: tripId,
    dayDate: dayDate,
    storagePath: storagePath,
    createdAt: DateTime(2026, 1, 1),
    imageUrl: imageUrl,
  );
}
