import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/wrap_up/data/datasources/wrap_up_remote_data_source.dart';
import 'package:traviato/features/wrap_up/data/models/wrap_up_model.dart';
import 'package:traviato/features/wrap_up/data/repositories/wrap_up_repository_impl.dart';

class _FakeWrapUpRemoteDataSource implements WrapUpRemoteDataSource {
  Exception? exception;
  var publishCallCount = 0;

  @override
  Future<WrapUpModel> getOrGenerate(
    String tripId, {
    required String language,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> publish(String tripId) async {
    publishCallCount++;
    if (exception != null) throw exception!;
  }

  var rebuildCallCount = 0;

  @override
  Future<void> rebuildKept(String tripId, {required String language}) async {
    rebuildCallCount++;
    if (exception != null) throw exception!;
  }
}

void main() {
  group('publish', () {
    // "Keep forever" is a plain UPDATE published_at = now() (#95's plan
    // comment / issue #95 AC): calling it again for an already-published
    // wrap-up must not surface an error.
    test('is idempotent — calling it twice both succeed', () async {
      final dataSource = _FakeWrapUpRemoteDataSource();
      final repo = WrapUpRepositoryImpl(remote: dataSource);

      final first = await repo.publish('t1');
      final second = await repo.publish('t1');

      expect(first, const Right<Failure, void>(null));
      expect(second, const Right<Failure, void>(null));
      expect(dataSource.publishCallCount, 2);
    });

    test('maps an authentication failure', () async {
      final dataSource = _FakeWrapUpRemoteDataSource()
        ..exception = const AuthenticationException(message: 'no session');
      final repo = WrapUpRepositoryImpl(remote: dataSource);

      final result = await repo.publish('t1');

      expect(result, isA<Left<Failure, void>>());
      expect(
        (result as Left<Failure, void>).value,
        isA<AuthenticationFailure>(),
      );
    });
  });

  group('rebuildKept (#294)', () {
    test('succeeds when the function does', () async {
      final dataSource = _FakeWrapUpRemoteDataSource();
      final repo = WrapUpRepositoryImpl(remote: dataSource);

      final result = await repo.rebuildKept('t1', language: 'en');

      expect(result, const Right<Failure, void>(null));
      expect(dataSource.rebuildCallCount, 1);
    });

    test('maps a server error to ServerFailure', () async {
      final repo = WrapUpRepositoryImpl(
        remote: _FakeWrapUpRemoteDataSource()
          ..exception = const ServerException(message: 'boom'),
      );

      final result = await repo.rebuildKept('t1', language: 'en');

      expect(result, const Left<Failure, void>(ServerFailure(message: 'boom')));
    });
  });
}
