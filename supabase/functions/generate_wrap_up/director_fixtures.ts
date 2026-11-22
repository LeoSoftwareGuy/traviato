// Test fixtures for the director (#328).

import type { TripData } from "./gather.ts";
import { goldenVowsFilm } from "./gv_film.ts";
import type { SlotPicks } from "./film_slots.ts";
import type { FilmPlan, PlanContext, PlanScene } from "./film_plan.ts";
import type { PhotoAnalysis } from "./photo_analysis.ts";
import type { SkyStoryPlan } from "./sky_story.ts";
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

function scene(
  type: PlanScene["type"],
  photo_ids: string[],
  extra: Partial<PlanScene> = {},
): PlanScene {
  return {
    type,
    photo_ids,
    caption_note_id: null,
    text: type === "text_card" ? "And then the rain." : null,
    duration_s: 5,
    emphasis: "normal",
    ...extra,
  };
}

// A valid Sky Story section over directorTripData(): one page per day (4
// photos a day), day 2 without a note so it carries a sky line.
export function skyStoryPlan(ids = DIRECTOR_PHOTO_IDS): SkyStoryPlan {
  return {
    pages: [
      {
        days: [1, 1],
        headline: "Bikes first, coffee later",
        hero_photo_id: ids[1],
        extra_photo_ids: [ids[0], ids[2], ids[3]],
        note_id: "n1",
        sky_line: null,
      },
      {
        days: [2, 2],
        headline: "The canal hour",
        hero_photo_id: ids[5],
        extra_photo_ids: [ids[4], ids[6]],
        note_id: null,
        sky_line: "You counted eleven bridges and lost count.",
      },
      {
        days: [3, 3],
        headline: "Rain on the stroopwafels",
        hero_photo_id: ids[9],
        extra_photo_ids: [ids[8], ids[10], ids[11]],
        note_id: "n2",
        sky_line: null,
      },
    ],
  };
}

// keepsakePlan() as the model emits it: with its sky_story section.
export function emittedPlan(
  ids = DIRECTOR_PHOTO_IDS,
): FilmPlan & { sky_story: SkyStoryPlan } {
  return { ...keepsakePlan(ids), sky_story: skyStoryPlan(ids) };
}

// A valid keepsake plan over DIRECTOR_PHOTO_IDS: 10 scenes × 5s = 50s.
export function keepsakePlan(ids = DIRECTOR_PHOTO_IDS): FilmPlan {
  return {
    plan_version: 2,
    occasion: "city",
    recipe: "keepsake",
    music: { energy: "calm" },
    language: "en",
    chapters: [
      {
        bridge_line: "You came for the canals.",
        scenes: [
          scene("card_flip", [ids[0]], {
            emphasis: "hero",
            caption_note_id: "n1",
          }),
          scene("collage_3", ids.slice(1, 4)),
          scene("card_flip", [ids[4]]),
          scene("text_card", []),
        ],
      },
      {
        bridge_line: "Then the bikes won.",
        scenes: [
          scene("card_flip", [ids[5]]),
          scene("collage_4", ids.slice(6, 10)),
          scene("card_flip", [ids[10]]),
          scene("card_flip", [ids[11]]),
          scene("text_card", []),
          scene("text_card", []),
        ],
      },
    ],
    footnote: { line: "Three days, one wet umbrella." },
    closing_line: "You left with dry socks, barely.",
    reasoning: "A quiet city trip, so keepsake.",
  };
}

// keepsakePlan with the faults from the first hosted run (#332): no
// plan_version, and a collage_3 holding only 2 photos.
export function keepsakePlanWithFixableFaults(
  ids = DIRECTOR_PHOTO_IDS,
): Record<string, unknown> {
  const plan = emittedPlan(ids) as unknown as Record<string, unknown>;
  delete plan.plan_version;
  const chapters = plan.chapters as FilmPlan["chapters"];
  chapters[0].scenes[1] = scene("collage_3", ids.slice(1, 3), {
    caption_note_id: "n2",
  });
  return plan;
}

export function planContext(
  overrides: Partial<PlanContext> = {},
): PlanContext {
  return {
    language: "en",
    photoOrder: DIRECTOR_PHOTO_IDS,
    excludedIds: new Set(),
    mustIncludeIds: new Set(),
    noteIds: new Set(["n1", "n2"]),
    ...overrides,
  };
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
      ids: r.slot === "ch1.title"
        ? []
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
        : r.chosen.map((c) => c.id).filter((id) =>
          id !== "day" && id !== "free"
        ),
      // A title no candidate fits: the director writes one.
      free_title: r.slot === "ch1.title"
        ? "Canal morning"
        : r.slot.endsWith(".title") && r.chosen[0]?.id === "day"
        ? `Canal part ${r.slot.slice(2, r.slot.indexOf("."))}`
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
