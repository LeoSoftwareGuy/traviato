import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/wrap_up_entity.dart';

abstract interface class WrapUpRepository {
  /// Returns the trip's wrap-up, generating it via `generate_wrap_up` (#93)
  /// on first call — the edge function itself is idempotent, so a second
  /// call for the same trip returns the same content without regenerating.
  Future<Either<Failure, WrapUpEntity>> getOrGenerate(String tripId);

  /// "Keep forever" — sets `published_at`. Direct client update, allowed by
  /// the `published_at`-scoped column grant from #93 (content/generated_at
  /// stay service-role-only).
  Future<Either<Failure, void>> publish(String tripId);
}
