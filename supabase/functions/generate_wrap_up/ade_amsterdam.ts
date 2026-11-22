// ADE-Amsterdam 2026's real director input (#454), exported from the
// database by tools/export_director_input.ts, and the director's picks
// for it as recorded by tools/record_neon_picks.ts. Tests run on this,
// never on a rebuilt copy.
import fixture from "./fixtures/ade_amsterdam.json" with { type: "json" };
import recorded from "./fixtures/ade_amsterdam_picks.json" with {
  type: "json",
};
import { withFilmPhotos } from "./film_photos.ts";
import type { TripData } from "./gather.ts";
import type { NnPicks } from "./neon_slots.ts";

// The memory as exported (a fresh copy each call).
export function adeMemory(): TripData {
  return structuredClone(fixture.trip_data) as unknown as TripData;
}

// Every analysed photo's hero score.
export function adeHeroScores(): Record<string, number> {
  return Object.fromEntries(
    fixture.analyses.map((a) => [a.photo_id, a.hero_score]),
  );
}

// The analyses by photo, as the director reads them.
export function adeAnalyses(): Map<
  string,
  { summary: string; hero_score: number }
> {
  return new Map(fixture.analyses.map((a) => [a.photo_id, a]));
}

// The memory as the director sees it: the film's photos, analysed ones
// (and those left out) only.
export function adeFilmMemory(): {
  memory: TripData;
  heroScores: Record<string, number>;
} {
  const heroScores = adeHeroScores();
  const film = withFilmPhotos(adeMemory(), heroScores);
  const analysed = new Set(fixture.analyses.map((a) => a.photo_id));
  return {
    memory: {
      ...film,
      photos: film.photos.filter((p) =>
        analysed.has(p.id) || p.use_in_wrap_up === false
      ),
    },
    heroScores,
  };
}

// The director's recorded picks.
export function adePicks(): NnPicks {
  return structuredClone(recorded.picks) as NnPicks;
}
