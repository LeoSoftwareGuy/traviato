// Neon Night's scenes dealt by code (#444): full cards and moments, day
// chapters never merged for length, lines on their own photos, director
// lines snapped to the note, the Note scene's fallback, the headline rule.
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildNeonNightContent,
  codeNeonNight,
  dealChapter,
  MAX_NN_HEADLINE_CHARS,
  momentFor,
  nnCheckContext,
  repairNeonNight,
} from "./neon_night.ts";
import { snapToNote } from "./excerpts.ts";
import { directorTripData, neonNightPlan } from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";
import type { NeonNightPlan } from "./neon_night.ts";

type Photo = TripData["photos"][number];

function photo(id: string, at: string, extra: Partial<Photo> = {}): Photo {
  return {
    id,
    day_date: at.slice(0, 10),
    taken_at: at,
    created_at: at,
    storage_path: `u/t/${id}.jpg`,
    caption: null,
    use_in_wrap_up: null,
    place_text: null,
    ...extra,
  } as Photo;
}

// [n] photos from [start], [stepMin] minutes apart.
function run(prefix: string, start: string, n: number, stepMin: number) {
  const t0 = Date.parse(start);
  return Array.from({ length: n }, (_, k) =>
    photo(
      `${prefix}${k}`,
      new Date(t0 + k * stepMin * 60_000).toISOString().replace(".000", ""),
    ));
}

function chapterOf(photos: Photo[]) {
  return {
    title: "x",
    note: null,
    photos,
    card: [] as string[],
    moments: [] as {
      type: "split" | "burst" | "timeline" | "peak";
      photo_ids: string[];
    }[],
    excerpts: [],
  };
}

Deno.test("momentFor: the type follows the photos' time spread", () => {
  const types = (ps: Photo[]) => momentFor(ps).type;
  assertEquals(types(run("a", "2026-10-24T22:00:00Z", 3, 0.5)), "burst");
  assertEquals(types(run("a", "2026-10-24T22:00:00Z", 4, 3)), "split");
  // Hours apart but only 3: side by side, never a half-empty timeline.
  assertEquals(types(run("a", "2026-10-24T10:00:00Z", 3, 120)), "split");
  assertEquals(types(run("a", "2026-10-24T22:00:00Z", 5, 1)), "timeline");
  // A timeline holds 6 (#448: a scene stays under ~12 s): the rest go to
  // the heart.
  assertEquals(
    momentFor(run("a", "2026-10-24T22:00:00Z", 11, 5)).photo_ids.length,
    6,
  );
});

Deno.test("dealChapter: a card of 3–6, then 1–2 moments, in time order (#448)", () => {
  for (
    const [n, card, moments] of [
      [3, 3, []],
      [4, 4, []],
      // 5–6 photos: a card and a moment, never five cards in a row.
      [5, 3, [2]],
      [6, 3, [3]],
      [7, 4, [3]],
      [9, 4, [5]],
      [10, 4, [3, 3]],
      [12, 5, [3, 4]],
      [14, 6, [3, 5]],
      [22, 6, [6, 6]],
    ] as [number, number, number[]][]
  ) {
    const c = chapterOf(run("p", "2026-10-24T20:00:00Z", n, 10));
    dealChapter(c, null);
    assertEquals(c.card.length, card, `${n} photos: card`);
    assertEquals(
      c.moments.map((m) => m.photo_ids.length).sort(),
      [...moments].sort(),
      `${n} photos: moments`,
    );
    const order = [...c.card, ...c.moments.flatMap((m) => m.photo_ids)];
    const ids = c.photos.map((p) => p.id);
    assertEquals(
      order,
      ids.filter((id) => order.includes(id)),
      `${n} photos: time order`,
    );
    assertEquals(new Set(order).size, order.length, "no photo twice");
  }
});

Deno.test("dealChapter: two moments split at the longest gap", () => {
  const c = chapterOf([
    ...run("eve", "2026-10-24T18:00:00Z", 4, 5),
    ...run("din", "2026-10-24T19:00:00Z", 3, 5),
    ...run("rave", "2026-10-25T01:00:00Z", 4, 2),
  ]);
  dealChapter(c, null);
  assertEquals(c.card, ["eve0", "eve1", "eve2", "eve3"]);
  assertEquals(c.moments[0].photo_ids, ["din0", "din1", "din2"]);
  assertEquals(c.moments[1], {
    type: "split",
    photo_ids: ["rave0", "rave1", "rave2", "rave3"],
  });
});

Deno.test("snapToNote: the note's own words, ignoring case, spacing, punctuation, ё", () => {
  const note =
    "Брюссель не меняется: отличное пиво и вкусная еда! Всё было 4,5 кг.";
  assertEquals(
    snapToNote("брюссель не меняется отличное пиво и вкусная еда", note),
    "Брюссель не меняется: отличное пиво и вкусная еда!",
  );
  assertEquals(snapToNote("все было 4.5 кг", note), "Всё было 4,5 кг.");
  // Only whole words: a part of one never matches.
  assertEquals(snapToNote("отличное пив", note), null);
  assertEquals(snapToNote("something else", note), null);
});

Deno.test("repair snaps a director line that isn't copied exactly", () => {
  const data = directorTripData();
  data.notes[0].content = "Bikes everywhere, honestly — 4,5 km of canals!";
  const plan = neonNightPlan();
  plan.chapters[0].note_id = data.notes[0].id!;
  plan.chapters[0].note_excerpt = "bikes everywhere honestly 4.5 km of canals";
  const fixed = repairNeonNight(plan, nnCheckContext(data)) as NeonNightPlan;
  assertEquals(
    fixed.chapters[0].note_excerpt,
    "Bikes everywhere, honestly — 4,5 km of canals!",
  );
});

Deno.test("a headline too long is dropped, never cut mid-phrase", () => {
  const data = directorTripData();
  const plan = neonNightPlan();
  plan.headline = "Куко Unreal всю ночь до утра ".repeat(4).trim();
  assert([...plan.headline].length > MAX_NN_HEADLINE_CHARS);
  const fixed = repairNeonNight(plan, nnCheckContext(data)) as NeonNightPlan;
  assertEquals(fixed.headline, null);
});

Deno.test("the Note scene falls back to code's best unused line", () => {
  const data = directorTripData();
  data.notes.push(
    {
      id: "n3",
      day_date: "2026-09-02",
      content: "Брюссель не меняется отличное пиво и вкусная еда.",
    } as TripData["notes"][number],
  );
  data.notes.push(
    {
      id: "n4",
      day_date: "2026-09-02",
      content: "Waffles at 2 am in the Grote Markt, 3 euros each.",
    } as TripData["notes"][number],
  );
  const plan = neonNightPlan();
  plan.note_moment = null;
  const content = buildNeonNightContent(data, plan);
  assert(content.note !== null, "a Note scene");
  assert(
    !content.chapters.some((c) =>
      c.note === content.note!.text ||
      c.moments.some((m) =>
        (m.words ?? []).some((w) => w.text === content.note!.text)
      )
    ),
    "a line no chapter plays",
  );
});

// ADE-Amsterdam's shape: three days, the last a short one (Brussels).
function threeDays(): TripData {
  const data = directorTripData();
  data.photos = [
    ...run("d1a", "2026-10-22T09:40:00Z", 3, 3),
    ...run("d1b", "2026-10-22T18:42:00Z", 4, 10),
    ...run("d1c", "2026-10-23T00:30:00Z", 5, 4),
    ...run("d2a", "2026-10-23T15:00:00Z", 4, 15),
    ...run("d2b", "2026-10-24T01:00:00Z", 6, 20),
    ...run("d3", "2026-10-24T14:00:00Z", 4, 30),
  ];
  // Times are UTC here; read them as the phone's.
  data.photos.forEach((p) => p.day_date = p.taken_at!.slice(0, 10));
  data.notes = [];
  data.trip = {
    ...data.trip,
    start_date: "2026-10-22",
    end_date: "2026-10-24",
  };
  return data;
}

Deno.test("three days: a chapter each, never merged for length; ≥ 70 % shown", () => {
  const data = threeDays();
  const plan = codeNeonNight(nnCheckContext(data), "en");
  const content = buildNeonNightContent(data, plan);
  // No chapter spans two logical days; the short last day is its own.
  assert(content.chapters.length >= 3, `${content.chapters.length}`);
  const last = content.chapters[content.chapters.length - 1];
  assertEquals(last.photos.map((p) => p.id), ["d30", "d31", "d32", "d33"]);
  assertEquals(last.card_photo_ids.length, 4);
  const shown = new Set(
    content.chapters.flatMap((c) => [
      ...c.card_photo_ids,
      ...c.moments.flatMap((m) => m.photo_ids),
    ]),
  );
  assert(
    shown.size >= 0.7 * data.photos.length,
    `${shown.size} / ${data.photos.length} shown`,
  );
  for (const c of content.chapters) {
    // 4–6 on a card; 3 when a chapter of 5–6 also has a moment (#448).
    if (c.photos.length >= 7) assert(c.card_photo_ids.length >= 4);
    if (c.photos.length >= 5) {
      assert(c.moments.length >= 1, `${c.title}: a card and a moment`);
    } else assertEquals(c.moments.length, 0);
    for (const m of c.moments) {
      if (m.type === "timeline") assert(m.photo_ids.length <= 6);
      else assert(m.photo_ids.length >= 2 && m.photo_ids.length <= 4);
    }
  }
});

Deno.test("a line plays over its own photo: it's brought into a moment", () => {
  const data = threeDays();
  // A note on a card photo of day 2.
  data.notes = [
    {
      id: "nx",
      day_date: "2026-10-23",
      content: "UFC at the bar: 3 rounds, 2 beers, one very loud Dutch guy.",
      photo_id: "d2a1",
      taken_at: "2026-10-23T15:20:00Z",
    } as TripData["notes"][number],
  ];
  const content = buildNeonNightContent(
    data,
    codeNeonNight(nnCheckContext(data), "en"),
  );
  const chapter = content.chapters.find((c) =>
    c.excerpts.some((e) => e.note_id === "nx")
  )!;
  const line = chapter.excerpts.find((e) => e.note_id === "nx")!;
  if (line.text === chapter.note) return; // the card types it
  // The Note scene plays it (#448: then no other scene does).
  if (content.note?.text === line.text) {
    assert(
      !chapter.moments.some((m) =>
        (m.words ?? []).some((w) => w.text === line.text)
      ),
    );
    return;
  }
  assert(
    chapter.moments.some((m) => m.photo_ids.includes(line.photo_id!)),
    `${line.photo_id} in a moment`,
  );
});

Deno.test("a long caption stays on its card, unzoomed; hero scores in content (#446, #448)", () => {
  const data = threeDays();
  const long =
    "UFC at the bar with the whole crew, three rounds and everybody screaming at the screen";
  data.photos.find((p) => p.id === "d2a1")!.caption = long;
  const content = buildNeonNightContent(
    data,
    codeNeonNight(nnCheckContext(data), "en"),
    { d2a0: 5 },
  );
  const chapter = content.chapters.find((c) =>
    c.photos.some((p) => p.id === "d2a1")
  )!;
  // It never pulls photos off the card (the app doesn't zoom it).
  assert(chapter.card_photo_ids.includes("d2a1"), "on the card");
  assert(chapter.card_photo_ids.length >= 4, "a full card");
  assertEquals(chapter.photos.find((p) => p.id === "d2a0")!.hero_score, 5);
  assertEquals(chapter.photos.find((p) => p.id === "d2a1")!.hero_score, null);
});

Deno.test("a full moment keeps its best photos: the heart gets the lowest-rated (#446)", () => {
  // 11 photos for one timeline of 6 (#448): the late laser shot (5)
  // stays; the lowest-rated go to the heart, wherever they are in time.
  const photos = run("p", "2026-10-25T01:00:00Z", 11, 10);
  const scores: Record<string, number> = {};
  photos.forEach((p) => scores[p.id] = 3);
  scores.p10 = 5; // the AMF laser shot, last in time
  scores.p1 = 1;
  scores.p4 = 1;
  scores.p7 = 2;
  const moment = momentFor(photos, scores);
  assertEquals(moment.type, "timeline");
  assertEquals(moment.photo_ids.length, 6);
  assert(moment.photo_ids.includes("p10"), "the laser shot stays");
  for (const low of ["p1", "p4", "p7"]) {
    assert(!moment.photo_ids.includes(low), `${low} goes to the heart`);
  }
  assertEquals(
    moment.photo_ids,
    [...moment.photo_ids].sort((a, b) =>
      Number(a.slice(1)) - Number(b.slice(1))
    ),
    "in time order",
  );
  // A caption ranks above a better shot: the user's own words stay.
  const captioned = photos.map((p) =>
    p.id === "p1" ? { ...p, caption: "Lost Anna at the bar" } : p
  );
  const withCaption = momentFor(captioned, scores).photo_ids;
  assert(withCaption.includes("p1"), "the captioned photo stays");
  assert(withCaption.includes("p10"), "the laser shot stays");
  assert(
    !withCaption.includes("p4") && !withCaption.includes("p7"),
    "the lowest-rated uncaptioned ones go",
  );
  // Without scores: an even spread, as before.
  assertEquals(momentFor(photos).photo_ids.length, 6);
});
