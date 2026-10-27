import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../settings/presentation/controllers/app_language_controller.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../domain/entities/wrap_up_dates.dart';
import '../../domain/entities/wrap_up_entity.dart';
import '../../domain/entities/wrap_up_invitation.dart';
import '../../domain/kept_film_staleness.dart';
import '../../domain/wrap_up_date_labels.dart';
import '../../domain/wrap_up_photo_pruning.dart';
import '../providers/wrap_up_providers.dart';
import 'wrap_up_state.dart';

part 'wrap_up_controller.g.dart';

@riverpod
class WrapUpController extends _$WrapUpController {
  @override
  Future<WrapUpState> build(String tripId) async {
    // A pick changed or a photo was deleted (#294): reload, so a draft
    // plays the new picks and a kept film rechecks whether it's stale.
    final sub = ref.watch(globalEventBusProvider).stream.listen((event) {
      if (event is FilmPhotosChangedDispatched && event.tripId == tripId) {
        ref.invalidateSelf();
      }
    });
    ref.onDispose(sub.cancel);

    final wrapUpRepo = ref.watch(wrapUpRepositoryProvider);
    final photoRepo = ref.watch(photoRepositoryProvider);
    final tripRepo = ref.watch(tripRepositoryProvider);

    // Started concurrently — generation can take real seconds, no reason to
    // block it on the photos fetch or vice versa. Unlike the pre-#125
    // screenplay, cover/title travel in `content` itself — but the date line
    // and day count are re-derived from the trip's live dates (#186) so they
    // stay right after a date shift and for wrap-ups baked before the
    // single-day fix.
    // Read, not watched: switching language mid-film mustn't spend an AI
    // call; the next open writes in the new language (#250).
    final wrapUpFuture = wrapUpRepo.getOrGenerate(
      tripId,
      language: ref.read(resolvedAppLanguageProvider).code!,
    );
    final photosFuture = photoRepo.getPhotosForTrip(tripId);
    final tripFuture = tripRepo.getTripCard(tripId);

    final wrapUp = (await wrapUpFuture).fold(
      (failure) => throw PresentationFailureException(failure),
      (w) => w,
    );
    final photos = (await photosFuture).fold(
      (failure) => throw PresentationFailureException(failure),
      (p) => p,
    );

    // A failed trip fetch isn't worth failing the film over — the stored
    // dates still play.
    final trip = (await tripFuture).fold((failure) {
      debugPrint('Wrap-up trip fetch failed, using stored dates: $failure');
      return null;
    }, (t) => t);

    final photoUrlById = {
      for (final photo in photos)
        if (photo.imageUrl != null) photo.id: photo.imageUrl!,
    };

    return WrapUpState(
      // A kept-forever wrap-up is frozen server-side, so a photo deleted
      // after publishing is still referenced — pruned here so the film
      // never plays an empty frame for it (#187).
      wrapUp: pruneMissingPhotos(
        _withLiveDates(
          wrapUp,
          start: trip?.startDate ?? wrapUp.dates.startDate,
          end: trip?.endDate ?? wrapUp.dates.endDate,
        ),
        photoUrlById.keys.toSet(),
      ),
      photoUrlById: photoUrlById,
      // Checked before pruning: a deleted photo the film shows is exactly
      // what makes it stale.
      isOutOfDate: isKeptFilmOutOfDate(wrapUp, photos),
    );
  }

  /// Reloads after "Photos changed · Rebuild film" (#294) rewrote the kept
  /// film server-side — it's read back as stored, so no AI call.
  void reloadRebuilt() => ref.invalidateSelf();

  WrapUpEntity _withLiveDates(
    WrapUpEntity wrapUp, {
    required DateTime? start,
    required DateTime? end,
  }) {
    final formatted = formatWrapUpDateRange(start, end);
    final line1 = wrapUpDayCountLine(start, end);
    return wrapUp.copyWith(
      dates: formatted == null
          ? null
          : WrapUpDates(startDate: start, endDate: end, formatted: formatted),
      invitation: line1 == null
          ? null
          : WrapUpInvitation(line1: line1, line2: wrapUp.invitation.line2),
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
