import '../../photo/domain/entities/film_pick.dart';
import '../../photo/domain/entities/photo_entity.dart';
import '../../photo/domain/photo_order.dart';

/// How many main moments (M1–M16) the Wrap-Up Film has (#304). Sent to
/// `generate_wrap_up` as `moment_slots`.
const filmMomentCount = 16;

/// At most this many bonus-task photos get a badged moment.
const filmMaxBonusMoments = 3;

/// The photos the Wrap-Up Film gives a main moment to, with the current
/// picks (#294) — the app's "Film chose this one" hint and strip markers.
///
/// Mirrors `pickMomentPhotos` in `supabase/functions/generate_wrap_up/
/// assemble.ts`; keep the two in step. Leave-out photos are skipped;
/// Always photos come first (more than [filmMomentCount] → spread over the
/// trip), then up to [filmMaxBonusMoments] bonus-task photos on Auto, then
/// Auto photos spread over the whole trip. [bonusPhotoIds] are the photos
/// of completed bonus tasks, in completion order. [momentCount] is the
/// film's slots — 16 for the film this build asks for (#304). Local only —
/// no network, no AI.
Set<String> filmMomentPhotoIds({
  required List<PhotoEntity> photos,
  required List<String> bonusPhotoIds,
  int momentCount = filmMomentCount,
}) {
  final eligible = photos.where((p) => p.filmPick != FilmPick.never).toList()
    ..sort(_chronological);
  final byId = {for (final p in eligible) p.id: p};

  final badged = bonusPhotoIds
      .where(byId.containsKey)
      .take(filmMaxBonusMoments)
      .toList();
  final always = spreadEvenly(
    eligible.where((p) => p.filmPick == FilmPick.always).toList(),
    momentCount,
  );
  final bonus = badged
      .map((id) => byId[id]!)
      .where((p) => p.filmPick == FilmPick.auto)
      .take(momentCount - always.length)
      .toList();
  final badgedIds = badged.toSet();
  final auto = spreadEvenly(
    eligible
        .where((p) => p.filmPick == FilmPick.auto && !badgedIds.contains(p.id))
        .toList(),
    momentCount - always.length - bonus.length,
  );
  return {
    for (final p in [...always, ...bonus, ...auto]) p.id,
  };
}

/// Picks [count] items spread evenly over [list] (the middle of each equal
/// share), keeping their order; all of [list] when it has no more.
List<T> spreadEvenly<T>(List<T> list, int count) {
  if (count >= list.length) return [...list];
  return [
    for (var k = 0; k < count; k++)
      list[((k + .5) * list.length / count).floor()],
  ];
}

/// By day (undated last), then by when each photo was taken.
int _chronological(PhotoEntity a, PhotoEntity b) {
  final dayA = a.dayDate;
  final dayB = b.dayDate;
  if (dayA != dayB) {
    if (dayA == null) return 1;
    if (dayB == null) return -1;
    final byDay = dayA.compareTo(dayB);
    if (byDay != 0) return byDay;
  }
  return comparePhotosByTime(a, b);
}
