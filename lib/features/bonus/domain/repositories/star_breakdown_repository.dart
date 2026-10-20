import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/star_ledger_group_entity.dart';

abstract interface class StarBreakdownRepository {
  /// The signed-in user's stars grouped by (memory, source).
  Future<Either<Failure, List<StarLedgerGroupEntity>>> getBreakdown();
}
