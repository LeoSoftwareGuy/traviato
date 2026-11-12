import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildGoldenVowsContent,
  chapterLayout,
  describeGoldenVowsProblems,
  type GoldenVowsPlan,
  gvCheckContext,
  isExcerptOf,
  MAX_GV_HEART,
  repairGoldenVows,
} from "./golden_vows.ts";
import {
  DIRECTOR_PHOTO_IDS as IDS,
  directorTripData,
  goldenVowsPlan,
} from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";

function problemsOf(
  edit: (plan: GoldenVowsPlan) => void,
  data: TripData = directorTripData(),
): string[] {
  const plan = goldenVowsPlan();
  edit(plan);
  return describeGoldenVowsProblems(plan, gvCheckContext(data));
}

Deno.test("a valid section has no problems", () => {
  assertEquals(problemsOf(() => {}), []);
  // A null carousel is fine too.
  assertEquals(problemsOf((p) => p.carousel = null), []);
});

Deno.test("each broken rule is named", () => {
  const cases: [string, (p: GoldenVowsPlan) => void][] = [
    [
      "golden_vows.occasion",
      (p) => (p as { occasion: string }).occasion = "party",
    ],
    ["golden_vows.heroes: 1", (p) => p.heroes = p.heroes.slice(0, 1)],
    [
      'golden_vows.heroes[0].photo_id: "invented"',
      (p) => p.heroes[0].photo_id = "invented",
    ],
    [
      'golden_vows.chapters[0].photo_ids[0]: "p01" is used twice',
      (p) => p.chapters[0].photo_ids[0] = IDS[1],
    ],
    [
      "golden_vows.chapters[1].photo_ids: 2",
      (p) => p.chapters[1].photo_ids.pop(),
    ],
    [
      'golden_vows.chapters[1].photo_ids[0]: "p00" is out of chronological order',
      (p) => [p.chapters[0], p.chapters[1]] = [p.chapters[1], p.chapters[0]],
    ],
    [
      "golden_vows.heroes[1].label: 26 characters",
      (p) => p.heroes[1].label = "The very first dance of us",
    ],
    [
      'golden_vows.end_line: banned phrase "unforgettable"',
      (p) => p.end_line = "An unforgettable day",
    ],
    [
      "golden_vows.heroes[0].note_id: the note is not from the photo's day",
      (p) => p.heroes[0].photo_id = IDS[11],
    ],
    [
      "golden_vows.heroes[0].note_excerpt: must be copied exactly",
      (p) => p.heroes[0].note_excerpt = "Bicycles everywhere",
    ],
    [
      "golden_vows.heroes[1].note_excerpt: only with a note_id",
      (p) => p.heroes[1].note_excerpt = "Bikes",
    ],
    [
      "golden_vows.chapters: 5",
      (p) => {
        p.chapters = Array.from({ length: 5 }, () => p.chapters[0]);
      },
    ],
  ];
  for (const [expected, edit] of cases) {
    const problems = problemsOf(edit);
    assert(
      problems.some((line) => line.startsWith(expected)),
      `${expected} — got ${JSON.stringify(problems)}`,
    );
  }
});

Deno.test("a left-out photo can't be used", () => {
  const data = directorTripData();
  data.photos[1].use_in_wrap_up = false;
  assert(
    problemsOf(() => {}, data).some((p) =>
      p === 'golden_vows.heroes[0].photo_id: "p01" was left out by the user'
    ),
  );
});

Deno.test("an excerpt is the note's words, spacing aside", () => {
  assert(isExcerptOf("Bikes  everywhere", "Bikes everywhere."));
  assert(isExcerptOf("everywhere.", "Bikes\neverywhere."));
  assertEquals(isExcerptOf("bikes everywhere", "Bikes everywhere."), false);
  assertEquals(isExcerptOf("  ", "Bikes everywhere."), false);
});

Deno.test("repair: quotes and ellipses go, order is restored, bad notes drop", () => {
  const context = gvCheckContext(directorTripData());
  const plan = goldenVowsPlan() as unknown as Record<string, unknown>;
  const p = plan as unknown as GoldenVowsPlan;
  p.occasion_line = '"Our Wedding Day"';
  p.heroes[0].note_excerpt = "“…Bikes everywhere”";
  p.heroes[1].note_id = "n2";
  p.heroes[1].note_excerpt = "Rain, then waffles";
  p.chapters[0].photo_ids = [IDS[3], IDS[0], IDS[2]];
  p.chapters = [p.chapters[2], p.chapters[0], p.chapters[1]];
  p.heroes = [...p.heroes, ...Array(6).fill(p.heroes[1])];
  delete plan.carousel;

  const repaired = repairGoldenVows(plan, context) as GoldenVowsPlan;

  assertEquals(repaired.occasion_line, "Our Wedding Day");
  assertEquals(repaired.heroes.length, 6);
  assertEquals(repaired.heroes[0].note_excerpt, "Bikes everywhere");
  assertEquals(repaired.heroes[1].note_id, null);
  assertEquals(repaired.heroes[1].note_excerpt, null);
  assertEquals(repaired.chapters.map((c) => c.title), [
    "Getting ready",
    "The ceremony",
    "Just married",
  ]);
  assertEquals(repaired.chapters[0].photo_ids, [IDS[0], IDS[2], IDS[3]]);
  assertEquals(repaired.carousel, null);
  // The original is untouched.
  assertEquals(p.occasion_line, '"Our Wedding Day"');
});

Deno.test("chapter layouts follow the photos' shapes", () => {
  const shapes = (s: string[]) =>
    Object.fromEntries(s.map((o, i) => [`x${i}`, o]));
  const ids = ["x0", "x1", "x2"];
  assertEquals(
    chapterLayout(ids, shapes(["landscape", "portrait", "portrait"]), 0),
    "A",
  );
  assertEquals(
    chapterLayout(ids, shapes(["portrait", "square", "landscape"]), 0),
    "C",
  );
  assertEquals(
    chapterLayout(ids, shapes(["portrait", "portrait", "portrait"]), 0),
    "B",
  );
  // Unknown shapes: A, B, C in turn.
  assertEquals(
    [0, 1, 2, 3].map((i) => chapterLayout(ids, {}, i)),
    ["A", "B", "C", "A"],
  );
});

Deno.test("content: the memory's facts, the user's words, code-picked photos", () => {
  const data = directorTripData({
    checklist: [
      { title: "Rings", suggestion_code: null, is_checked: true },
      { title: "Passport", suggestion_code: "passport", is_checked: true },
      { title: "Umbrella", suggestion_code: null, is_checked: false },
    ],
  });
  data.photos[9].caption = "  Barefoot by the last song ";
  const content = buildGoldenVowsContent(data, goldenVowsPlan(), {
    p00: "landscape",
    p02: "portrait",
    p03: "portrait",
  });

  assertEquals(content.names, "Amsterdam");
  assertEquals(content.place, "Netherlands");
  assertEquals(content.day_count, 3);
  assertEquals(content.start_date, "2026-09-01");
  assertEquals(content.occasion_line, "Our Wedding Day");
  assertEquals(content.heroes, [
    {
      photo_id: "p01",
      label: "The vows",
      taken_at: "2026-09-01T11:00:00Z",
      note: "Bikes everywhere",
    },
    {
      // A caption is the photo's note, whatever the director chose.
      photo_id: "p09",
      label: "First dance",
      taken_at: "2026-09-03T11:00:00Z",
      note: "Barefoot by the last song",
    },
  ]);
  assertEquals(content.chapters.map((c) => c.layout), ["A", "B", "C"]);
  assertEquals(content.packing, {
    source: "checklist",
    items: [
      { text: "Rings", suggestion_code: null },
      { text: "Passport", suggestion_code: "passport" },
    ],
    checked: 2,
    total: 3,
  });
  // 3 photos left: no carousel page.
  assertEquals(content.carousel, null);
  assertEquals(content.heart_photo_ids, IDS);
  assertEquals(content.moment_count, 12);
});

Deno.test("packing: checked items first, else planned quests, else none", () => {
  const plan = goldenVowsPlan();
  const quests = directorTripData({
    checklist: [{ title: "Rings", suggestion_code: null, is_checked: false }],
    quests: Array.from({ length: 7 }, (_, i) => ({
      title: `Quest ${i}`,
      day_date: "2026-09-01",
      completed_at: null,
    })),
  });
  const fromQuests = buildGoldenVowsContent(quests, plan).packing!;
  assertEquals(fromQuests.source, "quests");
  assertEquals(fromQuests.items.map((i) => i.text), [
    "Quest 0",
    "Quest 1",
    "Quest 2",
    "Quest 3",
    "Quest 4",
  ]);
  assertEquals(fromQuests.checked, null);
  assertEquals(fromQuests.total, null);

  assertEquals(buildGoldenVowsContent(directorTripData(), plan).packing, null);
});

Deno.test("the carousel: photos used nowhere else, Always first, 6 or more", () => {
  const data = directorTripData();
  data.photos[11].use_in_wrap_up = true;
  const plan = goldenVowsPlan();
  plan.chapters = plan.chapters.slice(0, 1);
  const content = buildGoldenVowsContent(data, plan);
  // 2 heroes + 3 chapter photos used: 7 left, all on the carousel.
  assertEquals(content.carousel, {
    title: "And the night went on",
    line: "Chapter four",
    photo_ids: ["p04", "p05", "p06", "p07", "p08", "p10", "p11"],
  });
  plan.carousel = null;
  assertEquals(buildGoldenVowsContent(data, plan).carousel, null);
});

Deno.test("the heart: every photo shown, spread to 200; left-out ones never", () => {
  const data = directorTripData();
  data.photos = Array.from({ length: 230 }, (_, i) => ({
    ...data.photos[i % 12],
    id: `h${String(i).padStart(3, "0")}`,
    taken_at: `2026-09-01T${String(Math.floor(i / 60)).padStart(2, "0")}:${
      String(i % 60).padStart(2, "0")
    }:00Z`,
    day_date: "2026-09-01",
  }));
  data.photos[5].use_in_wrap_up = false;
  const plan = goldenVowsPlan(data.photos.map((p) => p.id).slice(12));
  const content = buildGoldenVowsContent(data, plan);
  assertEquals(content.heart_photo_ids.length, MAX_GV_HEART);
  assertEquals(content.heart_photo_ids.includes("h005"), false);
  assertEquals(content.moment_count, 229);
});
