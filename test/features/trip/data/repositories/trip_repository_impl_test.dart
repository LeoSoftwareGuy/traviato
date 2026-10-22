import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:traviato/features/trip/data/models/trip_card_model.dart';
import 'package:traviato/features/trip/data/models/trip_dates_change_model.dart';
import 'package:traviato/features/trip/data/models/trip_model.dart';
import 'package:traviato/features/trip/data/repositories/trip_repository_impl.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';
import 'package:traviato/features/trip/domain/entities/trip_dates_change_entity.dart';

class _FakeTripRemoteDataSource implements TripRemoteDataSource {
  _FakeTripRemoteDataSource({
    this.exception,
    this.removeFilesException,
    this.datesChange,
  });

  Exception? exception;
  Exception? removeFilesException;

  /// What `setTripDates` returns (#271).
  TripDatesChangeModel? datesChange;
  bool? lastDryRun;
  final removedPhotoFiles = <String>[];
  String? lastCreateTripId;
  String? lastDeletedTripId;

  /// Storage objects, as the `trip-photos` bucket would hold them.
  final files = <String>{
    'u1/t1/p1.jpg',
    'u1/t1/p2.jpg',
    'u1/t1/cover.jpg',
    'u1/t2/p3.jpg',
  };

  /// Delete calls, in order — `row:<id>` / `files:<id>`.
  final calls = <String>[];

  @override
  Future<void> removeTripFiles(String tripId) async {
    calls.add('files:$tripId');
    if (removeFilesException != null) throw removeFilesException!;
    files.removeWhere((path) => path.startsWith('u1/$tripId/'));
  }

  static final _trips = [
    TripCardModel(
      id: 't1',
      userId: 'u1',
      name: 'Weekend in the woods',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: TripStatus.upcoming,
      photoCount: 0,
      questCount: 0,
      stars: 0,
      expenseTotal: 0,
    ),
  ];

  @override
  Future<List<TripCardModel>> getTripCards() async {
    if (exception != null) throw exception!;
    return _trips;
  }

  @override
  Future<TripCardModel> getTripCard(String tripId) async {
    if (exception != null) throw exception!;
    return _trips.firstWhere((t) => t.id == tripId, orElse: () => _trips.first);
  }

  @override
  Future<TripModel> createTrip({
    required String id,
    required String name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    List<String> vibes = const [],
    String? coverImagePath,
  }) async {
    if (exception != null) throw exception!;
    lastCreateTripId = id;
    return TripModel(
      id: id,
      userId: 'u1',
      name: name,
      destination: destination,
      startDate: startDate,
      endDate: endDate,
      vibes: vibes,
      coverImagePath: coverImagePath,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<void> deleteTrip(String id) async {
    calls.add('row:$id');
    if (exception != null) throw exception!;
    lastDeletedTripId = id;
  }

  @override
  Future<TripModel> updateTrip({
    required String id,
    String? name,
    String? coverImagePath,
  }) async {
    if (exception != null) throw exception!;
    return TripModel(
      id: id,
      userId: 'u1',
      name: name ?? 'Weekend in the woods',
      coverImagePath: coverImagePath,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<TripDatesChangeModel> setTripDates({
    required String id,
    required DateTime startDate,
    required DateTime endDate,
    bool dryRun = false,
  }) async {
    calls.add(dryRun ? 'preview:$id' : 'setDates:$id');
    lastDryRun = dryRun;
    if (exception != null) throw exception!;
    return datesChange ??
        const TripDatesChangeModel(
          quests: 0,
          notes: 0,
          photos: 0,
          bonusTasks: 0,
        );
  }

  @override
  Future<void> removePhotoFiles(List<String> storagePaths) async {
    calls.add('photoFiles:${storagePaths.length}');
    if (removeFilesException != null) throw removeFilesException!;
    removedPhotoFiles.addAll(storagePaths);
  }

  String? lastUploadCoverTripId;
  Uint8List? lastUploadCoverBytes;
  String? lastDeleteCoverTripId;

  @override
  Future<String> uploadCoverImage({
    required String tripId,
    required Uint8List bytes,
  }) async {
    if (exception != null) throw exception!;
    lastUploadCoverTripId = tripId;
    lastUploadCoverBytes = bytes;
    return 'u1/$tripId/cover.jpg';
  }

  @override
  Future<void> deleteCoverImage(String tripId) async {
    if (exception != null) throw exception!;
    lastDeleteCoverTripId = tripId;
  }

  @override
  Future<String> getCoverImageUrl(String storagePath) async {
    if (exception != null) throw exception!;
    return 'https://signed.example/$storagePath';
  }
}

void main() {
  group('TripRepositoryImpl.getTripCards', () {
    test('returns Right(trips) on success', () async {
      final repo = TripRepositoryImpl(remote: _FakeTripRemoteDataSource());
      final result = await repo.getTripCards();
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (trips) => expect(trips, hasLength(1)),
      );
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.getTripCards();
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(exception: const NetworkException()),
      );
      final result = await repo.getTripCards();
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });

    test('maps other AppExceptions to UnknownFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(
          exception: const UnknownException(message: 'boom'),
        ),
      );
      final result = await repo.getTripCards();
      result.fold(
        (failure) => expect(failure, const UnknownFailure(message: 'boom')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('TripRepositoryImpl.getTripCard', () {
    test('returns Right(trip) on success', () async {
      final repo = TripRepositoryImpl(remote: _FakeTripRemoteDataSource());
      final result = await repo.getTripCard('t1');
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (trip) => expect(trip.id, 't1'),
      );
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.getTripCard('t1');
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('TripRepositoryImpl.createTrip', () {
    test('returns Right(trip) and generates a client-side id', () async {
      final remote = _FakeTripRemoteDataSource();
      final repo = TripRepositoryImpl(remote: remote);
      final result = await repo.createTrip(name: 'Summer in Tokyo');
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (trip) => expect(trip.name, 'Summer in Tokyo'),
      );
      expect(remote.lastCreateTripId, isNotNull);
      expect(remote.lastCreateTripId, isNotEmpty);
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.createTrip(name: 'Summer in Tokyo');
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(exception: const NetworkException()),
      );
      final result = await repo.createTrip(name: 'Summer in Tokyo');
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });

    test(
      'maps MemoryLimitException (server-side TRV01, #139) to '
      'FreeTierLimitFailure',
      () async {
        final repo = TripRepositoryImpl(
          remote: _FakeTripRemoteDataSource(
            exception: const MemoryLimitException(
              message: 'Free plan is limited to 3 memories.',
            ),
          ),
        );
        final result = await repo.createTrip(name: 'Summer in Tokyo');
        result.fold(
          (failure) => expect(
            failure,
            const FreeTierLimitFailure(
              message: 'Free plan is limited to 3 memories.',
            ),
          ),
          (_) => fail('expected Left'),
        );
      },
    );

    test(
      'a server-side not-null rejection (23502, undated trip since #270) '
      'is a typed failure, not a raw exception',
      () async {
        // The data source maps any unrecognised PostgrestException code —
        // 23502 included — to DatabaseException.
        const message =
            'null value in column "start_date" of relation "trips" violates '
            'not-null constraint';
        final repo = TripRepositoryImpl(
          remote: _FakeTripRemoteDataSource(
            exception: const DatabaseException(message: message),
          ),
        );
        final result = await repo.createTrip(name: 'Summer in Tokyo');
        result.fold(
          (failure) => expect(failure, const UnknownFailure(message: message)),
          (_) => fail('expected Left'),
        );
      },
    );
  });

  group('TripRepositoryImpl dates (#271)', () {
    final start = DateTime(2026, 7, 20);
    final end = DateTime(2026, 7, 23);

    test('previewTripDates is a dry run and never removes files', () async {
      final remote = _FakeTripRemoteDataSource(
        datesChange: const TripDatesChangeModel(
          quests: 1,
          notes: 6,
          photos: 23,
          bonusTasks: 2,
          photoPaths: ['u1/t1/p1.jpg'],
        ),
      );
      final repo = TripRepositoryImpl(remote: remote);

      final result = await repo.previewTripDates(
        id: 't1',
        startDate: start,
        endDate: end,
      );

      final impact = result.getOrElse((_) => throw StateError('Left'));
      expect(remote.lastDryRun, isTrue);
      expect(impact.notes, 6);
      expect(impact.photos, 23);
      expect(impact.removesAnything, isTrue);
      expect(remote.calls, ['preview:t1']);
    });

    test(
      'setTripDates saves, then removes the deleted photos\' files',
      () async {
        final remote = _FakeTripRemoteDataSource(
          datesChange: const TripDatesChangeModel(
            quests: 0,
            notes: 1,
            photos: 2,
            bonusTasks: 0,
            photoPaths: ['u1/t1/p1.jpg', 'u1/t1/p2.jpg'],
          ),
        );
        final repo = TripRepositoryImpl(remote: remote);

        final result = await repo.setTripDates(
          id: 't1',
          startDate: start,
          endDate: end,
        );

        expect(result.isRight(), isTrue);
        expect(remote.lastDryRun, isFalse);
        // Rows first, files after — same order as photo delete.
        expect(remote.calls, ['setDates:t1', 'photoFiles:2']);
        expect(remote.removedPhotoFiles, ['u1/t1/p1.jpg', 'u1/t1/p2.jpg']);
      },
    );

    test('a file-removal failure never fails the save', () async {
      final remote = _FakeTripRemoteDataSource(
        removeFilesException: const StorageServerException(message: 'down'),
        datesChange: const TripDatesChangeModel(
          quests: 0,
          notes: 0,
          photos: 1,
          bonusTasks: 0,
          photoPaths: ['u1/t1/p1.jpg'],
        ),
      );
      final repo = TripRepositoryImpl(remote: remote);

      final result = await repo.setTripDates(
        id: 't1',
        startDate: start,
        endDate: end,
      );

      expect(result.isRight(), isTrue);
    });

    test('maps a permission error to PermissionFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(
          exception: const PermissionException(message: 'not yours'),
        ),
      );

      final result = await repo.setTripDates(
        id: 't1',
        startDate: start,
        endDate: end,
      );

      expect(
        result,
        const Left<Failure, TripDatesChangeEntity>(
          PermissionFailure(message: 'not yours'),
        ),
      );
    });
  });

  group('TripRepositoryImpl.deleteTrip', () {
    test('returns Right(null) on success', () async {
      final remote = _FakeTripRemoteDataSource();
      final repo = TripRepositoryImpl(remote: remote);
      final result = await repo.deleteTrip('t1');
      expect(result.isRight(), isTrue);
      expect(remote.lastDeletedTripId, 't1');
    });

    test("removes all of the trip's storage files — photos and cover — "
        'after the row, leaving other trips alone (#170)', () async {
      final remote = _FakeTripRemoteDataSource();
      await TripRepositoryImpl(remote: remote).deleteTrip('t1');

      expect(remote.calls, ['row:t1', 'files:t1']);
      expect(remote.files, {'u1/t2/p3.jpg'});
    });

    test('a failed row delete fails and keeps the files', () async {
      final remote = _FakeTripRemoteDataSource(
        exception: const NetworkException(),
      );
      final result = await TripRepositoryImpl(remote: remote).deleteTrip('t1');

      expect(result.isLeft(), isTrue);
      expect(remote.calls, ['row:t1']);
      expect(remote.files, hasLength(4));
    });

    test('a failed file cleanup still succeeds — the memory is gone for '
        'the user once its row is', () async {
      final remote = _FakeTripRemoteDataSource(
        removeFilesException: const StorageServerException(message: 'down'),
      );
      final result = await TripRepositoryImpl(remote: remote).deleteTrip('t1');

      expect(result.isRight(), isTrue);
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.deleteTrip('t1');
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('TripRepositoryImpl.uploadCoverImage', () {
    test('returns Right(storagePath) on success', () async {
      final remote = _FakeTripRemoteDataSource();
      final repo = TripRepositoryImpl(remote: remote);
      final bytes = Uint8List.fromList([1, 2, 3]);
      final result = await repo.uploadCoverImage(tripId: 't1', bytes: bytes);
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (path) => expect(path, 'u1/t1/cover.jpg'),
      );
      expect(remote.lastUploadCoverTripId, 't1');
      expect(remote.lastUploadCoverBytes, bytes);
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(exception: const NetworkException()),
      );
      final result = await repo.uploadCoverImage(
        tripId: 't1',
        bytes: Uint8List(0),
      );
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });
  });

  group('TripRepositoryImpl.deleteCoverImage', () {
    test('returns Right(null) on success', () async {
      final remote = _FakeTripRemoteDataSource();
      final repo = TripRepositoryImpl(remote: remote);
      final result = await repo.deleteCoverImage('t1');
      expect(result.isRight(), isTrue);
      expect(remote.lastDeleteCoverTripId, 't1');
    });

    test('maps other AppExceptions to UnknownFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(
          exception: const UnknownException(message: 'boom'),
        ),
      );
      final result = await repo.deleteCoverImage('t1');
      result.fold(
        (failure) => expect(failure, const UnknownFailure(message: 'boom')),
        (_) => fail('expected Left'),
      );
    });
  });

  group('TripRepositoryImpl.getCoverImageUrl', () {
    test('returns Right(signedUrl) on success', () async {
      final repo = TripRepositoryImpl(remote: _FakeTripRemoteDataSource());
      final result = await repo.getCoverImageUrl('u1/t1/cover.jpg');
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (url) => expect(url, 'https://signed.example/u1/t1/cover.jpg'),
      );
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = TripRepositoryImpl(
        remote: _FakeTripRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.getCoverImageUrl('u1/t1/cover.jpg');
      result.fold(
        (failure) =>
            expect(failure, const AuthenticationFailure(message: 'no session')),
        (_) => fail('expected Left'),
      );
    });
  });
}
