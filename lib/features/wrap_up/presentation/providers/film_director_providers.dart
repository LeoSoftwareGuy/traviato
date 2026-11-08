import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/providers/supabase_providers.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../data/datasources/film_director_remote_data_source.dart';
import '../../data/datasources/supabase_film_director_remote_data_source.dart';
import '../../data/repositories/film_director_repository_impl.dart';
import '../../domain/entities/film_plan_inspection.dart';
import '../../domain/repositories/film_director_repository.dart';

part 'film_director_providers.g.dart';

@riverpod
FilmDirectorRemoteDataSource filmDirectorRemoteDataSource(Ref ref) =>
    SupabaseFilmDirectorRemoteDataSource(
      client: ref.watch(supabaseClientProvider),
    );

@riverpod
FilmDirectorRepository filmDirectorRepository(Ref ref) =>
    FilmDirectorRepositoryImpl(
      remote: ref.watch(filmDirectorRemoteDataSourceProvider),
    );

/// What the debug Plan inspector (#328) shows: the last director run and
/// the photo analysis.
@riverpod
Future<FilmPlanInspection> filmPlanInspection(Ref ref, String tripId) async {
  final result = await ref
      .watch(filmDirectorRepositoryProvider)
      .getInspection(tripId);
  return result.fold(
    (failure) => throw PresentationFailureException(failure),
    (inspection) => inspection,
  );
}

/// Signed thumbnail URL per photo id, for the inspector's scene rows. A
/// failed lookup just means no thumbnails.
@riverpod
Future<Map<String, String>> filmPlanPhotoUrls(Ref ref, String tripId) async {
  final result = await ref
      .watch(photoRepositoryProvider)
      .getPhotosForTrip(tripId);
  return result.getOrElse((_) => const []).fold<Map<String, String>>({}, (
    urls,
    photo,
  ) {
    final url = photo.imageUrl;
    if (url != null) urls[photo.id] = url;
    return urls;
  });
}
