import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import 'trip_providers.dart';

part 'cover_image_url_provider.g.dart';

/// Signs a stored cover path (a custom upload, never an `asset:` bundled
/// reference) for display — `trip-photos` is a private bucket. Auto-dispose,
/// cached per path: cheap to re-derive, no need to keep it alive once
/// nothing is watching (issue #81).
@riverpod
Future<String> coverImageUrl(Ref ref, String storagePath) async {
  final repo = ref.watch(tripRepositoryProvider);
  return (await repo.getCoverImageUrl(storagePath)).fold(
    (failure) => throw PresentationFailureException(failure),
    (url) => url,
  );
}
