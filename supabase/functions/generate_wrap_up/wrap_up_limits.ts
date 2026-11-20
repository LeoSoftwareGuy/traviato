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
