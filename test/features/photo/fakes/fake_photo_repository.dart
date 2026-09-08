import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/photo/domain/entities/photo_entity.dart';
import 'package:traviato/features/photo/domain/repositories/photo_repository.dart';

class FakePhotoRepository implements PhotoRepository {
  Either<Failure, List<PhotoEntity>>? photosResult;
  var getPhotosCallCount = 0;

  Either<Failure, PhotoEntity>? addPhotoResult;

  /// Per-call results, consumed in call order — takes precedence over
  /// [addPhotoResult] while entries remain, for tests exercising a batch
  /// where different calls need different outcomes (e.g. a partial
  /// failure among several uploads).
  List<Either<Failure, PhotoEntity>>? addPhotoResultsQueue;
  var addPhotoCallCount = 0;
  Uint8List? lastAddedBytes;
  DateTime? lastAddedDayDate;

  @override
  Future<Either<Failure, List<PhotoEntity>>> getPhotosForTrip(
    String tripId,
  ) async {
    getPhotosCallCount++;
    return photosResult ?? const Right([]);
  }

  @override
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
  }) async {
    final callIndex = addPhotoCallCount;
    addPhotoCallCount++;
    lastAddedBytes = bytes;
    lastAddedDayDate = dayDate;
    final queue = addPhotoResultsQueue;
    if (queue != null && callIndex < queue.length) return queue[callIndex];
    return addPhotoResult ??
        Right(
          buildPhotoEntity(
            tripId: tripId,
            dayDate: dayDate,
            caption: caption,
            placeText: placeText,
            lat: lat,
            lng: lng,
            takenAt: takenAt,
          ),
        );
  }
}

PhotoEntity buildPhotoEntity({
  String id = 'p1',
  String tripId = 't1',
  DateTime? dayDate,
  String storagePath = 'u1/t1/p1.jpg',
  String? imageUrl,
  String? caption,
  String? placeText,
  double? lat,
  double? lng,
  DateTime? takenAt,
}) {
  return PhotoEntity(
    id: id,
    tripId: tripId,
    dayDate: dayDate,
    storagePath: storagePath,
    caption: caption,
    placeText: placeText,
    lat: lat,
    lng: lng,
    takenAt: takenAt,
    createdAt: DateTime(2026, 1, 1),
    imageUrl: imageUrl,
  );
}
