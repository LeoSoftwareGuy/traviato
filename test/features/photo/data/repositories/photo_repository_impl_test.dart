import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/photo/data/datasources/photo_remote_data_source.dart';
import 'package:traviato/features/photo/data/models/photo_model.dart';
import 'package:traviato/features/photo/data/repositories/photo_repository_impl.dart';

class _FakePhotoRemoteDataSource implements PhotoRemoteDataSource {
  _FakePhotoRemoteDataSource({this.exception});

  Exception? exception;
  String? lastAddedId;

  @override
  Future<List<PhotoModel>> getPhotosForTrip(String tripId) async {
    if (exception != null) throw exception!;
    return const [];
  }

  @override
  Future<PhotoModel> addPhoto({
    required String id,
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
    if (exception != null) throw exception!;
    lastAddedId = id;
    return PhotoModel(
      id: id,
      tripId: tripId,
      dayDate: dayDate,
      storagePath: '$tripId/$id.$fileExtension',
      caption: caption,
      placeText: placeText,
      lat: lat,
      lng: lng,
      takenAt: takenAt,
      createdAt: DateTime(2026, 1, 1),
    );
  }
}

void main() {
  group('PhotoRepositoryImpl.addPhoto', () {
    test('returns Right(photo) and generates a client-side id', () async {
      final remote = _FakePhotoRemoteDataSource();
      final repo = PhotoRepositoryImpl(remote: remote);
      final result = await repo.addPhoto(
        tripId: 't1',
        dayDate: DateTime(2026, 8, 18),
        bytes: Uint8List.fromList([1, 2, 3]),
        fileExtension: 'jpg',
        caption: 'Sunset',
        lat: 41.0,
        lng: 12.0,
      );

      expect(result.isRight(), isTrue);
      expect(remote.lastAddedId, isNotNull);
      expect(remote.lastAddedId, isNotEmpty);
      result.fold(
        (failure) => fail('expected Right, got Left($failure)'),
        (photo) {
          expect(photo.tripId, 't1');
          expect(photo.caption, 'Sunset');
          expect(photo.lat, 41.0);
          expect(photo.lng, 12.0);
        },
      );
    });

    test('maps a storage failure to UnknownFailure', () async {
      final repo = PhotoRepositoryImpl(
        remote: _FakePhotoRemoteDataSource(
          exception: const StorageServerException(message: 'bucket error'),
        ),
      );
      final result = await repo.addPhoto(
        tripId: 't1',
        bytes: Uint8List.fromList([1, 2, 3]),
        fileExtension: 'jpg',
      );
      result.fold(
        (failure) => expect(
          failure,
          const UnknownFailure(message: 'bucket error'),
        ),
        (_) => fail('expected Left'),
      );
    });

    test('maps NetworkException to NetworkFailure', () async {
      final repo = PhotoRepositoryImpl(
        remote: _FakePhotoRemoteDataSource(
          exception: const NetworkException(),
        ),
      );
      final result = await repo.addPhoto(
        tripId: 't1',
        bytes: Uint8List.fromList([1, 2, 3]),
        fileExtension: 'jpg',
      );
      result.fold(
        (failure) => expect(failure, const NetworkFailure()),
        (_) => fail('expected Left'),
      );
    });

    test('maps AuthenticationException to AuthenticationFailure', () async {
      final repo = PhotoRepositoryImpl(
        remote: _FakePhotoRemoteDataSource(
          exception: const AuthenticationException(message: 'no session'),
        ),
      );
      final result = await repo.addPhoto(
        tripId: 't1',
        bytes: Uint8List.fromList([1, 2, 3]),
        fileExtension: 'jpg',
      );
      result.fold(
        (failure) => expect(
          failure,
          const AuthenticationFailure(message: 'no session'),
        ),
        (_) => fail('expected Left'),
      );
    });
  });
}
