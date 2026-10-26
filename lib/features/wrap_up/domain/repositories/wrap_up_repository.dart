import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/wrap_up_entity.dart';

abstract interface class WrapUpRepository {
  /// Returns the trip's wrap-up, generating it via `generate_wrap_up` (#93)
  /// on first call — the edge function itself is idempotent, so a second
  /// call for the same trip returns the same content without regenerating.
  /// [language] is the UI language code the AI-written lines are written in
  /// (#250); a kept-forever wrap-up stays in the language it was made in.
  Future<Either<Failure, WrapUpEntity>> getOrGenerate(
    String tripId, {
    required String language,
  });

  /// "Keep forever" — sets `published_at`. Direct client update, allowed by
  /// the `published_at`-scoped column grant from #93 (content/generated_at
  /// stay service-role-only).
  Future<Either<Failure, void>> publish(String tripId);

  /// "Photos changed · Rebuild film" (#294): re-assembles a kept film from
  /// the current photos and picks, keeping its AI lines — no AI call — and
  /// keeping it kept. [language] is passed along as on every request.
  Future<Either<Failure, void>> rebuildKept(
    String tripId, {
    required String language,
  });
}
