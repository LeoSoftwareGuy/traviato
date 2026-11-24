// Test fixtures for the director (#328).

import type { TripData } from "./gather.ts";
import { goldenVowsFilm } from "./gv_film.ts";
import type { SlotPicks } from "./film_slots.ts";
import type { PhotoAnalysis } from "./photo_analysis.ts";
import { skyStoryFilm } from "./sky_film.ts";
import { neonNightFilm } from "./neon_film.ts";
import type { NnPicks } from "./neon_slots.ts";

export const DIRECTOR_PHOTO_IDS = Array.from(
  { length: 12 },
  (_, i) => `p${String(i).padStart(2, "0")}`,
);

// 12 photos over 3 days (4 a day), chronological by id. No picks — tests
// set use_in_wrap_up themselves.
export function directorTripData(
  overrides: Partial<TripData> = {},
): TripData {
  return {
    trip: {
      name: "Amsterdam",
      destination: "Netherlands",
      country_code: "NL",
      start_date: "2026-09-01",
      end_date: "2026-09-03",
      vibes: ["Cultural"],
      cover_image_path: null,
    },
    notes: [
      { id: "n1", day_date: "2026-09-01", content: "Bikes everywhere." },
      { id: "n2", day_date: "2026-09-03", content: "Rain, then stroopwafels." },
    ],
    photos: DIRECTOR_PHOTO_IDS.map((id, i) => ({
      id,
      day_date: `2026-09-0${1 + Math.floor(i / 4)}`,
      taken_at: `2026-09-0${1 + Math.floor(i / 4)}T${10 + (i % 4)}:00:00Z`,
      created_at: "2026-09-04T00:00:00Z",
      storage_path: `u/t/${id}.jpg`,
      caption: null,
      use_in_wrap_up: null,
      place_text: i === 0 ? "Centraal" : null,
      people_tags: [],
    })),
    completedBonusTasks: [],
    starsEarned: 10,
    latestAchievement: null,
    ...overrides,
  };
}

export function analysisFor(id: string): PhotoAnalysis {
  return {
    photo_id: id,
    summary: "A canal with bikes on a bridge",
    setting: "city",
    people: "0",
    energy: "calm",
    quality: "sharp",
    orientation: "portrait",
    hero_score: 4,
    dup_group: null,
  };
}

// A pick_sky_lines answer for [data] (#463): code's own choices, page
// 1's headline written by the director, and page 1's second line its
// list's last candidate.
export function skyPicksAnswer(data: TripData): {
  picks: { slot: string; ids: string[]; free_title: string | null }[];
} {
  const { report } = skyStoryFilm(data, null);
  return {
    picks: report.map((r) => ({
      slot: r.slot,
      ids: r.slot === "p1.headline"
        ? []
        : r.slot === "p1.line2" && r.candidates.length > 1
        ? [r.candidates.at(-1)!.id]
        : r.chosen.length === 0
        ? r.candidates.slice(0, 1).map((c) => c.id)
        : r.chosen.map((c) => c.id),
      free_title: r.slot === "p1.headline" ? "Bikes first" : null,
    })),
  };
}

// [skyPicksAnswer] as the director record stores it.
export function skyPicks(data: TripData): SlotPicks {
  return Object.fromEntries(
    skyPicksAnswer(data).picks.map((p) => [p.slot, {
      ids: p.ids,
      free_title: p.free_title,
    }]),
  );
}

// An Anthropic Messages response whose only block is a tool call.
export function toolResponse(
  name: string,
  input: unknown,
  usage = { input_tokens: 1000, output_tokens: 200 },
): Response {
  return new Response(
    JSON.stringify({
      content: [{ type: "tool_use", id: "t1", name, input }],
      stop_reason: "tool_use",
      usage,
    }),
    { status: 200 },
  );
}

// A valid Neon Night section over directorTripData(): 3 chapters of 4
// photos (one per day), chapter 1 split + burst with an excerpt of day 1's
// note, chapter 2 a timeline, chapter 3 a peak; day 3's note in neon.
// A pick_neon_lines answer for [data] (#454): code's own resolved picks
// (so none collide), chapter 1 titled "Doors open" by the director and
// every title code would call "Day N" "Part N".
export function neonPicksAnswer(data: TripData): {
  picks: { slot: string; ids: string[]; free_title: string | null }[];
} {
  const { report } = neonNightFilm(data, null);
  return {
    picks: report.map((r) => ({
      slot: r.slot,
      ids: r.slot === "ch1.title" ? [] : r.chosen.length === 0
        // Nothing played without picks (its words were taken): the
        // director still names its top candidate.
        ? r.candidates.slice(0, 1).map((c) => c.id)
        : r.chosen.map((c) => c.id).filter((id) =>
          id !== "day" && id !== "free"
        ),
      // A title no candidate fits: the director writes one.
      free_title: r.slot === "ch1.title"
        ? "Doors open"
        : r.slot.endsWith(".title") && r.chosen[0]?.id === "day"
        ? `Part ${r.slot.slice(2, r.slot.indexOf("."))}`
        : null,
    })),
  };
}

// [neonPicksAnswer] as the director record stores it.
export function neonPicks(data: TripData): NnPicks {
  return Object.fromEntries(
    neonPicksAnswer(data).picks.map((p) => [p.slot, {
      ids: p.ids,
      free_title: p.free_title,
    }]),
  );
}

// A pick_golden_vows_lines answer for [data] (#458): code's own choices,
// the finale's last candidate instead, and a title of the director's own.
export function gvPicksAnswer(
  data: TripData,
  summaries: ReadonlyMap<string, string> = new Map(),
): {
  picks: { slot: string; ids: string[]; free_title: string | null }[];
} {
  const { report } = goldenVowsFilm(data, null, { summaries });
  return {
    picks: report.map((r) => ({
      slot: r.slot,
      ids: r.slot === "ch1.title"
        ? []
        : r.slot === "finale"
        ? [r.candidates.at(-1)!.id]
        : r.chosen.length === 0
        // Nothing played without picks (its words were taken): the
        // director still names its top candidate.
        ? r.candidates.slice(0, 1).map((c) => c.id)
        : r.chosen.map((c) => c.id).filter((id) =>
          id !== "day" && id !== "free"
        ),
      // A title no candidate fits: the director writes one.
      free_title: r.slot === "ch1.title"
        ? "Slow morning"
        : r.slot.endsWith(".title") && r.chosen[0]?.id === "day"
        ? `Slow part ${r.slot.slice(2, r.slot.indexOf("."))}`
        : null,
    })),
  };
}

// [gvPicksAnswer] as the director record stores it.
export function gvPicks(
  data: TripData,
  summaries: ReadonlyMap<string, string> = new Map(),
): SlotPicks {
  return Object.fromEntries(
    gvPicksAnswer(data, summaries).picks.map((p) => [p.slot, {
      ids: p.ids,
      free_title: p.free_title,
    }]),
  );
}
