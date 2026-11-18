import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildNeonNightContent,
  dayChapterStarts,
  describeNeonNightProblems,
  type NeonNightPlan,
  nnCheckContext,
  repairNeonNight,
} from "./neon_night.ts";
import { directorTripData } from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";

// The real story (#398): an Amsterdam-shaped memory, Tallinn clock (UTC+2).
// Day 1 runs 20:00–23:00 local, then 01:00–03:00 after midnight (still day
// 1 by the logical-day rule); day 2 12:00–17:00; day 3 11:00–15:00.
const OFFSET = 120;

function local(day: string, hour: number, minute = 0): string {
  // Local wall time → UTC instant.
  const ms = Date.parse(
    `${day}T${String(hour).padStart(2, "0")}:${
      String(minute).padStart(2, "0")
    }:00Z`,
  ) - OFFSET * 60_000;
  return new Date(ms).toISOString();
}

function amsterdam(): TripData {
  const base = directorTripData().photos[0];
  const photos: TripData["photos"] = [];
  const add = (id: string, calendar: string, h: number) =>
    photos.push({
      ...base,
      id,
      day_date: calendar, // old rows: their calendar date
      taken_at: local(calendar, h),
      storage_path: `u/t/${id}.jpg`,
      place_text: null,
    });
  for (let k = 0; k < 4; k++) add(`a${k}`, "2026-09-01", 20 + k);
  for (let k = 0; k < 3; k++) add(`a${4 + k}`, "2026-09-02", 1 + k);
  for (let k = 0; k < 6; k++) add(`b${k}`, "2026-09-02", 12 + k);
  for (let k = 0; k < 5; k++) add(`c${k}`, "2026-09-03", 11 + k);
  return directorTripData({
    utc_offset_minutes: OFFSET,
    photos,
    notes: [
      {
        id: "n1",
        day_date: "2026-09-01",
        legacy: true,
        content: "It was fun. Заказали 4,5 кг рёбер на троих в Брюсселе! " +
          "Everyone was tired.",
      },
      {
        id: "n2",
        day_date: "2026-09-02",
        taken_at: local("2026-09-02", 2, 30),
        photo_id: "a5",
        content: "Danced at Shelter until 3, first time in a club since 2019!",
      },
      {
        id: "n3",
        day_date: "2026-09-02",
        taken_at: local("2026-09-02", 15),
        photo_id: null,
        content: "We went home. Rented 3 bikes and rode 12 km to Zaandam.",
      },
      {
        id: "n4",
        day_date: "2026-09-03",
        taken_at: local("2026-09-03", 13),
        photo_id: null,
        content: "Rain, then stroopwafels at Albert Cuyp market.",
      },
    ],
  });
}

// The director folds day 2 into day 1, picks a generic line, and a
// profane headline.
function foldedPlan(): NeonNightPlan {
  return {
    chapters: [
      {
        title: "Brussels to Shelter",
        first_photo_id: "a0",
        note_id: null,
        note_excerpt: null,
        moments: [
          { type: "split", photo_ids: ["a1", "a2"] },
          { type: "timeline", photo_ids: ["b1", "b2", "b3"] },
        ],
        excerpts: [{ note_id: "n1", text: "It was fun.", photo_id: null }],
      },
      {
        title: "Albert Cuyp",
        first_photo_id: "c0",
        note_id: "n4",
        note_excerpt: "Rain, then stroopwafels",
        moments: [{ type: "burst", photo_ids: ["c3", "c1"] }],
        excerpts: [{
          note_id: "n4",
          text: "Rain, then stroopwafels at Albert Cuyp market.",
          photo_id: "c2",
        }],
      },
    ],
    note_moment: null,
    headline: "Fucking legends",
  };
}

Deno.test("several days need one chapter per logical day", () => {
  const context = nnCheckContext(amsterdam());
  // After midnight stays on day 1; day 2 starts at b0.
  assertEquals(context.photoDays!.get("a6"), "2026-09-01");
  assertEquals(context.photoDays!.get("b0"), "2026-09-02");
  const problems = describeNeonNightProblems(foldedPlan(), context);
  assert(
    problems.some((p) => p.includes("one chapter per day")),
    problems.join("\n"),
  );
  assert(problems.some((p) => p.includes("headline")), problems.join("\n"));
});

Deno.test("repair splits a folded plan by days, keeping the director's words", () => {
  const context = nnCheckContext(amsterdam());
  const repaired = repairNeonNight(foldedPlan(), context) as NeonNightPlan;
  assertEquals(describeNeonNightProblems(repaired, context), []);
  assertEquals(repaired.chapters.map((c) => c.first_photo_id), [
    "a0",
    "b0",
    "c0",
  ]);
  assertEquals(repaired.chapters[0].title, "Brussels to Shelter");
  assertEquals(repaired.chapters[2].title, "Albert Cuyp");
  // Day 2 keeps the folded timeline's photos of its own day.
  assertEquals(repaired.chapters[1].moments[0].photo_ids, ["b1", "b2", "b3"]);
  // Moment photos in time order.
  assertEquals(repaired.chapters[2].moments[0].photo_ids, ["c1", "c3"]);
  assertEquals(repaired.headline, null);
});

Deno.test("content: days, specific excerpts on their photos, strict chronology", () => {
  const data = amsterdam();
  const plan = repairNeonNight(
    foldedPlan(),
    nnCheckContext(data),
  ) as NeonNightPlan;
  const content = buildNeonNightContent(data, plan);
  assertEquals(content.chapters.length, 3);
  assertEquals(content.chapters.map((c) => c.days), [
    ["2026-09-01"],
    ["2026-09-02"],
    ["2026-09-03"],
  ]);
  // After midnight is day 1's.
  assert(content.chapters[0].photos.some((p) => p.id === "a6"));

  const [one, two, three] = content.chapters;
  // Day 1: the generic "It was fun." gives way to the ribs; the club note
  // plays over its own photo.
  const texts = one.excerpts.map((e) => e.text);
  assert(!texts.includes("It was fun."), texts.join(" | "));
  assert(texts.includes("Заказали 4,5 кг рёбер на троих в Брюсселе!"));
  const club = one.excerpts.find((e) => e.note_id === "n2")!;
  assertEquals(club.photo_id, "a5");
  assertEquals(club.source, "code");
  assert(one.rejected_excerpts.some((r) => r.text === "It was fun."));
  // Day 2: the bikes, not "We went home."; on the photo nearest 15:00.
  assertEquals(two.excerpts.map((e) => e.text), [
    "Rented 3 bikes and rode 12 km to Zaandam.",
  ]);
  assertEquals(two.excerpts[0].photo_id, "b3");
  // Day 3: the director's line, on the photo it chose.
  assertEquals(three.excerpts[0].source, "director");
  assertEquals(three.excerpts[0].photo_id, "c2");

  // Chronology: card photos are the chapter's earliest free ones, moments
  // and their photos in time order.
  for (const chapter of content.chapters) {
    const at = new Map(chapter.photos.map((p, i) => [p.id, i]));
    const firsts = chapter.moments.map((m) => at.get(m.photo_ids[0])!);
    assertEquals(firsts, [...firsts].sort((a, b) => a - b));
    for (const m of chapter.moments) {
      const order = m.photo_ids.map((id) => at.get(id)!);
      assertEquals(order, [...order].sort((a, b) => a - b));
    }
    const inMoments = new Set(chapter.moments.flatMap((m) => m.photo_ids));
    const free = chapter.photos.map((p) => p.id).filter((id) =>
      !inMoments.has(id)
    );
    assertEquals(
      chapter.card_photo_ids,
      free.slice(0, chapter.card_photo_ids.length),
    );
  }
  assertEquals(content.headline, null);
});

Deno.test("one night is still split by the director, by time", () => {
  const data = amsterdam();
  data.photos = data.photos.filter((p) => p.id.startsWith("a"));
  const context = nnCheckContext(data);
  const plan: NeonNightPlan = {
    chapters: [
      {
        title: "Ribs",
        first_photo_id: "a0",
        note_id: null,
        note_excerpt: null,
        moments: [{ type: "split", photo_ids: ["a0", "a1"] }],
        excerpts: [],
      },
      {
        title: "Shelter",
        first_photo_id: "a4",
        note_id: null,
        note_excerpt: null,
        moments: [{ type: "split", photo_ids: ["a5", "a6"] }],
        excerpts: [],
      },
    ],
    note_moment: null,
    headline: null,
  };
  assertEquals(describeNeonNightProblems(plan, context), []);
  const repaired = repairNeonNight(plan, context) as NeonNightPlan;
  assertEquals(repaired.chapters.map((c) => c.first_photo_id), ["a0", "a4"]);
});

// --- #422: Amsterdam feedback ------------------------------------------------

Deno.test("an untimed photo keeps its stored day: no 1-photo day chapter", () => {
  const data = amsterdam();
  data.photos.push({
    ...data.photos[data.photos.length - 1],
    id: "untimed",
    taken_at: null,
    created_at: "2026-10-27T10:00:00Z", // uploaded two days later
    storage_path: "u/t/untimed.jpg",
  });
  const context = nnCheckContext(data);
  assertEquals(context.photoDays!.get("untimed"), "2026-09-03");
  assertEquals(dayChapterStarts(context).length, 3);
});

Deno.test("a day the director split by time keeps at most 2 moments", () => {
  const context = nnCheckContext(amsterdam());
  const plan: NeonNightPlan = {
    chapters: [
      ["a0", ["a0", "a1"]],
      ["a2", ["a2", "a3"]],
      ["a4", ["a4", "a5"]],
      ["b0", ["b0", "b1"]],
      ["c0", ["c0", "c1"]],
    ].map(([first, ids], k) => ({
      title: `Part ${k + 1}`,
      first_photo_id: first as string,
      note_id: null,
      note_excerpt: null,
      moments: [{ type: "split" as const, photo_ids: ids as string[] }],
      excerpts: [],
    })),
    note_moment: null,
    headline: null,
  };
  const repaired = repairNeonNight(plan, context) as NeonNightPlan;
  assertEquals(describeNeonNightProblems(repaired, context), []);
  const day1 = repaired.chapters[0];
  assertEquals(day1.moments.length, 2);
  // The first stays; the others' photos make one timeline, in time order.
  assertEquals(day1.moments[0].photo_ids, ["a0", "a1"]);
  assertEquals(day1.moments[1].type, "timeline");
  assertEquals(day1.moments[1].photo_ids, ["a2", "a3", "a4", "a5"]);
});
