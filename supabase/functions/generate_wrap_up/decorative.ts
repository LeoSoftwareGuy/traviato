// Photos for a film's decorative ending — Sky Story's balloon mosaic, the
// Golden Vows and Neon Night hearts (#378).
//
// "Always" (#294) means the user wants to *see* that photo, and a 36 px
// tile in a mosaic isn't seeing it. So Always picks get a proper moment
// elsewhere in the film, and the ending is made from the other photos:
// Auto picks, plus any Always pick that found no moment (the film's known
// limit — better a tile than nothing). Only when that leaves too few for
// the ending to look full are other Always picks added back. Leave-out
// picks never appear.

import type { TripData } from "./gather.ts";
import { sortPhotosChronologically, spreadEvenly } from "./assemble.ts";

type Photo = TripData["photos"][number];

// Below this many photos an ending looks sparse, so Always picks top it up.
export const MIN_DECORATIVE_PHOTOS = 12;

// Up to [max] photos for the ending, chronological. [shownIds] are the
// photos the film already gives a moment.
export function decorativePhotos(
  photos: readonly Photo[],
  shownIds: ReadonlySet<string>,
  max: number,
): Photo[] {
  const usable = sortPhotosChronologically(
    photos.filter((p) => p.use_in_wrap_up !== false),
  );
  const isOwnMoment = (p: Photo) =>
    p.use_in_wrap_up === true && shownIds.has(p.id);
  const base = usable.filter((p) => !isOwnMoment(p));
  const wanted = Math.min(MIN_DECORATIVE_PHOTOS, usable.length);
  const topUp = base.length < wanted
    ? spreadEvenly(usable.filter(isOwnMoment), wanted - base.length)
    : [];
  const picked = new Set([...base, ...topUp]);
  return spreadEvenly(usable.filter((p) => picked.has(p)), max);
}
