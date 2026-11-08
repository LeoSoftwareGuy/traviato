import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/wrap_up/domain/entities/film_plan_inspection.dart';
import 'package:traviato/features/wrap_up/domain/repositories/film_director_repository.dart';

class FakeFilmDirectorRepository implements FilmDirectorRepository {
  Either<Failure, FilmPlanInspection> inspectionResult = const Right(
    FilmPlanInspection(),
  );
  Either<Failure, void> rerunResult = const Right(null);
  var getInspectionCallCount = 0;
  var rerunCallCount = 0;
  String? lastLanguage;

  /// Delays [getInspection] so tests can observe the loading state.
  Duration delay = Duration.zero;

  @override
  Future<Either<Failure, FilmPlanInspection>> getInspection(
    String tripId,
  ) async {
    getInspectionCallCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return inspectionResult;
  }

  @override
  Future<Either<Failure, void>> rerun(
    String tripId, {
    required String language,
  }) async {
    rerunCallCount++;
    lastLanguage = language;
    return rerunResult;
  }
}
