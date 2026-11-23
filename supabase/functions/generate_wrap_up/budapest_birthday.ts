// "Elmas birthday" (#460): the first real Golden Vows run — a Romantic
// memory over 4 days in Budapest, exported from the database by
// tools/export_director_input.ts (--offset 120: the phone's Tallinn clock).
// Tests run on this, never on a rebuilt copy.
import fixture from "./fixtures/budapest_birthday.json" with { type: "json" };
import { withFilmPhotos } from "./film_photos.ts";
import type { TripData } from "./gather.ts";
import type { SlotPicks } from "./film_slots.ts";

// Every analysed photo's hero score.
export function budapestHeroScores(): Record<string, number> {
  return Object.fromEntries(
    fixture.analyses.map((a) => [a.photo_id, a.hero_score]),
  );
}

// The analyses' summaries by photo, as the director reads them.
export function budapestSummaries(): Map<string, string> {
  return new Map(fixture.analyses.map((a) => [a.photo_id, a.summary]));
}

// The photos' orientations from the director's run.
export function budapestOrientations(): Record<string, string> {
  return { ...fixture.recorded_director.orientations } as Record<
    string,
    string
  >;
}

// The memory as the director sees it: the film's photos, analysed ones
// (and those left out) only.
export function budapestFilmMemory(): TripData {
  const memory = structuredClone(fixture.trip_data) as unknown as TripData;
  const film = withFilmPhotos(memory, budapestHeroScores());
  const analysed = new Set(fixture.analyses.map((a) => a.photo_id));
  return {
    ...film,
    photos: film.photos.filter((p) =>
      analysed.has(p.id) || p.use_in_wrap_up === false
    ),
  };
}

// The director's free text from that first run (#458's slots): the words
// it wrote are what #460 checks; its ids name slots that changed.
export function budapestFreeTexts(): SlotPicks {
  const picks = fixture.recorded_director.golden_vows.picks as Record<
    string,
    { ids: string[]; free_title: string | null }
  >;
  return Object.fromEntries(
    Object.entries(picks).flatMap(([slot, p]) =>
      p.free_title ? [[slot, { ids: [], free_title: p.free_title }]] : []
    ),
  );
}
