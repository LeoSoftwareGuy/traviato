import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/trip_card_entity.dart';
import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_remote_data_source.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl({required TripRemoteDataSource remote}) : _remote = remote;

  final TripRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<TripCardEntity>>> getTripCards() async {
    try {
      return Right(await _remote.getTripCards());
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, TripCardEntity>> getTripCard(String tripId) async {
    try {
      return Right(await _remote.getTripCard(tripId));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> createTrip({
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String> vibes = const [],
    String? coverImagePath,
  }) async {
    try {
      return Right(
        await _remote.createTrip(
          id: const Uuid().v4(),
          name: name,
          destination: destination,
          startDate: startDate,
          endDate: endDate,
          vibes: vibes,
          coverImagePath: coverImagePath,
        ),
      );
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on MemoryLimitException catch (e) {
      return Left(FreeTierLimitFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, TripEntity>> updateTrip({
    required String id,
    String? name,
    String? coverImagePath,
  }) async {
    try {
      return Right(
        await _remote.updateTrip(
          id: id,
          name: name,
          coverImagePath: coverImagePath,
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

  @override
  Future<Either<Failure, TripEntity>> shiftTripDates({
    required String id,
    required int deltaDays,
  }) async {
    try {
      return Right(
        await _remote.shiftTripDates(id: id, deltaDays: deltaDays),
      );
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> uploadCoverImage({
    required String tripId,
    required Uint8List bytes,
  }) async {
    try {
      return Right(
        await _remote.uploadCoverImage(tripId: tripId, bytes: bytes),
      );
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCoverImage(String tripId) async {
    try {
      await _remote.deleteCoverImage(tripId);
      return const Right(null);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, String>> getCoverImageUrl(String storagePath) async {
    try {
      return Right(await _remote.getCoverImageUrl(storagePath));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTrip(String id) async {
    // Row first (its cascade takes photos, notes, quests, ...), then the
    // trip's storage files (#170). Files first would leave a memory with
    // broken photos if the row delete then failed; this way round the
    // worst case is orphaned files nobody can see, so a failed cleanup is
    // logged rather than failing a delete the user already sees as done.
    try {
      await _remote.deleteTrip(id);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on AppException catch (e) {
      return Left(UnknownFailure(message: e.message));
    }
    try {
      await _remote.removeTripFiles(id);
    } on AppException catch (e) {
      debugPrint('Orphaned storage files for trip $id: ${e.message}');
    }
    return const Right(null);
  }
}
