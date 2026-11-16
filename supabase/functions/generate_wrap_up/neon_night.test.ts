import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildNeonNightContent,
  describeNeonNightProblems,
  MAX_NN_PHOTOS,
  type NeonNightPlan,
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
  const data = directorTripData({
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
  ]);
  assertEquals(content.chapters.map((c) => c.photos.map((p) => p.id)), [
    IDS.slice(0, 4),
    IDS.slice(4, 8),
    IDS.slice(8, 12),
  ]);
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
    photos: 12,
    notes: 2,
    ticks: 1,
    moments: 12,
  });
});

Deno.test("a photo added later joins the chapter it falls in", () => {
  const data = directorTripData();
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
