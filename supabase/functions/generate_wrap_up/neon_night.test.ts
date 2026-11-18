import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildNeonNightContent,
  describeNeonNightProblems,
  MAX_NN_PHOTOS,
  type NeonNightPlan,
  neonNightToolProperty,
  nnCheckContext,
  repairNeonNight,
} from "./neon_night.ts";
import {
  DIRECTOR_PHOTO_IDS as IDS,
  directorTripData,
  neonNightPlan,
} from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";

function problemsOf(
  edit: (plan: NeonNightPlan) => void,
  data: TripData = directorTripData(),
): string[] {
  const plan = neonNightPlan();
  edit(plan);
  return describeNeonNightProblems(plan, nnCheckContext(data));
}

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

Deno.test("a valid section has no problems", () => {
  assertEquals(problemsOf(() => {}), []);
  assertEquals(
    problemsOf((p) => {
      p.note_moment = null;
      p.headline = null;
    }),
    [],
  );
});

Deno.test("each broken rule is named", () => {
  const cases: [string, (p: NeonNightPlan) => void][] = [
    ["neon_night.chapters: 0", (p) => p.chapters = []],
    [
      "neon_night.chapters[0].first_photo_id: must be the first photo",
      (p) => p.chapters[0].first_photo_id = IDS[1],
    ],
    [
      "neon_night.chapters[2].first_photo_id: must come after",
      (p) => p.chapters[2].first_photo_id = IDS[3],
    ],
    [
      'neon_night.chapters[1].first_photo_id: "invented"',
      (p) => p.chapters[1].first_photo_id = "invented",
    ],
    [
      "neon_night.chapters[0].title: 23 characters",
      (p) => p.chapters[0].title = "The doors open at eight",
    ],
    [
      "neon_night.chapters[1].moments: 0",
      (p) => p.chapters[1].moments = [],
    ],
    [
      "neon_night.chapters[2].moments[0].photo_ids: 2, a peak takes 3–5",
      (p) => p.chapters[2].moments[0].photo_ids.pop(),
    ],
    [
      'neon_night.chapters[1].moments[0].photo_ids[3]: "p08" is not from this chapter',
      (p) => p.chapters[1].moments[0].photo_ids[3] = IDS[8],
    ],
    [
      'neon_night.chapters[0].moments[1].photo_ids[0]: "p01" is used twice',
      (p) => p.chapters[0].moments[1].photo_ids[0] = IDS[1],
    ],
    [
      'neon_night.chapters[1].moments[0].photo_ids[1]: "p04" is out of chronological order',
      (p) =>
        p.chapters[1].moments[0].photo_ids = [IDS[5], IDS[4], IDS[6], IDS[7]],
    ],
    [
      "neon_night.chapters[0].moments[0].type",
      (p) => (p.chapters[0].moments[0] as { type: string }).type = "slideshow",
    ],
    [
      "neon_night.chapters[0].note_excerpt: must be copied exactly",
      (p) => p.chapters[0].note_excerpt = "Bicycles everywhere",
    ],
    [
      "neon_night.chapters[1].note_excerpt: only with a note_id",
      (p) => p.chapters[1].note_excerpt = "Bikes",
    ],
    [
      "neon_night.note_moment.excerpt.note_id: not a note id",
      (p) => p.note_moment!.note_id = "n9",
    ],
    [
      'neon_night.note_moment.photo_id: "invented"',
      (p) => p.note_moment!.photo_id = "invented",
    ],
    [
      "neon_night.headline: 25 characters",
      (p) => p.headline = "The best night of my life",
    ],
    [
      'neon_night.headline: banned phrase "epic"',
      (p) => p.headline = "Epic night",
    ],
  ];
  for (const [expected, edit] of cases) {
    const problems = problemsOf(edit);
    assert(
      problems.some((p) => p.startsWith(expected)),
      `expected "${expected}" in ${JSON.stringify(problems)}`,
    );
  }
});

Deno.test("a photo the user left out may not be used", () => {
  const data = directorTripData();
  data.photos[5].use_in_wrap_up = false;
  const problems = problemsOf(() => {}, data);
  assert(problems.some((p) => p.includes('"p05" was left out by the user')));
});

Deno.test("repair fixes what code can put right", () => {
  const plan = neonNightPlan();
  // Chapters out of order, the first starting late, quotes, a reworded
  // card excerpt, moment photos out of order, a reworded note moment.
  plan.chapters.reverse();
  plan.chapters[2].first_photo_id = IDS[1];
  plan.chapters[0].title = '"Peak time"';
  plan.chapters[2].note_excerpt = "Bicycles everywhere";
  plan.chapters[1].moments[0].photo_ids.reverse();
  plan.note_moment!.excerpt = "Rain then waffles";
  plan.headline = '"Best night ever"';

  const context = nnCheckContext(directorTripData());
  const repaired = repairNeonNight(plan, context) as NeonNightPlan;

  assertEquals(describeNeonNightProblems(repaired, context), []);
  assertEquals(repaired.chapters.map((c) => c.title), [
    "Doors open",
    "After midnight",
    "Peak time",
  ]);
  assertEquals(repaired.chapters[0].first_photo_id, IDS[0]);
  assertEquals(repaired.chapters[0].note_id, null);
  assertEquals(repaired.chapters[1].moments[0].photo_ids, IDS.slice(4, 8));
  assertEquals(repaired.note_moment, null);
  assertEquals(repaired.headline, "Best night ever");
});

Deno.test("content.neon_night: chapters by range, the user's own words, totals", () => {
  const data = fullNight({
    quests: [
      {
        title: "Pre-drinks",
        day_date: "2026-09-01",
        time: "22:00:00",
        completed_at: "2026-09-01T22:30:00Z",
      },
      {
        title: "No time",
        day_date: "2026-09-01",
        time: null,
        completed_at: null,
      },
      {
        title: "Afterparty",
        day_date: "2026-09-02",
        time: "03:00:00",
        completed_at: null,
      },
      {
        title: "Breakfast",
        day_date: "2026-09-03",
        time: "09:00:00",
        completed_at: null,
      },
    ],
    username: "Leo Engineer",
  });
  data.notes[1].created_at = "2026-09-03T23:31:00Z";
  const content = buildNeonNightContent(data, neonNightPlan());

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
  assertEquals(content.chapters[0].note, "Bikes everywhere");
  assertEquals(content.chapters[1].note, null);
  assertEquals(content.chapters[0].moments[0].place, "Centraal");
  // Only a split is labelled with a place.
  assertEquals(content.chapters[0].moments[1].place, null);
  assertEquals(content.note, {
    text: "Rain, then stroopwafels.",
    number: 2,
    written_at: "2026-09-03T23:31:00Z",
    photo_id: IDS[10],
  });
  assertEquals(content.headline, "Best night ever");
  assertEquals(content.first_name, "Leo");
  assertEquals(content.totals, {
    photos: 27,
    notes: 2,
    ticks: 1,
    moments: 27,
  });
});

Deno.test("a photo added later joins the chapter it falls in", () => {
  const data = fullNight();
  data.photos.push({
    ...data.photos[5],
    id: "late",
    taken_at: "2026-09-02T12:30:00Z",
  });
  const plan = neonNightPlan();
  assertEquals(describeNeonNightProblems(plan, nnCheckContext(data)), []);
  const content = buildNeonNightContent(data, plan);
  assert(content.chapters[1].photos.some((p) => p.id === "late"));
});

Deno.test("over 200 photos: an even spread that keeps the named ones", () => {
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
  const content = buildNeonNightContent(data, neonNightPlan());
  const shown = content.chapters.flatMap((c) => c.photos.map((p) => p.id));
  assert(shown.length <= MAX_NN_PHOTOS + 6, `${shown.length}`);
  for (const id of [IDS[0], IDS[4], IDS[8], IDS[9], IDS[10]]) {
    assert(shown.includes(id), id);
  }
  assertEquals(content.totals.photos, 312);
});

// --- Always picks get their own moment (#378) -----------------------------

Deno.test("an Always pick must be in a moment (or the Note scene's photo)", () => {
  const data = directorTripData();
  data.photos[11].use_in_wrap_up = true; // in no moment
  assertEquals(problemsOf(() => {}, data), [
    `neon_night: photo "p11" is marked Always but is in no moment — put it in a moment of its chapter`,
  ]);

  // As the Note scene's background it's shown.
  assertEquals(
    problemsOf((p) => p.note_moment!.photo_id = "p11", data),
    [],
  );

  // In a moment: fine.
  const inMoment = directorTripData();
  inMoment.photos[3].use_in_wrap_up = true;
  assertEquals(problemsOf(() => {}, inMoment), []);
});

Deno.test("an Always pick whose analysis failed isn't required", () => {
  const data = directorTripData();
  data.photos[11].use_in_wrap_up = true;
  assertEquals(
    describeNeonNightProblems(
      neonNightPlan(),
      nnCheckContext(data, new Set(["p11"])),
    ),
    [],
  );
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
  const content = buildNeonNightContent(
    data,
    neonNightPlan(data.photos.map((p) => p.id)),
  );
  assertEquals(
    content.heart_photo_ids.filter((id) => id === "h01" || id === "h03"),
    [],
  );
  assertEquals(content.heart_photo_ids.length, 38);
  // Every photo still plays in its chapter.
  assertEquals(content.chapters.flatMap((c) => c.photos).length, 40);
});

// --- Repairs instead of discarding (#382) ---------------------------------

function repaired(plan: unknown, data: TripData = directorTripData()) {
  const context = nnCheckContext(data);
  const fixed = repairNeonNight(plan, context) as NeonNightPlan;
  return { fixed, problems: describeNeonNightProblems(fixed, context) };
}

Deno.test("a moment's photos from another chapter are dropped, its type made to fit", () => {
  // ADE-Amsterdam 2026's faults: two photos from the next chapter in a
  // moment, and a 2-photo peak.
  const plan = neonNightPlan();
  plan.chapters[1].moments[0].photo_ids = ["p04", "p05", "p08", "p09"];
  plan.chapters[2].moments[0].photo_ids = ["p08", "p09"];
  const { fixed, problems } = repaired(plan);
  assertEquals(problems, []);
  assertEquals(fixed.chapters[1].moments[0].photo_ids, ["p04", "p05"]);
  assertEquals(fixed.chapters[2].moments[0], {
    type: "timeline",
    photo_ids: ["p08", "p09"],
  });
});

Deno.test("a moment left under 2 photos goes; a chapter left without one gets a timeline", () => {
  const plan = neonNightPlan();
  plan.chapters[2].moments = [{ type: "peak", photo_ids: ["p01", "p08"] }];
  const { fixed, problems } = repaired(plan);
  assertEquals(problems, []);
  // p01 isn't chapter 3's: one photo left → dropped → a timeline of
  // chapter 3's photos instead (p10 is the Note scene's, still usable).
  assertEquals(fixed.chapters[2].moments.length, 1);
  assertEquals(fixed.chapters[2].moments[0].type, "timeline");
  assert(
    fixed.chapters[2].moments[0].photo_ids.every((id) =>
      ["p08", "p09", "p10", "p11"].includes(id)
    ),
  );
});

Deno.test("Always picks without a moment join one of their chapter", () => {
  const data = directorTripData();
  data.photos[11].use_in_wrap_up = true; // chapter 3, in no moment
  const { fixed, problems } = repaired(neonNightPlan(), data);
  assertEquals(problems, []);
  // The 3-photo peak has room for a fourth.
  assertEquals(fixed.chapters[2].moments[0].photo_ids, [
    "p08",
    "p09",
    "p10",
    "p11",
  ]);
});

Deno.test("a full moment grows into a timeline to take an Always pick", () => {
  const data = directorTripData();
  // Chapter 1 has one full split (3 of 3); its Always pick p03 makes it a
  // 4-photo timeline.
  const plan = neonNightPlan();
  plan.chapters[0].moments = [{
    type: "split",
    photo_ids: ["p00", "p01", "p02"],
  }];
  data.photos[3].use_in_wrap_up = true;
  const { fixed, problems } = repaired(plan, data);
  assertEquals(problems, []);
  assertEquals(fixed.chapters[0].moments, [{
    type: "timeline",
    photo_ids: ["p00", "p01", "p02", "p03"],
  }]);
});

// --- No peak, fuller timelines (#386) --------------------------------------

Deno.test("the director can't plan a peak any more", () => {
  const json = JSON.stringify(neonNightToolProperty);
  assert(!json.includes('"peak"'));
  assert(json.includes('"timeline"'));
});

Deno.test("a peak in a plan made before plays as photos side by side", () => {
  // neonNightPlan()'s chapter 3 is a 3-photo peak.
  const content = buildNeonNightContent(fullNight(), neonNightPlan());
  assertEquals(content.chapters[2].moments, [{
    type: "split",
    photo_ids: ["p08", "p09", "p10"],
    place: null,
  }]);
  assert(
    content.chapters.every((c) => c.moments.every((m) => m.type !== "peak")),
  );
});

Deno.test("a timeline is filled with what the card leaves, in time order", () => {
  const plan = neonNightPlan();
  plan.chapters[1].moments = [{ type: "timeline", photo_ids: ["p07", "p04"] }];
  const chapter = buildNeonNightContent(fullNight(), plan).chapters[1];
  // 9 photos: the card takes 4 unused ones, the timeline the next 3.
  assertEquals(chapter.card_photo_ids.length, 4);
  const ids = chapter.moments[0].photo_ids;
  assertEquals(chapter.moments[0].type, "timeline");
  assertEquals(ids.length, 5);
  assertEquals(ids.slice(0, 1), ["p04"]);
  assert(ids.includes("p07"));
  // Never a card photo, never another chapter's.
  assert(ids.every((id) => !chapter.card_photo_ids.includes(id)));
  assert(ids.every((id) => chapter.photos.some((p) => p.id === id)));
});

Deno.test("the fill takes Always picks first and stops at 6", () => {
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
  const plan = neonNightPlan();
  plan.chapters[1].moments = [{ type: "timeline", photo_ids: ["p04", "p05"] }];
  const chapter = buildNeonNightContent(data, plan).chapters[1];
  const ids = chapter.moments[0].photo_ids;
  assertEquals(ids.length, 6);
  assert(ids.includes("x8") && ids.includes("x9"));
  assertEquals(ids.slice(0, 2), ["p04", "p05"]);
});

// --- Fewer, fuller scenes (#390) --------------------------------------------

Deno.test("small chapters merge into fuller ones", () => {
  // 3 chapters of 4 photos → one of 12: the first one's title and note.
  const content = buildNeonNightContent(directorTripData(), neonNightPlan());
  assertEquals(content.chapters.length, 1);
  const [chapter] = content.chapters;
  assertEquals(chapter.title, "Doors open");
  assertEquals(chapter.note, "Bikes everywhere");
  assertEquals(chapter.photos.length, 12);
});

Deno.test("Amsterdam's shape: 5 chapters of 3–7 photos become fuller ones", () => {
  const data = directorTripData();
  const sizes = [7, 5, 7, 3, 6];
  data.photos = [];
  let n = 0;
  sizes.forEach((size, c) => {
    for (let k = 0; k < size; k++, n++) {
      data.photos.push({
        ...directorTripData().photos[0],
        id: `a${String(n).padStart(2, "0")}`,
        day_date: "2026-09-01",
        taken_at: `2026-09-01T${String(8 + c * 3).padStart(2, "0")}:${
          String(k * 5).padStart(2, "0")
        }:00Z`,
        caption: k === 0 ? `Caption ${c}` : null,
        place_text: null,
      });
    }
  });
  const ids = data.photos.map((p) => p.id);
  let at = 0;
  const plan: NeonNightPlan = {
    chapters: sizes.map((size, c) => {
      const own = ids.slice(at, at + size);
      at += size;
      return {
        title: `Chapter ${c + 1}`,
        first_photo_id: own[0],
        note_id: null,
        note_excerpt: null,
        // Every photo in a moment, as Amsterdam's director did.
        moments: size > 4
          ? [
            { type: "split" as const, photo_ids: own.slice(0, 3) },
            { type: "timeline" as const, photo_ids: own.slice(3) },
          ]
          : [{ type: "timeline" as const, photo_ids: own }],
      };
    }),
    note_moment: null,
    headline: null,
  };
  assertEquals(describeNeonNightProblems(plan, nnCheckContext(data)), []);

  const content = buildNeonNightContent(data, plan);

  assert(content.chapters.length <= 3, `${content.chapters.length}`);
  for (const chapter of content.chapters) {
    assert(chapter.photos.length >= 8);
    assert(chapter.card_photo_ids.length >= 1);
    const inMoments = chapter.moments.flatMap((m) => m.photo_ids);
    // No photo on the card and in a moment, none twice.
    assert(chapter.card_photo_ids.every((id) => !inMoments.includes(id)));
    assertEquals(new Set(inMoments).size, inMoments.length);
    for (const m of chapter.moments) {
      assert(m.type !== "timeline" || m.photo_ids.length >= 5, m.type);
      assert(m.type !== "peak");
    }
  }
  // Fewer scenes: at most 2 moments a chapter.
  assert(content.chapters.every((c) => c.moments.length <= 2));
});

Deno.test("the card takes captioned photos first", () => {
  const data = fullNight();
  data.photos.find((p) => p.id === "d1x3")!.caption = "Lost the keys";
  const plan = neonNightPlan();
  const chapter = buildNeonNightContent(data, plan).chapters[0];
  // Chapter 1's free photos: d1x0–d1x4; the captioned one is on the card.
  assert(chapter.card_photo_ids.includes("d1x3"));
});

Deno.test("a timeline under 5 photos plays as a split or burst", () => {
  const plan = neonNightPlan();
  // The card takes chapter 2's 5 unused photos' first 4; one is left.
  plan.chapters[1].moments = [{ type: "timeline", photo_ids: ["p04", "p05"] }];
  const data = fullNight();
  // Leave chapter 2 nothing to fill with: its extras marked left out.
  for (const p of data.photos) {
    if (p.id.startsWith("d2x")) p.use_in_wrap_up = false;
  }
  const chapter = buildNeonNightContent(data, plan).chapters[1];
  assertEquals(chapter.moments.map((m) => m.type), ["split"]);
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
    neonNightPlan(),
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
    neonNightPlan(),
  );
  assertEquals(three.plan.length, 3);
});

Deno.test("chapter photos carry the user's caption, trimmed (#387)", () => {
  const data = fullNight();
  data.photos.find((p) => p.id === "p01")!.caption = "  Lost the keys ";
  data.photos.find((p) => p.id === "p02")!.caption = "   ";
  const photos = buildNeonNightContent(data, neonNightPlan()).chapters[0]
    .photos;
  const caption = (id: string) => photos.find((p) => p.id === id)!.caption;
  assertEquals(caption("p01"), "Lost the keys");
  assertEquals(caption("p02"), null);
  assertEquals(caption("p03"), null);
});
