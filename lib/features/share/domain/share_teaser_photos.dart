import '../../photo/domain/entities/film_pick.dart';
import '../../photo/domain/entities/photo_entity.dart';
import '../../wrap_up/domain/film_moment_picks.dart';

/// How many photos a share link's teaser shows (#309): 2 clear, 4 blurred.
const shareTeaserPhotoCount = 6;

/// The photos a share link's preview uploads, in order (#309): the owner's
/// Always picks, then the film's other moment picks, then the rest — each
/// group chronological, Leave-out photos never. The memory's cover photo,
/// when it is one of these, comes first: it becomes `0.jpg`, the preview's
/// cover. Local only.
List<PhotoEntity> shareTeaserPhotos({
  required List<PhotoEntity> photos,
  required List<String> bonusPhotoIds,
  String? coverImagePath,
}) {
  final eligible = photos.where((p) => p.filmPick != FilmPick.never).toList()
    ..sort(comparePhotosChronologically);
  final momentIds = filmMomentPhotoIds(
    photos: photos,
    bonusPhotoIds: bonusPhotoIds,
  );
  final always = eligible.where((p) => p.filmPick == FilmPick.always);
  final moments = eligible.where(
    (p) => p.filmPick == FilmPick.auto && momentIds.contains(p.id),
  );
  final rest = eligible.where(
    (p) => p.filmPick == FilmPick.auto && !momentIds.contains(p.id),
  );
  final ordered = [...always, ...moments, ...rest];

  final cover = ordered.where((p) => p.storagePath == coverImagePath);
  return [
    ...cover,
    ...ordered.where((p) => p.storagePath != coverImagePath),
  ].take(shareTeaserPhotoCount).toList();
}
