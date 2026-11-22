// Neon Night's skeleton and content (#454): code cuts the chapters and
// deals their scenes; picks only choose words (neon_slots.test.ts).
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { MAX_NN_PHOTOS } from "./neon_night.ts";
import { buildNeonNightContent } from "./neon_film.ts";
import {
  DIRECTOR_PHOTO_IDS as IDS,
  directorTripData,
  neonPicks,
} from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";
import { useFilmLengthRuleForTests } from "./film_length.ts";

// These tests are about other rules: every film at its longest (#434).
useFilmLengthRuleForTests(false);

// directorTripData() with 5 more photos a day (14:00–18:00, ids
// "d<day>x<k>"): 9 per chapter, so none merges (#390).
function fullNight(overrides: Partial<TripData> = {}): TripData {
  const data = directorTripData(overrides);
  const extra: TripData["photos"] = [];
  for (let day = 1; day <= 3; day++) {
    for (let k = 0; k < 5; k++) {
      extra.push({
        ...data.photos[0],
        id: `d${day}x${k}`,
        day_date: `2026-09-0${day}`,
        taken_at: `2026-09-0${day}T${14 + k}:00:00Z`,
        storage_path: `u/t/d${day}x${k}.jpg`,
        place_text: null,
      });
    }
  }
  data.photos = [...data.photos, ...extra];
  return data;
}

Deno.test("content.neon_night: a chapter per day, every photo dealt in time order, totals", () => {
  const quest = (title: string, day: string, time: string, done = false) => ({
    title,
    day_date: day,
    time,
    completed_at: done ? `${day}T22:30:00Z` : null,
  });
  const data = fullNight({
    quests: [
      quest("Pre-drinks", "2026-09-01", "22:00:00", true),
      { ...quest("No time", "2026-09-01", "00:00:00"), time: null },
      quest("Afterparty", "2026-09-02", "03:00:00"),
      quest("Breakfast", "2026-09-03", "09:00:00"),
    ],
    username: "Leo Engineer",
  });
  const content = buildNeonNightContent(data);

  assertEquals(content.nn_version, 1);
  assertEquals(content.title, "Amsterdam");
  assertEquals(content.plan, [
    { time: "22:00", title: "Pre-drinks", done: true },
    { time: "03:00", title: "Afterparty", done: false },
    { time: "09:00", title: "Breakfast", done: false },
  ]);
  assertEquals(
    content.chapters.map((c) => c.photos.slice(0, 4).map((p) => p.id)),
    [IDS.slice(0, 4), IDS.slice(4, 8), IDS.slice(8, 12)],
  );
  assertEquals(content.chapters.map((c) => c.photos.length), [9, 9, 9]);
  assertEquals(content.chapters[0].photos[0].taken_at, "2026-09-01T10:00:00Z");
  // 9 photos: a card of 4 and one timeline of 5 (#444).
  for (const chapter of content.chapters) {
    assertEquals(chapter.card_photo_ids.length, 4);
    assertEquals(
      chapter.moments.map((m) => [m.type, m.photo_ids.length]),
      [["timeline", 5]],
    );
    assertStrictlyAfterCard(chapter);
    assert(chapter.title.length > 0);
  }
  assertEquals(content.chapters[0].moments[0].place, null);
  assertEquals(content.first_name, "Leo");
  assertEquals(content.totals, { photos: 27, notes: 2, ticks: 1, moments: 27 });
});

Deno.test("the director's picks only change words, never the scenes", () => {
  const data = fullNight();
  const code = buildNeonNightContent(data);
  const picked = buildNeonNightContent(data, neonPicks(data));
  const scenes = (c: typeof code) =>
    c.chapters.map((ch) => [
      ch.photos.map((p) => p.id),
      ch.card_photo_ids,
      ch.moments.map((m) => [m.type, m.photo_ids]),
    ]);
  assertEquals(scenes(picked), scenes(code));
  assertEquals(picked.chapters[0].title, "Doors open");
});

Deno.test("one night is split into parts at its long breaks, never merged", () => {
  // 12 photos an hour apart: no break of 2 h, one chapter.
  const content = buildNeonNightContent(oneNight());
  assertEquals(content.chapters.length, 1);
  assertEquals(content.chapters[0].photos.length, 12);
  assertStrictlyAfterCard(content.chapters[0]);
});

Deno.test("the card opens a chapter with its earliest photos (#426)", () => {
  const content = buildNeonNightContent(fullNight());
  for (const chapter of content.chapters) {
    const shown = new Set([
      ...chapter.card_photo_ids,
      ...chapter.moments.flatMap((m) => m.photo_ids),
    ]);
    const first = chapter.photos.find((p) => shown.has(p.id))!;
    assertEquals(chapter.card_photo_ids[0], first.id);
    assertStrictlyAfterCard(chapter);
  }
});

Deno.test("the Plan scene needs 3 rows", () => {
  const quest = (title: string, time: string) => ({
    title,
    day_date: "2026-09-01",
    time,
    completed_at: null,
  });
  const two = buildNeonNightContent(
    fullNight({ quests: [quest("Fly", "07:00:00"), quest("Eat", "09:00:00")] }),
  );
  assertEquals(two.plan, []);
  const three = buildNeonNightContent(
    fullNight({
      quests: [
        quest("Fly", "07:00:00"),
        quest("Eat", "09:00:00"),
        quest("Club", "23:00:00"),
      ],
    }),
  );
  assertEquals(three.plan.length, 3);
});

Deno.test("chapter photos carry the user's caption, trimmed (#387)", () => {
  const data = fullNight();
  data.photos.find((p) => p.id === "p01")!.caption = "  Lost the keys ";
  data.photos.find((p) => p.id === "p02")!.caption = "   ";
  const photos = buildNeonNightContent(data).chapters[0]
    .photos;
  const caption = (id: string) => photos.find((p) => p.id === id)!.caption;
  assertEquals(caption("p01"), "Lost the keys");
  assertEquals(caption("p02"), null);
  assertEquals(caption("p03"), null);
});

Deno.test("a photo added later joins the chapter it falls in", () => {
  const data = fullNight();
  data.photos.push({
    ...data.photos[5],
    id: "late",
    taken_at: "2026-09-02T12:30:00Z",
  });
  const content = buildNeonNightContent(data);
  assert(content.chapters[1].photos.some((p) => p.id === "late"));
});

Deno.test("over 200 photos: never more than the cap, every day kept", () => {
  const data = directorTripData();
  data.photos.push(
    ...Array.from({ length: 300 }, (_, i) => ({
      ...data.photos[11],
      id: `x${String(i).padStart(3, "0")}`,
      taken_at: `2026-09-03T14:${String(i % 60).padStart(2, "0")}:${
        String(Math.floor(i / 60)).padStart(2, "0")
      }Z`,
    })),
  );
  const content = buildNeonNightContent(data);
  const shown = content.chapters.flatMap((c) => c.photos.map((p) => p.id));
  assert(shown.length <= MAX_NN_PHOTOS + 6, `${shown.length}`);
  // Each day keeps its chapter.
  assertEquals(content.chapters.length >= 3, true);
  assertEquals(content.totals.photos, 312);
});

Deno.test("the heart leaves out Always picks that have their moment", () => {
  const data = directorTripData();
  data.photos = Array.from({ length: 40 }, (_, i) => ({
    ...data.photos[i % 12],
    id: `h${String(i).padStart(2, "0")}`,
    taken_at: `2026-09-01T22:${String(i).padStart(2, "0")}:00Z`,
    day_date: "2026-09-01",
    use_in_wrap_up: i === 1 || i === 3 ? true : null,
  }));
  const content = buildNeonNightContent(data);
  assertEquals(
    content.heart_photo_ids.filter((id) => id === "h01" || id === "h03"),
    [],
  );
  assertEquals(content.heart_photo_ids.length, 38);
  // Every photo still plays in its chapter.
  assertEquals(content.chapters.flatMap((c) => c.photos).length, 40);
});

Deno.test("a big chapter: a 6-photo card, two full moments, the Always picks shown", () => {
  const data = fullNight();
  // 10 more photos on day 2, the last two marked Always.
  for (let k = 0; k < 10; k++) {
    data.photos.push({
      ...data.photos[4],
      id: `x${k}`,
      taken_at: `2026-09-02T${
        String(19 + Math.floor(k / 6)).padStart(2, "0")
      }:${String(k * 5).padStart(2, "0")}:00Z`,
      storage_path: `u/t/x${k}.jpg`,
      use_in_wrap_up: k >= 8 ? true : null,
    });
  }
  const chapter = buildNeonNightContent(data).chapters[1];
  assertEquals(chapter.card_photo_ids.length, 6);
  assertEquals(chapter.moments.length, 2);
  const shown = [
    ...chapter.card_photo_ids,
    ...chapter.moments.flatMap((m) => m.photo_ids),
  ];
  // 19 photos: a card of 6 and two moments of up to 6 (#448); the one
  // left over goes to the heart, never an Always pick.
  assertEquals(new Set(shown).size, chapter.photos.length - 1);
  assert(shown.includes("x8") && shown.includes("x9"));
  assertStrictlyAfterCard(chapter);
});

Deno.test("a chapter of up to 6 photos is one full card, no moment (#444)", () => {
  const data = fullNight();
  // Chapter 2 keeps only its 4 own photos.
  for (const p of data.photos) {
    if (p.id.startsWith("d2x")) p.use_in_wrap_up = false;
  }
  const chapter = buildNeonNightContent(data).chapters[1];
  assertEquals(chapter.card_photo_ids, ["p04", "p05", "p06", "p07"]);
  assertEquals(chapter.moments, []);
});

// The card's photos come first in time, then each moment's (#426).
function assertStrictlyAfterCard(
  chapter: ReturnType<typeof buildNeonNightContent>["chapters"][number],
) {
  const at = new Map(chapter.photos.map((p, i) => [p.id, i]));
  const blocks = [
    chapter.card_photo_ids,
    ...chapter.moments.map((m) => m.photo_ids),
  ].map((ids) => ids.map((id) => at.get(id)!));
  for (const block of blocks) {
    assertEquals(block, [...block].sort((a, b) => a - b));
  }
  for (let k = 1; k < blocks.length; k++) {
    assert(
      Math.max(...blocks[k - 1]) < Math.min(...blocks[k]),
      `block ${k} goes back in time: ${JSON.stringify(blocks)}`,
    );
  }
}

// directorTripData() as one night: the 12 photos an hour apart from 10:00.
function oneNight(): TripData {
  const data = directorTripData();
  data.photos = data.photos.map((p, i) => ({
    ...p,
    day_date: "2026-09-01",
    taken_at: `2026-09-01T${String(10 + i).padStart(2, "0")}:00:00Z`,
  }));
  return data;
}
