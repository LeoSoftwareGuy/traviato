import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildSkyContent,
  codeSkyPages,
  dayNumberOf,
  describeSkyStoryProblems,
  firstNameOf,
  groupDays,
  MAX_SKY_MOSAIC_PHOTOS,
  pickExtras,
  pickHero,
  repairSkyStory,
  skyCheckContext,
  type SkyStoryPlan,
} from "./sky_story.ts";
import type { TripData } from "./gather.ts";
import { directorTripData, skyStoryPlan } from "./director_fixtures.ts";

type Photo = TripData["photos"][number];

function addDays(date: string, days: number): string {
  return new Date(Date.parse(`${date}T00:00:00Z`) + days * 86_400_000)
    .toISOString().slice(0, 10);
}

// [perDay[i]] photos on day i + 1 of a memory starting 2026-06-01.
function memory(perDay: number[], overrides: Partial<TripData> = {}): TripData {
  const start = "2026-06-01";
  const photos: Photo[] = [];
  perDay.forEach((count, d) => {
    for (let k = 0; k < count; k++) {
      const date = addDays(start, d);
      photos.push({
        id: `d${d + 1}p${k}`,
        day_date: date,
        taken_at: `${date}T${String(8 + k).padStart(2, "0")}:00:00Z`,
        created_at: `${date}T23:00:00Z`,
        storage_path: `u/t/d${d + 1}p${k}.jpg`,
        caption: null,
        use_in_wrap_up: null,
        place_text: null,
        people_tags: [],
      });
    }
  });
  return {
    ...directorTripData(),
    trip: {
      ...directorTripData().trip,
      start_date: start,
      end_date: addDays(start, perDay.length - 1),
    },
    notes: [],
    photos,
    ...overrides,
  };
}

// --- Day numbers and grouping ---

Deno.test("dayNumberOf counts from 1", () => {
  assertEquals(dayNumberOf("2026-06-01", "2026-06-01"), 1);
  assertEquals(dayNumberOf("2026-06-01", "2026-06-10"), 10);
  // Across the month and a DST change.
  assertEquals(dayNumberOf("2026-03-28", "2026-04-02"), 6);
});

Deno.test("groupDays keeps one group per day up to the limit", () => {
  const days = [1, 2, 4].map((day) => ({ day, count: 3 }));
  assertEquals(groupDays(days, 5), [[1, 1], [2, 2], [4, 4]]);
  assertEquals(groupDays([], 5), []);
});

Deno.test("groupDays balances neighbouring days into 5 groups", () => {
  // 10 days, 4 photos each: two days a page.
  const even = Array.from({ length: 10 }, (_, i) => ({ day: i + 1, count: 4 }));
  assertEquals(groupDays(even, 5), [[1, 2], [3, 4], [5, 6], [7, 8], [9, 10]]);

  // A big day stays alone; the quiet days share.
  const uneven = [1, 1, 30, 1, 1, 1, 1, 1].map((count, i) => ({
    day: i + 1,
    count,
  }));
  const groups = groupDays(uneven, 5);
  assertEquals(groups.length, 5);
  assert(groups.some(([a, b]) => a === 3 && b === 3));
  // Contiguous and in order, covering every day.
  assertEquals(groups[0][0], 1);
  assertEquals(groups.at(-1)![1], 8);
  for (let i = 1; i < groups.length; i++) {
    assertEquals(groups[i][0], groups[i - 1][1] + 1);
  }
});

// --- Hero and extras ---

Deno.test("pickHero: Always > hero score > captioned or placed > middle", () => {
  const photos = memory([5]).photos;
  assertEquals(pickHero(photos, {}).id, "d1p2");

  photos[4].place_text = "Alfama";
  assertEquals(pickHero(photos, {}).id, "d1p4");

  assertEquals(pickHero(photos, { d1p1: 5, d1p4: 3 }).id, "d1p1");

  photos[0].use_in_wrap_up = true;
  assertEquals(pickHero(photos, { d1p1: 5 }).id, "d1p0");
});

Deno.test("pickExtras: up to 4, Always first, spread, chronological", () => {
  const photos = memory([12]).photos;
  const hero = photos[0];
  photos[11].use_in_wrap_up = true;
  const extras = pickExtras(photos, hero).map((p) => p.id);
  assertEquals(extras.length, 4);
  assert(extras.includes("d1p11"));
  assert(!extras.includes(hero.id));
  assertEquals(
    extras,
    [...extras].sort((a, b) => Number(a.slice(3)) - Number(b.slice(3))),
  );

  assertEquals(pickExtras(photos.slice(0, 2), hero).map((p) => p.id), ["d1p1"]);
});

// --- Code-built pages ---

Deno.test("codeSkyPages: one page per day with photos, days without photos skipped", () => {
  const data = memory([3, 0, 2]);
  data.notes = [
    { id: "n1", day_date: "2026-06-01", content: "First day." },
    { id: "n2", day_date: "2026-06-02", content: "No photos today." },
  ];
  const pages = codeSkyPages(data);
  assertEquals(pages.map((p) => [p.first_day, p.last_day]), [[1, null], [
    3,
    null,
  ]]);
  assertEquals(pages[0].date, "2026-06-01");
  assertEquals(pages[0].photo_count, 3);
  assertEquals(pages[0].note_id, "n1");
  assertEquals(pages[1].note_id, null);
  assertEquals(pages[0].headline, null);
  assertEquals(pages[0].sky_line, null);
});

Deno.test("codeSkyPages: a one-day memory is one page", () => {
  const pages = codeSkyPages(memory([20]));
  assertEquals(pages.length, 1);
  assertEquals(pages[0].extra_photo_ids.length, 4);
});

Deno.test("codeSkyPages: 10 days become 5 pages of day ranges", () => {
  const data = memory(Array(10).fill(3));
  data.notes = [
    { id: "a", day_date: "2026-06-03", content: "Short." },
    { id: "b", day_date: "2026-06-04", content: "Also." },
  ];
  const pages = codeSkyPages(data);
  assertEquals(pages.length, 5);
  assertEquals(pages[1].first_day, 3);
  assertEquals(pages[1].last_day, 4);
  assertEquals(pages[1].end_date, "2026-06-04");
  assertEquals(pages[1].photo_count, 6);
  // Both days have 3 photos: the earlier note wins.
  assertEquals(pages[1].note_id, "a");
});

Deno.test("codeSkyPages: a 30-day memory still makes 5 pages", () => {
  const pages = codeSkyPages(memory(Array(30).fill(2)));
  assertEquals(pages.length, 5);
  assertEquals(pages[0].first_day, 1);
  assertEquals(pages.at(-1)!.last_day, 30);
});

Deno.test("codeSkyPages never uses Left-out photos, or photos outside the dates", () => {
  const data = memory([3, 3]);
  data.photos.forEach((p) => {
    if (p.day_date === "2026-06-02") p.use_in_wrap_up = false;
  });
  data.photos.push({ ...data.photos[0], id: "stray", day_date: "2026-07-01" });
  data.photos.push({ ...data.photos[0], id: "dayless", day_date: null });
  const pages = codeSkyPages(data);
  assertEquals(pages.length, 1);
  const shown = [pages[0].hero_photo_id, ...pages[0].extra_photo_ids];
  assert(!shown.includes("stray") && !shown.includes("dayless"));
});

Deno.test("codeSkyPages is stable across rebuilds", () => {
  const data = memory([7, 4, 9]);
  assertEquals(codeSkyPages(data), codeSkyPages(structuredClone(data)));
});

Deno.test("buildSkyContent: no photo on any day → null", () => {
  assertEquals(buildSkyContent(memory([0, 0]), null), null);
  const noDates = memory([3]);
  noDates.trip.start_date = null;
  assertEquals(buildSkyContent(noDates, null), null);
});

Deno.test("buildSkyContent: counts, mosaic and first name", () => {
  const data = memory([40, 40], { username: "  Mari Tamm " });
  data.photos[0].use_in_wrap_up = false;
  const sky = buildSkyContent(data, null)!;
  assertEquals(sky.sky_version, 1);
  assertEquals(sky.source, "code");
  assertEquals(sky.first_name, "Mari");
  assertEquals(sky.title, "Amsterdam");
  assertEquals(sky.moment_count, 80);
  assertEquals(sky.mosaic_photo_ids.length, MAX_SKY_MOSAIC_PHOTOS);
  assert(!sky.mosaic_photo_ids.includes("d1p0"));
});

Deno.test("firstNameOf: first word, none when empty", () => {
  assertEquals(firstNameOf("Leo"), "Leo");
  assertEquals(firstNameOf("  Анна Петрова"), "Анна");
  assertEquals(firstNameOf("   "), null);
  assertEquals(firstNameOf(null), null);
});

Deno.test("buildSkyContent: the director's pages, with counts and dates from code", () => {
  const data = directorTripData();
  const sky = buildSkyContent(data, skyStoryPlan())!;
  assertEquals(sky.source, "director");
  assertEquals(sky.pages.length, 3);
  assertEquals(sky.pages[0], {
    first_day: 1,
    last_day: null,
    date: "2026-09-01",
    end_date: null,
    photo_count: 4,
    headline: "Bikes first, coffee later",
    hero_photo_id: "p01",
    extra_photo_ids: ["p00", "p02", "p03"],
    note_id: "n1",
    note: "Bikes everywhere.",
    sky_line: null,
  });
  assertEquals(
    sky.pages[1].sky_line,
    "You counted eleven bridges and lost count.",
  );
});

// --- Director validation ---

function check(plan: unknown, data = directorTripData()): string[] {
  return describeSkyStoryProblems(plan, skyCheckContext(data));
}

Deno.test("a valid sky_story has no problems", () => {
  assertEquals(check(skyStoryPlan()), []);
});

Deno.test("sky_story shape problems", () => {
  assertEquals(check(null), ["sky_story: expected an object"]);
  assertEquals(check({ pages: [] }), [
    "sky_story.pages: expected at least one page",
  ]);
  const six = { pages: Array(6).fill(skyStoryPlan().pages[0]) };
  assert(check(six).includes("sky_story.pages: 6, at most 5"));
});

Deno.test("sky_story day problems: outside the memory, overlapping, reversed", () => {
  const plan = skyStoryPlan();
  plan.pages[2].days = [3, 4];
  assert(check(plan).some((p) => p.includes("is not within days 1–3")));

  const overlap = skyStoryPlan();
  overlap.pages[1].days = [1, 2];
  assert(
    check(overlap).some((p) => p.includes("overlaps or comes before")),
  );

  const reversed = skyStoryPlan();
  reversed.pages[0].days = [1, 0] as [number, number];
  assert(check(reversed).some((p) => p.startsWith("sky_story.pages[0].days")));
});

Deno.test("sky_story photo problems", () => {
  const invented = skyStoryPlan();
  invented.pages[0].hero_photo_id = "invented";
  assertEquals(check(invented), [
    'sky_story.pages[0].hero_photo_id: "invented" is not a photo id from the input',
  ]);

  const wrongDay = skyStoryPlan();
  wrongDay.pages[0].extra_photo_ids = ["p05"];
  assert(
    check(wrongDay).some((p) =>
      p.includes('"p05" is not from the page\'s days')
    ),
  );
  assert(check(wrongDay).some((p) => p.includes('"p05" is used twice')));

  const data = directorTripData();
  data.photos[1].use_in_wrap_up = false;
  assert(
    check(skyStoryPlan(), data).some((p) => p.includes('"p01" was left out')),
  );

  const tooMany = skyStoryPlan();
  tooMany.pages[0].extra_photo_ids = ["p00", "p02", "p03", "p00", "p02"];
  assert(check(tooMany).some((p) => p.includes("5, at most 4")));
});

Deno.test("sky_story note and line problems", () => {
  const wrongNote = skyStoryPlan();
  wrongNote.pages[0].note_id = "n2";
  assert(
    check(wrongNote).includes(
      "sky_story.pages[0].note_id: the note is not from the page's days",
    ),
  );

  const both = skyStoryPlan();
  both.pages[0].sky_line = "Hello";
  assert(
    check(both).includes(
      "sky_story.pages[0].sky_line: only a page without a note has one",
    ),
  );

  const long = skyStoryPlan();
  long.pages[0].headline = "x".repeat(33);
  assert(
    check(long).includes(
      "sky_story.pages[0].headline: 33 characters, at most 32",
    ),
  );

  const banned = skyStoryPlan();
  banned.pages[1].sky_line = "An epic canal.";
  assert(
    check(banned).includes(
      'sky_story.pages[1].sky_line: banned phrase "epic"',
    ),
  );
});

Deno.test("sky_story Always picks: on their page, and every such day has one", () => {
  const data = directorTripData();
  data.photos[7].use_in_wrap_up = true; // day 2, not on its page
  assertEquals(check(skyStoryPlan(), data), [
    'sky_story.pages[1]: photo "p07" is marked Always but not on its page',
  ]);

  const skipped: SkyStoryPlan = { pages: [skyStoryPlan().pages[0]] };
  assert(
    check(skipped, data).includes(
      "sky_story: day 2 has a photo marked Always but no page",
    ),
  );

  // More Always picks than slots: five shown is enough.
  const busy = directorTripData();
  busy.photos = [
    ...busy.photos,
    ...[12, 13].map((i) => ({ ...busy.photos[0], id: `p${i}` })),
  ];
  busy.photos.filter((p) => p.day_date === "2026-09-01").forEach((p) =>
    p.use_in_wrap_up = true
  );
  const full = skyStoryPlan();
  full.pages[0].extra_photo_ids = ["p00", "p02", "p03", "p12"];
  assertEquals(check(full, busy), []);
});

Deno.test("repairSkyStory trims, de-duplicates and clears what doesn't belong", () => {
  const context = skyCheckContext(directorTripData());
  const raw = skyStoryPlan() as unknown as {
    pages: Record<string, unknown>[];
  };
  raw.pages[0].headline = '"Bikes first"';
  raw.pages[0].extra_photo_ids = ["p01", "p00", "p02", "p03", "p00", "p02"];
  raw.pages[0].sky_line = "Not with a note.";
  raw.pages[1].note_id = "gone";
  delete raw.pages[2].sky_line;

  const fixed = repairSkyStory(raw, context) as SkyStoryPlan;
  assertEquals(fixed.pages[0].headline, "Bikes first");
  assertEquals(fixed.pages[0].extra_photo_ids, ["p00", "p02", "p03", "p00"]);
  assertEquals(fixed.pages[0].sky_line, null);
  assertEquals(fixed.pages[1].note_id, null);
  assertEquals(fixed.pages[2].sky_line, null);
  assertEquals(repairSkyStory("nope", context), "nope");
});
