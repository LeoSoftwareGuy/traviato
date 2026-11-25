// "Arabic retreat" (#468): a memory made in November for an April trip
// (Oman, 8 days, 91 photos, 60 Always), every photo and note added to its
// Journal day after the fact — the camera's day is one day before the
// Journal's on days 1–6, and every note was typed on 2026-11-24. Exported
// from the database by tools/export_director_input.ts (--offset 120: the
// phone's Tallinn clock). Tests run on this, never on a rebuilt copy.
import fixture from "./fixtures/arabic_retreat.json" with { type: "json" };
import { withFilmPhotos } from "./film_photos.ts";
import type { TripData } from "./gather.ts";
import { withLocalTimes } from "./time_zones.ts";

// Every analysed photo's hero score.
export function arabicHeroScores(): Record<string, number> {
  return Object.fromEntries(
    fixture.analyses.map((a) => [a.photo_id, a.hero_score]),
  );
}

// The analyses' summaries by photo.
export function arabicSummaries(): Map<string, string> {
  return new Map(fixture.analyses.map((a) => [a.photo_id, a.summary]));
}

// The memory as the film sees it on open: the photos' summaries attached
// (the handler's attachSummaries), on Muscat's clock (#461), the film's
// photos only.
export function arabicFilmMemory(): TripData {
  const memory = structuredClone(fixture.trip_data) as unknown as TripData;
  const summaries = arabicSummaries();
  for (const p of memory.photos) p.summary = summaries.get(p.id) ?? null;
  return withFilmPhotos(withLocalTimes(memory), arabicHeroScores());
}

// A note's id by the start of its text.
export function arabicNote(start: string): string {
  const n = fixture.trip_data.notes.find((x) => x.content.startsWith(start));
  if (!n) throw new Error(`no note starts with "${start}"`);
  return n.id;
}
