// Sky Story: code cuts the pages, the director picks the words (#463).

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import type { TripData } from "./gather.ts";
import { directorTripData } from "./director_fixtures.ts";
import {
  alwaysWithoutPage,
  dayNumberOf,
  firstNameOf,
  MAX_SKY_PAGES,
} from "./sky_story.ts";
import {
  buildSkySkeleton,
  groupDaysEvenly,
  skyLimitSeconds,
  skyPageRoom,
} from "./sky_skeleton.ts";
import { buildSkySlots, skyWordGuard, skyWordsProblem } from "./sky_slots.ts";
import { skySecondsAt, skyStoryFilm } from "./sky_film.ts";
import { withFilmPhotos } from "./film_photos.ts";
import { isBackfilled } from "./film_slots.ts";
import {
  SKY_REFERENCE_SECONDS,
  useFilmLengthRuleForTests,
} from "./film_length.ts";

// These tests are about other rules: every page the film can hold (#434);
// the length tests switch it on.
useFilmLengthRuleForTests(false);

function withLengthRule(run: () => void) {
  useFilmLengthRuleForTests(true);
  try {
    run();
  } finally {
    useFilmLengthRuleForTests(false);
  }
}

type Photo = TripData["photos"][number];

function addDays(date: string, days: number): string {
  return new Date(Date.parse(`${date}T00:00:00Z`) + days * 86_400_000)
    .toISOString().slice(0, 10);
}

// [perDay[i]] photos on day i + 1 of a memory starting 2026-06-01, an
// hour apart from 08:00.
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
      name: "Summer",
      destination: null,
      start_date: start,
      end_date: addDays(start, perDay.length - 1),
    },
    notes: [],
    photos,
    ...overrides,
  };
}

const note = (
  id: string,
  day: string,
  content: string,
  extra: Partial<TripData["notes"][number]> = {},
): TripData["notes"][number] => ({ id, day_date: day, content, ...extra });

Deno.test("dayNumberOf counts from 1; firstNameOf the first word", () => {
  assertEquals(dayNumberOf("2026-06-01", "2026-06-01"), 1);
  assertEquals(dayNumberOf("2026-06-01", "2026-06-10"), 10);
  assertEquals(firstNameOf("Mari Tamm"), "Mari");
  assertEquals(firstNameOf("  "), null);
});

// --- The length decides how many pages --------------------------------

Deno.test("the limit: 75 s, and 4 s a film photo below", () => {
  assertEquals(skyLimitSeconds(15), 60);
  assertEquals(skyLimitSeconds(40), 75);
  withLengthRule(() => {
    // 15 photos: 60 s holds 3 pages (54 s); 19+ photos all 5.
    assertEquals(skyPageRoom(15), 3);
    assertEquals(skyPageRoom(19), 5);
    assertEquals(skyPageRoom(60), MAX_SKY_PAGES);
  });
});

Deno.test("skySecondsAt plays the reference lengths without words", () => {
  for (let count = 1; count <= 5; count++) {
    const pages = Array.from(
      { length: count },
      () => ({ extras: 4, words: null, caption: null }),
    );
    assertEquals(skySecondsAt(pages, null), SKY_REFERENCE_SECONDS[count - 1]);
  }
  // A long note: its page plays long enough to be read.
  const long = "word ".repeat(40).trim();
  assert(
    skySecondsAt([{ extras: 4, words: long, caption: null }], null) >
      SKY_REFERENCE_SECONDS[0],
  );
});

// --- Pages ------------------------------------------------------------

Deno.test("one page per logical day; days without photos have none", () => {
  const { pages } = buildSkySkeleton(memory([4, 0, 4, 4, 4]));
  assertEquals(pages.map((p) => p.days), [
    ["2026-06-01"],
    ["2026-06-03"],
    ["2026-06-04"],
    ["2026-06-05"],
  ]);
  assertEquals(pages.map((p) => [p.first_day, p.last_day]), [
    [1, 1],
    [3, 3],
    [4, 4],
    [5, 5],
  ]);
});

Deno.test("more days than pages: neighbours share evenly, no day dropped", () => {
  assertEquals(
    groupDaysEvenly([[1], [2], [3], [4], [5], [6], [7], [8], [9]], 5)
      .map((g) => g.length),
    [2, 2, 2, 2, 1],
  );
  // The arrangement with the fewest photos on its fullest page.
  assertEquals(
    groupDaysEvenly([[1, 1, 1, 1], [2], [3], [4], [5], [6]], 5)
      .map((g) => g.length),
    [1, 2, 1, 1, 1],
  );
  for (const days of [9, 30]) {
    // The film's photos, as the handler passes them (at most 60).
    const data = withFilmPhotos(memory(Array(days).fill(3)), {});
    const { pages, mosaic, photos } = buildSkySkeleton(data);
    assertEquals(pages.length, 5);
    // Every day is on a page.
    assertEquals(
      pages.flatMap((p) => p.days),
      [...new Set(data.photos.map((p) => p.day_date!))],
    );
    // Every film photo is on a page or in the mosaic.
    const shown = new Set([
      ...pages.flatMap((p) => [p.hero, ...p.extras].map((x) => x.id)),
      ...mosaic,
    ]);
    assert(photos.every((p) => shown.has(p.id)));
  }
});

Deno.test("pages to spare: a long day in parts at its 2 h break", () => {
  const data = memory([8]);
  // 08:00–11:00, then 18:00–21:00.
  data.photos.forEach((p, k) => {
    const h = k < 4 ? 8 + k : 14 + k;
    p.taken_at = `2026-06-01T${String(h).padStart(2, "0")}:00:00Z`;
  });
  const { pages } = buildSkySkeleton(data);
  assertEquals(pages.length, 2);
  assert(pages.every((p) => p.is_part && p.photos.length === 4));
  // Without a break, or with too few photos a part: one page.
  assertEquals(buildSkySkeleton(memory([8])).pages.length, 1);
  const short = memory([6]);
  short.photos[5].taken_at = "2026-06-01T20:00:00Z";
  assertEquals(buildSkySkeleton(short).pages.length, 1);
});

Deno.test("the hero: Always, then captioned, then a note's photo, then the score", () => {
  const data = memory([5]);
  const hero = (d: TripData, scores: Record<string, number> = {}) =>
    buildSkySkeleton(d, scores).pages[0].hero.id;
  assertEquals(hero(data, { d1p3: 5 }), "d1p3");
  data.notes = [note("n", "2026-06-01", "Here.", { photo_id: "d1p2" })];
  assertEquals(hero(data, { d1p3: 5 }), "d1p2");
  data.photos[1].caption = "The bridge";
  assertEquals(hero(data, { d1p3: 5 }), "d1p1");
  data.photos[4].use_in_wrap_up = true;
  assertEquals(hero(data, { d1p3: 5 }), "d1p4");
});

Deno.test("extras: up to 4, Always first, in time order; left-out never", () => {
  const data = memory([9]);
  data.photos[8].use_in_wrap_up = true;
  data.photos[0].use_in_wrap_up = false;
  const [page] = buildSkySkeleton(data).pages;
  const ids = [page.hero, ...page.extras].map((p) => p.id);
  assertEquals(page.extras.length, 4);
  assert(ids.includes("d1p8"));
  assertEquals(ids.includes("d1p0"), false);
  const times = page.extras.map((p) => p.taken_at!);
  assertEquals(times, [...times].sort());
});

Deno.test("the mosaic leaves out Always picks that have a page", () => {
  const data = memory([20]);
  data.photos[3].use_in_wrap_up = true;
  const { mosaic, pages } = buildSkySkeleton(data);
  assert(
    pages[0].hero.id === "d1p3" || pages[0].extras.some((p) => p.id === "d1p3"),
  );
  assertEquals(mosaic.includes("d1p3"), false);
  const film = skyStoryFilm(data, null);
  assertEquals(alwaysWithoutPage(data, film.content!), []);
  assertEquals(film.shown, { pages: 5, photos: 20 });
});

Deno.test("photos outside the dates are on no page", () => {
  const data = memory([4, 4]);
  data.photos.push({ ...data.photos[0], id: "late", day_date: "2026-07-01" });
  const film = skyStoryFilm(data, null);
  const ids = film.content!.pages.flatMap((p) => [
    p.hero_photo_id,
    ...p.extra_photo_ids,
  ]);
  assertEquals(ids.includes("late"), false);
});

Deno.test("no photo on any day: no Sky Story", () => {
  assertEquals(skyStoryFilm(memory([]), null).content, null);
});

// --- Words ------------------------------------------------------------

Deno.test("a note's line plays on its own photo's page, never another day's", () => {
  const data = memory([4, 4, 4], {
    notes: [
      note("own", "2026-06-01", "Rented 3 bikes and rode 12 km to Zaandam.", {
        photo_id: "d2p1",
      }),
      note("d3", "2026-06-03", "Pastéis de nata at Manteigaria, three each."),
    ],
  });
  const film = skyStoryFilm(data, null);
  const lines = film.content!.pages.map((p) =>
    p.excerpts.map((e) => e.note_id)
  );
  assertEquals(lines, [[], ["own"], ["d3"]]);
  assertEquals(film.unlisted, []);
});

Deno.test("a grouped page shows a line from each of its days", () => {
  const data = memory(Array(10).fill(2), {
    notes: [
      // Short enough for a 5-page film (75 s) to read both.
      note("a", "2026-06-01", "Tram 28 to the castle."),
      note("b", "2026-06-02", "Pastéis at Manteigaria."),
    ],
  });
  const film = skyStoryFilm(data, null);
  const first = film.content!.pages[0];
  assertEquals(first.last_day, 2);
  assertEquals(first.excerpts.map((e) => e.note_id), ["a", "b"]);
  assertEquals(
    film.slots.filter((s) => s.page === 0 && s.kind === "line").map((s) =>
      s.day
    ),
    ["2026-06-01", "2026-06-02"],
  );
});

Deno.test("a day without photos: its note plays on the nearest page, even one with its own (#468)", () => {
  const notes = [
    note("p1", "2026-06-01", "Tram 28 up to the castle."),
    note("gap", "2026-06-02", "A whole day of rain at the hotel."),
  ];
  const withOwn = skyStoryFilm(memory([4, 0, 4], { notes }), null);
  assertEquals(withOwn.unlisted, []);
  assertEquals(
    withOwn.content!.pages[0].excerpts.map((e) => e.note_id),
    ["p1", "gap"],
  );
  const without = skyStoryFilm(memory([4, 0, 4], { notes: [notes[1]] }), null);
  assertEquals(
    without.content!.pages.flatMap((p) => p.excerpts.map((e) => e.note_id)),
    ["gap"],
  );
});

Deno.test("a note written after the trip stays on its saved day", () => {
  const data = memory([4, 4], {
    notes: [note("later", "2026-06-02", "Pastéis de nata at Manteigaria.", {
      taken_at: "2026-11-20T10:00:00Z",
    })],
  });
  const film = skyStoryFilm(data, null);
  assertEquals(film.content!.pages[1].excerpts.map((e) => e.note_id), [
    "later",
  ]);
});

Deno.test("headlines name the page: its place, never the memory's name", () => {
  const data = memory([4, 4], {
    trip: { ...memory([4, 4]).trip, name: "Alfama" },
  });
  data.photos[0].place_text = "Alfama";
  data.photos[4].place_text = "Belém";
  const film = skyStoryFilm(data, null);
  assertEquals(film.content!.pages.map((p) => p.headline), [null, "Belém"]);
  // Nothing names it: null, and the app shows "Day N".
  assertEquals(
    skyStoryFilm(memory([4]), null).content!.pages[0].headline,
    null,
  );
});

Deno.test("the sky line: only without a note line, from captions and places, never filler", () => {
  const data = memory([4, 4], {
    notes: [
      note("n", "2026-06-01", "Tram 28 up to the castle, the city below us."),
    ],
  });
  data.photos[5].caption = "Sunset over the river";
  const film = skyStoryFilm(data, null);
  const [one, two] = film.content!.pages;
  assertEquals(one.sky_line, null);
  // Day 2's extras carry the caption (its hero shows its own).
  if (two.hero_photo_id !== "d2p1") {
    assertEquals(two.sky_line, "Sunset over the river");
  }
  // No caption, no place: no slot, no line.
  const bare = skyStoryFilm(memory([4]), null);
  assertEquals(bare.slots.some((s) => s.kind === "sky_line"), false);
  assertEquals(bare.content!.pages[0].sky_line, null);
});

Deno.test("the director's own words: only the user's, names as written", () => {
  const data = memory([4], {
    notes: [note("n", "2026-06-01", "Elmas birthday at the famous spas.")],
  });
  data.photos[0].place_text = "Széchenyi";
  const guard = skyWordGuard(data, new Map([["d1p0", "a thermal pool"]]));
  assertEquals(skyWordsProblem("Elmas birthday", guard), null);
  assertEquals(skyWordsProblem("The famous spas of Széchenyi", guard), null);
  assert(skyWordsProblem("Elma's birthday", guard) !== null);
  assert(skyWordsProblem("A thermal pool", guard) !== null);
  assert(skyWordsProblem("Gondolas", guard) !== null);
});

Deno.test("the director's picks: by id from the page's own list, else code's", () => {
  const data = memory([4, 4], {
    notes: [
      note(
        "a",
        "2026-06-01",
        "Tram 28 up to the castle. Pastéis de nata, warm.",
      ),
      note(
        "b",
        "2026-06-02",
        "Our last sunset at Miradouro da Senhora do Monte.",
      ),
    ],
  });
  const slots = buildSkySlots(data, buildSkySkeleton(data), "en");
  const line1 = slots.find((s) => s.slot === "p1.line1")!;
  const pick = line1.candidates.at(-1)!;
  const picked = skyStoryFilm(data, {
    "p1.line1": { ids: [`p1.line1/${pick.id}`], free_title: null },
    // Page 2's line, offered on page 1: not in its list.
    "p1.line2": {
      ids: [
        `p1.line2/${
          slots.find((s) => s.slot === "p2.line1")!.candidates[0].id
        }`,
      ],
      free_title: null,
    },
  });
  const p1 = picked.report.find((r) => r.slot === "p1.line1")!;
  assertEquals(p1.source, "director");
  assertEquals(p1.chosen[0].text, pick.text);
  assertEquals(
    picked.report.find((r) => r.slot === "p1.line2")!.source,
    "code",
  );
  // The same picks on a rebuild: the same film.
  assertEquals(
    skyStoryFilm(data, {
      "p1.line1": { ids: [`p1.line1/${pick.id}`], free_title: null },
    }).content,
    skyStoryFilm(data, {
      "p1.line1": { ids: [`p1.line1/${pick.id}`], free_title: null },
    }).content,
  );
});

// --- Length -----------------------------------------------------------

Deno.test("past 75 s the second lines go first, the last page first; never a day", () => {
  withLengthRule(() => {
    const long = (k: number) =>
      `Day ${k}: grilled sardines at the old harbour.`;
    const second = (k: number) => `A ferry to island ${k}, a green swim.`;
    const data = memory(Array(5).fill(8), {
      notes: Array.from(
        { length: 5 },
        (_, k) =>
          note(
            `n${k}`,
            addDays("2026-06-01", k),
            `${long(k + 1)} ${second(k + 1)}`,
          ),
      ),
    });
    const film = skyStoryFilm(data, null);
    assertEquals(film.content!.pages.length, 5);
    assert(film.seconds <= 75 + 1e-9 || film.trims.length > 0);
    // Past what a page's box holds, the first to go for length is the
    // last page's second line.
    const forLength = film.trims.filter((t) => !t.includes("fit the page"));
    if (forLength.length > 0) {
      assertEquals(forLength[0], "p5: a second line left out");
    }
    // Every page keeps a line.
    assert(film.content!.pages.every((p) => p.excerpts.length >= 1));
  });
});

// --- #468: the Journal is the truth -------------------------------------

Deno.test("8 days on the 5-page cap: grouped evenly, none dropped (#468)", () => {
  const data = memory([3, 3, 3, 3, 3, 3, 3, 3]);
  const pages = buildSkySkeleton(data).pages;
  assertEquals(pages.length, MAX_SKY_PAGES);
  assertEquals(pages.flatMap((p) => p.days), [
    "2026-06-01",
    "2026-06-02",
    "2026-06-03",
    "2026-06-04",
    "2026-06-05",
    "2026-06-06",
    "2026-06-07",
    "2026-06-08",
  ]);
  const sizes = pages.map((p) => p.days.length);
  assert(Math.max(...sizes) - Math.min(...sizes) <= 1, sizes.join(","));
});

Deno.test("photos backfilled onto other Journal days play on those days (#468)", () => {
  // Each day's photos were taken the day before (the camera's day), as
  // in "Arabic retreat": the Journal day wins.
  const data = memory([3, 3, 3]);
  data.photos = data.photos.map((p) => ({
    ...p,
    taken_at: `${addDays(p.day_date!, -1)}${p.taken_at!.slice(10)}`,
  }));
  data.notes = [
    note("d2", "2026-06-02", "The lighthouse at the end of the pier."),
  ];
  const film = skyStoryFilm(data, null);
  assertEquals(film.skeleton.pages.map((p) => p.days), [
    ["2026-06-01"],
    ["2026-06-02"],
    ["2026-06-03"],
  ]);
  assertEquals(film.content!.pages[1].excerpts.map((e) => e.note_id), ["d2"]);
});

Deno.test('"yesterday" never moves a note to another day (#468)', () => {
  const data = memory([3, 3]);
  data.notes = [
    note("y", "2026-06-02", "Yesterday the tram 28 up to the castle."),
  ];
  const film = skyStoryFilm(data, null);
  assertEquals(film.content!.pages[1].excerpts.map((e) => e.note_id), ["y"]);
  assertEquals(film.content!.pages[0].excerpts, []);
});

Deno.test("a backfilled note goes to the part of its day that shows what it says (#468)", () => {
  // One long day in two parts (a 2 h+ break): the beach, then the fort.
  const data = memory([10]);
  data.photos = data.photos.map((p, k) => ({
    ...p,
    taken_at: `2026-06-01T${
      String(k < 5 ? 8 + k : 16 + k).padStart(2, "0")
    }:00:00Z`,
    summary: k < 5 ? "Sandy beach with waves" : "Mud-brick fort walls",
  }));
  data.notes = [
    note("fort", "2026-06-01", "The old fort walls were enormous.", {
      taken_at: "2026-11-20T10:00:00Z",
    }),
    note("beach", "2026-06-01", "The beach water was so warm.", {
      taken_at: "2026-11-20T10:05:00Z",
    }),
  ];
  const film = skyStoryFilm(data, null);
  assertEquals(film.skeleton.pages.length, 2);
  const lineOn = (k: number) =>
    film.content!.pages[k].excerpts.map((e) => e.note_id);
  assertEquals(lineOn(0), ["beach"]);
  assertEquals(lineOn(1), ["fort"]);
});

Deno.test("backfilled: typed more than 24 h outside its Journal day (#468)", () => {
  const at = (taken_at: string, utc_offset_minutes = 0) =>
    isBackfilled(
      note("n", "2026-06-01", "x", { taken_at, utc_offset_minutes }),
    );
  assertEquals(at("2026-06-01T21:00:00Z"), false);
  // The next morning, the next evening: still about the day.
  assertEquals(at("2026-06-02T09:00:00Z"), false);
  assertEquals(at("2026-06-02T23:30:00Z"), false);
  assertEquals(at("2026-06-03T00:30:00Z"), true);
  assertEquals(at("2026-11-20T10:00:00Z"), true);
  assertEquals(at("2026-05-30T23:00:00Z"), true);
  // On the clock it was typed on: 23:30 UTC is 01:30 at +120.
  assertEquals(at("2026-06-02T23:30:00Z", 120), true);
  assertEquals(
    isBackfilled(note("l", "2026-06-01", "x", {
      legacy: true,
      taken_at: "2026-11-20T10:00:00Z",
    })),
    false,
  );
});
