import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/home/data/datasources/profile_stats_remote_data_source.dart';
import 'package:traviato/features/home/data/models/profile_stats_model.dart';
import 'package:traviato/features/home/data/repositories/profile_stats_repository_impl.dart';

class _FakeProfileStatsRemoteDataSource
    implements ProfileStatsRemoteDataSource {
  _FakeProfileStatsRemoteDataSource({this.exception});

  Exception? exception;

  @override
  Future<ProfileStatsModel> getStats() async {
    if (exception != null) throw exception!;
    return const ProfileStatsModel(memories: 2, places: 3, days: 4, stars: 5);
  }
}

void main() {
  test('returns Right(stats) on success', () async {
    final repo = ProfileStatsRepositoryImpl(
      remote: _FakeProfileStatsRemoteDataSource(),
    );
    final result = await repo.getStats();
    result.fold(
      (failure) => fail('expected Right, got Left($failure)'),
      (stats) => expect(stats.stars, 5),
    );
  });

  test('maps AuthenticationException to AuthenticationFailure', () async {
    final repo = ProfileStatsRepositoryImpl(
      remote: _FakeProfileStatsRemoteDataSource(
        exception: const AuthenticationException(message: 'no session'),
      ),
    );
    final result = await repo.getStats();
    result.fold(
      (failure) =>
          expect(failure, const AuthenticationFailure(message: 'no session')),
      (_) => fail('expected Left'),
    );
  });

  test('maps NetworkException to NetworkFailure', () async {
    final repo = ProfileStatsRepositoryImpl(
      remote: _FakeProfileStatsRemoteDataSource(
        exception: const NetworkException(),
      ),
    );
    final result = await repo.getStats();
    result.fold(
      (failure) => expect(failure, const NetworkFailure()),
      (_) => fail('expected Left'),
    );
  });
}
