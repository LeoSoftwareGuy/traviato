import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/photo_entity.dart';
import '../../domain/repositories/photo_repository.dart';
import '../datasources/photo_remote_data_source.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl({required PhotoRemoteDataSource remote})
    : _remote = remote;

  final PhotoRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<PhotoEntity>>> getPhotosForTrip(
    String tripId,
  ) async {
    try {
      return Right(await _remote.getPhotosForTrip(tripId));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
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
    try {
      return Right(
        await _remote.addPhoto(
          id: const Uuid().v4(),
          tripId: tripId,
          dayDate: dayDate,
          bytes: bytes,
          fileExtension: fileExtension,
          caption: caption,
          placeText: placeText,
          lat: lat,
          lng: lng,
          takenAt: takenAt,
        ),
      );
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PhotoLimitException catch (e) {
      return Left(PhotoLimitFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deletePhoto(PhotoEntity photo) async {
    // Row first: if the file went first and the row delete then failed, the
    // Journal would show a broken photo. This way round, the worst case is
    // an orphaned file nobody can see.
    try {
      await _remote.deletePhotoRow(photo.id);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
    try {
      await _remote.removePhotoFile(photo.storagePath);
    } on AppException catch (e) {
      debugPrint('Orphaned photo file ${photo.storagePath}: ${e.message}');
    }
    return const Right(null);
  }
}
