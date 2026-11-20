// The film's photos (#432, #433): at most WRAP_UP_LIMITS.maxFilmPhotos.
//
// - With minPhotos or more Always picks, the Always picks ARE the film's
//   photos: the director only decides where each one goes.
// - Otherwise the Always picks plus the best Auto photos (hero_score, then
//   spread over the memory), up to the cap.
//
// The photos that don't make it are marked left out in a copy of the
// memory, so every template, check and the director see only the film's.

import type { TripData } from "./gather.ts";
import { sortPhotosChronologically } from "./assemble.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";

type Photo = TripData["photos"][number];

// A photo the director hasn't analysed scores as an average one.
const UNKNOWN_SCORE = 3;

// The ids of the film's photos, chronological.
export function filmPhotoIds(
  tripData: TripData,
  heroScores: Readonly<Record<string, number>> = {},
  max: number = WRAP_UP_LIMITS.maxFilmPhotos,
): string[] {
  const shown = sortPhotosChronologically(
    tripData.photos.filter((p) => p.use_in_wrap_up !== false),
  );
  const always = shown.filter((p) => p.use_in_wrap_up === true);
  const pool = always.length >= WRAP_UP_LIMITS.minPhotos ? always : shown;
  if (pool.length <= max) return pool.map((p) => p.id);

  const index = new Map(pool.map((p, i) => [p.id, i]));
  const score = (p: Photo) => heroScores[p.id] ?? UNKNOWN_SCORE;
  const picked = new Set<string>();
  // Always picks first (only more than the cap when the pool is them all).
  const rank = (photos: Photo[]) =>
    [...photos].sort((a, b) =>
      score(b) - score(a) || index.get(a.id)! - index.get(b.id)!
    );
  for (const p of rank(always)) {
    if (picked.size >= max) break;
    picked.add(p.id);
  }
  // Then the best Auto photos; among equals, spread over the memory.
  const auto = pool.filter((p) => !picked.has(p.id));
  const byScore = new Map<number, Photo[]>();
  for (const p of auto) {
    const s = score(p);
    byScore.set(s, [...(byScore.get(s) ?? []), p]);
  }
  for (const s of [...byScore.keys()].sort((a, b) => b - a)) {
    const group = byScore.get(s)!;
    const room = max - picked.size;
    if (room <= 0) break;
    for (const p of spread(group, room)) picked.add(p.id);
  }
  return pool.filter((p) => picked.has(p.id)).map((p) => p.id);
}

// Up to [count] of [items], evenly spread, in order.
function spread<T>(items: T[], count: number): T[] {
  if (items.length <= count) return items;
  return Array.from(
    { length: count },
    (_, k) => items[Math.floor((k + 0.5) * items.length / count)],
  );
}

// [tripData] with every photo outside the film marked left out, so the
// templates and the director see only the film's photos. Unchanged when
// they all fit.
export function withFilmPhotos(
  tripData: TripData,
  heroScores: Readonly<Record<string, number>> = {},
): TripData {
  const ids = new Set(filmPhotoIds(tripData, heroScores));
  if (
    tripData.photos.every((p) => p.use_in_wrap_up === false || ids.has(p.id))
  ) {
    return tripData;
  }
  return {
    ...tripData,
    photos: tripData.photos.map((p) =>
      p.use_in_wrap_up === false || ids.has(p.id)
        ? p
        : { ...p, use_in_wrap_up: false }
    ),
  };
}
