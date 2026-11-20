import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildNeonNightContent,
  dayChapterStarts,
  describeNeonNightProblems,
  type NeonNightPlan,
  nnChapterStarts,
  nnCheckContext,
  repairNeonNight,
} from "./neon_night.ts";
import { directorTripData } from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";
import { useFilmLengthRuleForTests } from "./film_length.ts";

// These tests are about other rules: every film at its longest (#434).
useFilmLengthRuleForTests(false);

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
    problems.some((p) => p.includes("chapter_start")),
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

// --- A long day in parts (#426) --------------------------------------------

// The ADE memory's shape: day 1 from the airport at 08:40 to the rave at
// 06:34, with breaks of 3.3 h (after only 3 photos), 2.6 h and 2.3 h; then
// two shorter days.
function longDays(): TripData {
  const base = directorTripData().photos[0];
  const photos: TripData["photos"] = [];
  const add = (id: string, calendar: string, h: number, m = 0) =>
    photos.push({
      ...base,
      id,
      day_date: calendar,
      taken_at: local(calendar, h, m),
      storage_path: `u/t/${id}.jpg`,
      place_text: null,
      caption: null,
      use_in_wrap_up: null,
    });
  const d1 = "2026-10-23";
  [[8, 40], [8, 42], [8, 50]].forEach(([h, m], k) => add(`air${k}`, d1, h, m));
  [[12, 10], [12, 19], [13, 25], [14, 31], [14, 33]].forEach(([h, m], k) =>
    add(`day${k}`, d1, h, m)
  );
  [[17, 10], [17, 42], [20, 25], [21, 30], [23, 14], [23, 46]].forEach((
    [h, m],
    k,
  ) => add(`eve${k}`, d1, h, m));
  [[3, 4], [3, 5], [6, 34], [6, 35]].forEach(([h, m], k) =>
    add(`rave${k}`, "2026-10-24", h, m)
  );
  [[13, 0], [14, 30], [18, 30], [19, 30]].forEach(([h, m], k) =>
    add(`d2_${k}`, "2026-10-24", h, m)
  );
  [[16, 19], [16, 39], [19, 4], [19, 30]].forEach(([h, m], k) =>
    add(`d3_${k}`, "2026-10-25", h, m)
  );
  return directorTripData({ utc_offset_minutes: OFFSET, photos, notes: [] });
}

Deno.test("a long day breaks into parts at its long breaks (#426)", () => {
  const context = nnCheckContext(longDays());
  const ordered = [...context.photoOrder.entries()].sort((a, b) => a[1] - b[1])
    .map(([id]) => id);
  const starts = nnChapterStarts(context).map((at) => ordered[at]);
  // The longest break, after the airport's 3 photos, would leave too few
  // for a part; the next (2.7 h, before the bar) and the rave's are parts.
  // The 2.6 h one would leave the bus 2 photos. Days 2 and 3 stay whole.
  assertEquals(starts, ["air0", "eve2", "rave0", "d2_0", "d3_0"]);
  // A memory over a single day keeps the director's split.
  const oneDay = longDays();
  oneDay.photos = oneDay.photos.filter((p) =>
    p.id.startsWith("air") ||
    p.id.startsWith("day")
  );
  assertEquals(nnChapterStarts(nnCheckContext(oneDay)), []);
});

Deno.test("repair gives each part a chapter, titled by the director or its time", () => {
  const data = longDays();
  const context = nnCheckContext(data);
  const plan: NeonNightPlan = {
    chapters: [
      {
        title: "Прилет",
        first_photo_id: "air0",
        note_id: null,
        note_excerpt: null,
        moments: [
          { type: "timeline", photo_ids: ["air1", "day2", "eve2", "rave2"] },
        ],
        excerpts: [],
      },
      {
        title: "AMF",
        first_photo_id: "d2_0",
        note_id: null,
        note_excerpt: null,
        moments: [{ type: "split", photo_ids: ["d2_2", "d2_3"] }],
        excerpts: [],
      },
      {
        title: "Брюссель",
        first_photo_id: "d3_0",
        note_id: null,
        note_excerpt: null,
        moments: [{ type: "split", photo_ids: ["d3_0", "d3_1"] }],
        excerpts: [],
      },
    ],
    note_moment: null,
    headline: null,
  };
  const repaired = repairNeonNight(plan, context) as NeonNightPlan;
  assertEquals(describeNeonNightProblems(repaired, context), []);
  assertEquals(repaired.chapters.map((c) => c.title), [
    "Прилет",
    "20:25",
    "03:04",
    "AMF",
    "Брюссель",
  ]);
  // Content: every chapter in its own stretch, each scene after the last.
  const content = buildNeonNightContent(data, repaired);
  let last = -Infinity;
  for (const chapter of content.chapters) {
    const at = (id: string) =>
      Date.parse(chapter.photos.find((p) => p.id === id)!.taken_at);
    for (
      const block of [
        chapter.card_photo_ids,
        ...chapter.moments.map((m) => m.photo_ids),
      ]
    ) {
      const times = block.map(at);
      assertEquals(times, [...times].sort((a, b) => a - b));
      assert(times[0] > last, `${chapter.title} goes back in time`);
      last = times[times.length - 1];
    }
  }
});

Deno.test("an overlong title loses whole words, not the film (#426)", () => {
  const context = nnCheckContext(amsterdam());
  const plan = foldedPlan();
  plan.headline = null;
  plan.chapters[0].title = "Брюссель, ребра и Shelter"; // 25 characters
  const repaired = repairNeonNight(plan, context) as NeonNightPlan;
  assertEquals(describeNeonNightProblems(repaired, context), []);
  assertEquals(repaired.chapters[0].title, "Брюссель, ребра и");
  // One long word can't be shortened: the part's time instead.
  plan.chapters[0].title = "Супердлинноеназваниеглавы";
  const timed = repairNeonNight(plan, context) as NeonNightPlan;
  assertEquals(describeNeonNightProblems(timed, context), []);
  assertEquals(timed.chapters[0].title, "20:00");
});
