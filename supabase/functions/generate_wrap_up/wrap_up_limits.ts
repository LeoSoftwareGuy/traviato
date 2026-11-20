// The Wrap-Up Film's limits (#432) — one config shared with the app:
// lib/features/wrap_up/domain/wrap_up_limits.dart mirrors
// wrap_up_limits.json, and a Dart test fails if they disagree.

import limits from "./wrap_up_limits.json" with { type: "json" };

export const WRAP_UP_LIMITS: Readonly<{
  minPhotos: number;
  maxFilmPhotos: number;
  minNotes: number;
  maxNoteLines: number;
  maxVibes: number;
  shortestFilmSeconds: number;
  longestFilmSeconds: number;
  shortestFilmPhotos: number;
  longestFilmPhotos: number;
}> = Object.freeze({ ...limits });

// What an unkept memory still lacks before its film can be made, or null
// when it's eligible.
export function wrapUpMissing(
  photoCount: number,
  noteCount: number,
  minimums = {
    photos: WRAP_UP_LIMITS.minPhotos,
    notes: WRAP_UP_LIMITS.minNotes,
  },
): { photos: number; notes: number } | null {
  const photos = Math.max(0, minimums.photos - photoCount);
  const notes = Math.max(0, minimums.notes - noteCount);
  return photos === 0 && notes === 0 ? null : { photos, notes };
}

// How long a film of [photos] film photos should play (#434), s: the
// shortest at shortestFilmPhotos or fewer, growing evenly to the longest
// at longestFilmPhotos or more. Each film sizes its scenes to it.
export function filmSeconds(photos: number): number {
  const {
    shortestFilmSeconds: short,
    longestFilmSeconds: long,
    shortestFilmPhotos: from,
    longestFilmPhotos: to,
  } = WRAP_UP_LIMITS;
  const t = Math.min(1, Math.max(0, (photos - from) / (to - from)));
  return short + (long - short) * t;
}
