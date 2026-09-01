import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../providers/wrap_up_providers.dart';
import 'wrap_up_state.dart';

part 'wrap_up_controller.g.dart';

@riverpod
class WrapUpController extends _$WrapUpController {
  @override
  Future<WrapUpState> build(String tripId) async {
    final wrapUpRepo = ref.watch(wrapUpRepositoryProvider);
    final tripRepo = ref.watch(tripRepositoryProvider);
    final photoRepo = ref.watch(photoRepositoryProvider);

    // Started concurrently — generation can take real seconds, no reason to
    // block it on the trip/photos fetches or vice versa.
    final wrapUpFuture = wrapUpRepo.getOrGenerate(tripId);
    final tripFuture = tripRepo.getTripCard(tripId);
    final photosFuture = photoRepo.getPhotosForTrip(tripId);

    final wrapUp = (await wrapUpFuture).fold(
      (failure) => throw PresentationFailureException(failure),
      (w) => w,
    );
    final trip = (await tripFuture).fold(
      (failure) => throw PresentationFailureException(failure),
      (t) => t,
    );
    final photos = (await photosFuture).fold(
      (failure) => throw PresentationFailureException(failure),
      (p) => p,
    );

    return WrapUpState(
      wrapUp: wrapUp,
      trip: trip,
      photoUrlById: {
        for (final photo in photos)
          if (photo.imageUrl != null) photo.id: photo.imageUrl!,
      },
    );
  }

  /// Called by the publish mutation after a successful "Keep forever".
  void applyPublished(DateTime publishedAt) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        wrapUp: current.wrapUp.copyWith(publishedAt: () => publishedAt),
      ),
    );
  }
}
