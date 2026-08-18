import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:traviato/features/trip/data/models/trip_card_model.dart';
import 'package:traviato/features/trip/data/models/trip_model.dart';
import 'package:traviato/features/trip/data/repositories/trip_repository_impl.dart';
import 'package:traviato/features/trip/domain/entities/trip_card_entity.dart';

class _FakeTripRemoteDataSource implements TripRemoteDataSource {
  _FakeTripRemoteDataSource({this.exception});

  Exception? exception;
  String? lastCreateTripId;

  static final _trips = [
    TripCardModel(
      id: 't1',
      userId: 'u1',
      name: 'Weekend in the woods',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: TripStatus.upcoming,
      photoCount: 0,
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
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
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
  });
}
