import 'package:fpdart/fpdart.dart';

import '../../../../core/errors/failures.dart';
import '../entities/film_plan_inspection.dart';

/// Debug-only access to the wrap-up director (#328) for the Plan inspector.
abstract interface class FilmDirectorRepository {
  Future<Either<Failure, FilmPlanInspection>> getInspection(String tripId);

  /// Runs the director again for [tripId] — photo analysis for new photos,
  /// then a new plan. A kept film's content is never changed by it.
  Future<Either<Failure, void>> rerun(
    String tripId, {
    required String language,
  });
}
