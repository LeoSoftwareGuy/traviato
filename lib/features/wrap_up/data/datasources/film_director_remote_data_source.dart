import '../../domain/entities/film_plan_inspection.dart';

/// The wrap-up director's debug surface (#328): reads the last run and the
/// photo analysis, and asks `generate_wrap_up` to run the director again.
abstract interface class FilmDirectorRemoteDataSource {
  Future<FilmPlanInspection> getInspection(String tripId);

  /// Throws a `PermissionException` when the director isn't enabled for
  /// this account (server-side flag).
  Future<void> rerun(String tripId, {required String language});
}
