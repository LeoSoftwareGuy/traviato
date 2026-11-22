// The real story (#398) on code's skeleton (#454): logical days, parts of
// a long day, the notes' best lines on their own photos, strict
// chronology.
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  dayChapterStarts,
  nnChapterStarts,
  nnCheckContext,
} from "./neon_night.ts";
import { buildNeonNightContent, neonNightFilm } from "./neon_film.ts";
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

Deno.test("content: a chapter per logical day, specific lines on their photos, strict chronology", () => {
  const data = amsterdam();
  const content = buildNeonNightContent(data);
  assertEquals(content.chapters.map((c) => c.days), [
    ["2026-09-01"],
    ["2026-09-02"],
    ["2026-09-03"],
  ]);
  // After midnight is day 1's.
  assert(content.chapters[0].photos.some((p) => p.id === "a6"));

  const lines = content.chapters.flatMap((c) => c.excerpts.map((e) => e.text));
  // The generic lines never play while a specific one is left.
  for (
    const generic of ["It was fun.", "Everyone was tired.", "We went home."]
  ) {
    assert(!lines.includes(generic), lines.join(" | "));
  }
  // The club note (after midnight, so day 1's) plays: the Note scene,
  // over its own photo — and so in no other scene.
  assertEquals(content.note?.photo_id, "a5");
  assert(content.note?.text.startsWith("Danced at Shelter until 3"));
  assert(!lines.some((l) => l.startsWith("Danced at Shelter")));

  for (const chapter of content.chapters) {
    const at = new Map(chapter.photos.map((p, i) => [p.id, i]));
    const blocks = [
      chapter.card_photo_ids,
      ...chapter.moments.map((m) => m.photo_ids),
    ].map((ids) => ids.map((id) => at.get(id)!));
    for (const [k, block] of blocks.entries()) {
      assertEquals(block, [...block].sort((a, b) => a - b));
      if (k > 0) assert(Math.max(...blocks[k - 1]) < Math.min(...block));
    }
  }
});

Deno.test("a profane line is never the headline or a title", () => {
  const data = amsterdam();
  data.notes[2].content = "Fucking legends. Rented 3 bikes and rode 12 km.";
  const { slots, content } = neonNightFilm(data, null);
  for (const s of slots) {
    if (s.kind !== "title" && s.kind !== "headline") continue;
    assert(s.candidates.every((c) => !/fuck/i.test(c.text)), s.slot);
  }
  assert(!/fuck/i.test(content.headline ?? ""));
});

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
  // A memory over a single day isn't cut by days: its night is.
  const oneDay = longDays();
  oneDay.photos = oneDay.photos.filter((p) =>
    p.id.startsWith("air") ||
    p.id.startsWith("day")
  );
  assertEquals(nnChapterStarts(nnCheckContext(oneDay)), []);
});
