import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/bonus/data/datasources/star_breakdown_remote_data_source.dart';
import 'package:traviato/features/bonus/data/models/star_ledger_group_model.dart';
import 'package:traviato/features/bonus/data/repositories/star_breakdown_repository_impl.dart';
import 'package:traviato/features/bonus/domain/entities/star_ledger_group_entity.dart';

class _FakeRemote implements StarBreakdownRemoteDataSource {
  _FakeRemote({this.exception});

  final Exception? exception;

  @override
  Future<List<StarLedgerGroupModel>> getBreakdown() async {
    if (exception != null) throw exception!;
    return const [
      StarLedgerGroupModel(
        tripId: 't1',
        source: StarSource.photo,
        entryCount: 2,
        points: 4,
      ),
    ];
  }
}

void main() {
  test('returns Right(groups) on success', () async {
    final result = await StarBreakdownRepositoryImpl(
      remote: _FakeRemote(),
    ).getBreakdown();
    expect(result.getOrElse((_) => const []).single.points, 4);
  });

  test('maps AuthenticationException to AuthenticationFailure', () async {
    final result = await StarBreakdownRepositoryImpl(
      remote: _FakeRemote(
        exception: const AuthenticationException(message: 'no session'),
      ),
    ).getBreakdown();
    expect(result.getLeft().toNullable(), isA<AuthenticationFailure>());
  });

  test('maps NetworkException to NetworkFailure', () async {
    final result = await StarBreakdownRepositoryImpl(
      remote: _FakeRemote(exception: const NetworkException()),
    ).getBreakdown();
    expect(result.getLeft().toNullable(), const NetworkFailure());
  });

  test('maps other AppExceptions to UnknownFailure', () async {
    final result = await StarBreakdownRepositoryImpl(
      remote: _FakeRemote(exception: const DatabaseException(message: 'boom')),
    ).getBreakdown();
    expect(result.getLeft().toNullable(), isA<UnknownFailure>());
  });
}
