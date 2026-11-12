// Test fixtures for the director (#328).

import type { TripData } from "./gather.ts";
import type { FilmPlan, PlanContext, PlanScene } from "./film_plan.ts";
import type { PhotoAnalysis } from "./photo_analysis.ts";
import type { SkyStoryPlan } from "./sky_story.ts";

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

// A valid rave plan over DIRECTOR_PHOTO_IDS: 16 scenes × ~3s = 48s.
export function ravePlan(ids = DIRECTOR_PHOTO_IDS): FilmPlan {
  const s = (
    type: PlanScene["type"],
    photo_ids: string[],
  ) => scene(type, photo_ids, { duration_s: 3 });
  return {
    ...keepsakePlan(ids),
    occasion: "party",
    recipe: "rave",
    music: { energy: "high" },
    chapters: [
      {
        bridge_line: "Doors at ten.",
        scenes: [
          s("burst", ids.slice(0, 3)),
          s("split", ids.slice(3, 5)),
          s("text_card", []),
          s("text_card", []),
          s("text_card", []),
          s("text_card", []),
          s("text_card", []),
          s("text_card", []),
        ],
      },
      {
        bridge_line: "Then it got loud.",
        scenes: [
          s("burst", ids.slice(5, 9)),
          s("card_flip", [ids[9]]),
          s("split", ids.slice(10, 12)),
          s("text_card", []),
          s("text_card", []),
          s("text_card", []),
          s("text_card", []),
          s("text_card", []),
        ],
      },
    ],
  };
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
