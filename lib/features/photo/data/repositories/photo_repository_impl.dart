import 'dart:typed_data';

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
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }
}
