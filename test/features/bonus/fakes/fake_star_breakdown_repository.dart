import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/bonus/domain/entities/star_ledger_group_entity.dart';
import 'package:traviato/features/bonus/domain/repositories/star_breakdown_repository.dart';

/// Test double for [StarBreakdownRepository]. Returns [groups] unless
/// [result] is set.
class FakeStarBreakdownRepository implements StarBreakdownRepository {
  List<StarLedgerGroupEntity> groups = const [];
  Either<Failure, List<StarLedgerGroupEntity>>? result;
  var callCount = 0;

  @override
  Future<Either<Failure, List<StarLedgerGroupEntity>>> getBreakdown() async {
    callCount++;
    return result ?? Right(groups);
  }
}
