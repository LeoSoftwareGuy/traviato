import 'entities/wrap_up_entity.dart';
import 'entities/wrap_up_flurry_leftovers.dart';
import 'entities/wrap_up_moment.dart';
import 'entities/wrap_up_photo_ref.dart';

/// Drops every photo reference the film can't actually show (#187) — a
/// photo deleted after the wrap-up was built, or one whose URL couldn't be
/// resolved — so the player never paints an empty frame for it. Applied
/// before the scene timeline is computed, so timings follow what's left.
///
/// - A moment keeps its collage only when every tile is still available.
/// - Otherwise it falls back to a card flip on its own photo, or on the
///   first surviving collage tile if its own photo is gone (the note and
///   badge described the gone photo, so they're dropped with it).
/// - A moment with no surviving photo at all is removed.
/// - Flurry lists simply lose the missing entries.
WrapUpEntity pruneMissingPhotos(
  WrapUpEntity wrapUp,
  Set<String> availablePhotoIds,
) {
  bool isAvailable(WrapUpPhotoRef ref) =>
      availablePhotoIds.contains(ref.photoId);

  final moments = <WrapUpMoment>[];
  for (final moment in wrapUp.moments) {
    final surviving = moment.allPhotoRefs.where(isAvailable).toList();
    if (surviving.isEmpty) continue;
    if (surviving.length == moment.allPhotoRefs.length) {
      moments.add(moment);
      continue;
    }
    final ownPhotoSurvives = isAvailable(moment.photoRef);
    final ref = surviving.first;
    moments.add(
      WrapUpMoment(
        photoId: ref.photoId,
        dayDate: ref.dayDate,
        note: ownPhotoSurvives ? moment.note : null,
        badge: ownPhotoSurvives ? moment.badge : null,
      ),
    );
  }

  final leftovers = wrapUp.flurryLeftovers;
  List<WrapUpPhotoRef> keep(List<WrapUpPhotoRef> refs) =>
      refs.where(isAvailable).toList();

  return WrapUpEntity(
    cut: wrapUp.cut,
    dates: wrapUp.dates,
    coverPhoto: wrapUp.coverPhoto,
    invitation: wrapUp.invitation,
    bridges: wrapUp.bridges,
    moments: moments,
    flurryLeftovers: WrapUpFlurryLeftovers(
      photos: keep(leftovers.photos),
      flurry1: keep(leftovers.flurry1),
      flurry2: keep(leftovers.flurry2),
      totalRemainingLabel: leftovers.totalRemainingLabel,
    ),
    footnote: wrapUp.footnote,
    unlock: wrapUp.unlock,
    keepsake: wrapUp.keepsake,
    generatedAt: wrapUp.generatedAt,
    publishedAt: wrapUp.publishedAt,
  );
}
