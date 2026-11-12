import '../../photo/domain/entities/photo_entity.dart';
import 'entities/wrap_up_entity.dart';
import 'entities/wrap_up_sky.dart';

/// Whether a kept film no longer matches its memory's photos (#294) — the
/// trigger for "Photos changed · Rebuild film". A draft is rebuilt on every
/// open (#187), so only a kept film can be out of date. It is when:
/// - a photo's film pick changed after the film was built, or
/// - the film shows a photo that has since been deleted — a classic film's
///   moments and flurries, or a Sky Story's page photos (#345).
bool isKeptFilmOutOfDate(WrapUpEntity wrapUp, List<PhotoEntity> photos) {
  if (!wrapUp.isPublished) return false;
  final pickChanged = photos.any((photo) {
    final setAt = photo.filmPickSetAt;
    return setAt != null && setAt.isAfter(wrapUp.generatedAt);
  });
  if (pickChanged) return true;

  final photoIds = {for (final photo in photos) photo.id};
  final shown = [
    for (final moment in wrapUp.moments)
      for (final ref in moment.allPhotoRefs) ref.photoId,
    for (final ref in wrapUp.flurry1Photos) ref.photoId,
    for (final ref in wrapUp.flurry2Photos) ref.photoId,
    for (final page in wrapUp.sky?.pages ?? const <WrapUpSkyPage>[]) ...[
      page.heroPhotoId,
      ...page.extraPhotoIds,
    ],
  ];
  return shown.any((id) => !photoIds.contains(id));
}
