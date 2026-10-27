import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  assembleWrapUpContent,
  formatDateRange,
  invitationLine1,
  noteExcerpts,
  pickMomentPhotos,
  selectCut,
  sortPhotosChronologically,
  splitKeepsakeTitle,
  spreadEvenly,
} from "./assemble.ts";
import { validateWrapUpContent } from "./content.ts";
import type { WrapUpContent } from "./content.ts";
import { validAiFields, validTripData } from "./test_fixtures.ts";
import type { TripData } from "./gather.ts";

function tripData(overrides: Partial<TripData> = {}): TripData {
  return { ...validTripData, ...overrides };
}

Deno.test("assembleWrapUpContent produces the expected shape for the happy-path fixture", () => {
  const content = assembleWrapUpContent(validTripData, validAiFields);
  assertEquals(validateWrapUpContent(content), true);
  assertEquals(content.moments.length, 8);
  // Bonus p1 + p3, journal moments spread over p2, p4..p10.
  assertEquals(content.moments.map((m) => m.photo_id), [
    "p1",
    "p2",
    "p3",
    "p5",
    "p6",
    "p7",
    "p9",
    "p10",
  ]);
  assertEquals(content.flurry_leftovers.photos.map((p) => p.photo_id), [
    "p4",
    "p8",
  ]);
});

Deno.test("badge slots degrade to plain journal photos with fewer than 3 completed bonus tasks", () => {
  const content = assembleWrapUpContent(validTripData, validAiFields);
  const badged = content.moments.filter((m) => m.badge !== null);
  assertEquals(badged.length, 2); // only 2 completions in the fixture
  assertEquals(content.moments.every((m) => m.badge !== undefined), true);
  // never an empty-string badge — either a real badge or null
  assertEquals(content.moments.some((m) => m.badge === ""), false);
});

Deno.test("moments array is shorter than 8 with fewer than 8 total photos", () => {
  const data = tripData({
    photos: validTripData.photos.slice(0, 3),
    completedBonusTasks: [],
  });
  const content = assembleWrapUpContent(data, validAiFields);
  assertEquals(validateWrapUpContent(content), true);
  assertEquals(content.moments.length, 3);
  assertEquals(content.flurry_leftovers.photos.length, 0);
});

Deno.test("zero photos produces empty moments and leftovers without crashing", () => {
  const data = tripData({ photos: [], completedBonusTasks: [] });
  const content = assembleWrapUpContent(data, validAiFields);
  assertEquals(validateWrapUpContent(content), true);
  assertEquals(content.moments, []);
  assertEquals(content.flurry_leftovers.photos, []);
  assertEquals(content.footnote.photo_count, 0);
});

Deno.test("a photo with no caption produces a null note, never a fabricated one", () => {
  const content = assembleWrapUpContent(validTripData, validAiFields);
  const uncaptioned = content.moments.find((m) => m.photo_id === "p2");
  assertEquals(uncaptioned?.note, null);
});

Deno.test("zero achievements earned produces a null unlock", () => {
  const data = tripData({ latestAchievement: null });
  const content = assembleWrapUpContent(data, validAiFields);
  assertEquals(validateWrapUpContent(content), true);
  assertEquals(content.unlock, null);
});

Deno.test("flurry label is suppressed under the 10-leftover threshold", () => {
  const content = assembleWrapUpContent(validTripData, validAiFields); // 2 leftovers
  assertEquals(content.flurry_leftovers.total_remaining_label, null);
});

// --- #151: photo-count-aware cuts ---------------------------------------

function photos(
  count: number,
  prefix = "c",
  perDay = 4,
): TripData["photos"] {
  return Array.from({ length: count }, (_, i) => ({
    id: `${prefix}${i}`,
    day_date: `2026-06-${String(1 + Math.floor(i / perDay)).padStart(2, "0")}`,
    taken_at: null,
    created_at: `2026-06-01T00:00:00Z`,
    storage_path: `u/t/${prefix}${i}.jpg`,
    caption: null,
    use_in_wrap_up: null,
  }));
}

// All on one day by default, so the cut tests below measure the photo
// budget alone — same-day collage limits (#298) have their own tests.
function planFor(count: number, withBonus = false, perDay = count || 1) {
  const list = photos(count, "c", perDay);
  const completedBonusTasks = withBonus
    ? list.slice(0, 3).map((p, i) => ({
      completed_at: `2026-06-01T0${i}:00:00Z`,
      photo_id: p.id,
      title: `Dare ${i}`,
      points: 1,
    }))
    : [];
  return assembleWrapUpContent(
    tripData({ photos: list, completedBonusTasks }),
    validAiFields,
  );
}

function layouts(content: WrapUpContent) {
  return content.moments.map((m) => m.layout);
}

function flurrySizes(content: WrapUpContent) {
  return [
    content.flurry_leftovers.flurry1.length,
    content.flurry_leftovers.flurry2.length,
  ];
}

Deno.test("selectCut: highlight up to 11, compact 12-23, full from 24", () => {
  assertEquals(selectCut(0), "highlight");
  assertEquals(selectCut(5), "highlight");
  assertEquals(selectCut(11), "highlight");
  assertEquals(selectCut(12), "compact");
  assertEquals(selectCut(23), "compact");
  assertEquals(selectCut(24), "full");
});

Deno.test("5 photos (gate floor): highlight, 5 card-flip moments, no Flurry", () => {
  const content = planFor(5);
  assertEquals(validateWrapUpContent(content), true);
  assertEquals(content.cut, "highlight");
  assertEquals(content.moments.length, 5);
  assertEquals(layouts(content), [null, null, null, null, null]);
  assertEquals(flurrySizes(content), [0, 0]);
});

Deno.test("10 photos: still highlight, 8 card flips, no Flurry", () => {
  const content = planFor(10);
  assertEquals(content.cut, "highlight");
  assertEquals(content.moments.length, 8);
  assertEquals(content.moments.every((m) => m.layout === null), true);
  assertEquals(
    content.moments.every((m) => m.collage_extras.length === 0),
    true,
  );
  assertEquals(flurrySizes(content), [0, 0]);
  assertEquals(content.flurry_leftovers.photos.length, 2);
});

Deno.test("12 photos: compact, collages scale down to what's available", () => {
  const content = planFor(12);
  assertEquals(content.cut, "compact");
  assertEquals(layouts(content), [
    null,
    "stack3",
    null,
    null,
    "stack3",
    null,
    null,
    null,
  ]);
  assertEquals(flurrySizes(content), [0, 0]);
});

Deno.test("15 photos: compact, torn4/stack3 only, no Flurry under 6", () => {
  const content = planFor(15);
  assertEquals(content.cut, "compact");
  assertEquals(layouts(content), [
    null,
    "stack3",
    null,
    null,
    "torn4",
    null,
    "stack3",
    null,
  ]);
  assertEquals(flurrySizes(content), [0, 0]);
});

Deno.test("19 photos: compact holds 6 back for its one Flurry", () => {
  const content = planFor(19);
  assertEquals(layouts(content), [
    null,
    "stack3",
    null,
    null,
    "torn4",
    null,
    null,
    null,
  ]);
  assertEquals(flurrySizes(content), [6, 0]);
});

Deno.test("23 photos: compact caps M7 at torn4 and plays one Flurry", () => {
  const content = planFor(23);
  assertEquals(layouts(content), [
    null,
    "stack3",
    null,
    null,
    "torn4",
    null,
    "torn4",
    null,
  ]);
  assertEquals(flurrySizes(content), [7, 0]);
});

Deno.test("24 photos: full unlocks tilt6, one Flurry", () => {
  const content = planFor(24);
  assertEquals(content.cut, "full");
  assertEquals(layouts(content), [
    null,
    "stack3",
    null,
    null,
    "torn4",
    null,
    "tilt6",
    null,
  ]);
  assertEquals(flurrySizes(content), [6, 0]);
});

Deno.test("30 photos: full, all four collages, one Flurry", () => {
  const content = planFor(30);
  assertEquals(layouts(content), [
    null,
    "stack3",
    null,
    null,
    "torn4",
    null,
    "tilt6",
    "torn6",
  ]);
  assertEquals(flurrySizes(content), [7, 0]);
});

Deno.test("35 and 40 photos: full, both Flurries", () => {
  assertEquals(flurrySizes(planFor(35)), [6, 6]);
  assertEquals(flurrySizes(planFor(40)), [11, 6]);
});

Deno.test("big trips label only the photos shown nowhere", () => {
  // 200 - 8 moments - 15 collage extras = 177; 15 + 15 in Flurries.
  const content = planFor(200);
  assertEquals(flurrySizes(content), [15, 15]);
  assertEquals(content.flurry_leftovers.total_remaining_label, "And 147 more.");
  // 60 - 23 = 37 left, 30 shown -> 7 unshown, under the label threshold.
  assertEquals(planFor(60).flurry_leftovers.total_remaining_label, null);
});

Deno.test("collage extras are the photos nearest in time to the moment", () => {
  const content = planFor(15);
  // Moments are c0, c2, .., c14; M2 is c2, so its extras are c1 and c3.
  assertEquals(content.moments[1].photo_id, "c2");
  assertEquals(
    content.moments[1].collage_extras.map((p) => p.photo_id),
    ["c1", "c3"],
  );
});

Deno.test("no cut at any photo count ever repeats a photo", () => {
  for (const [withBonus, perDay] of [[false, 0], [true, 0], [false, 4]]) {
    for (let count = 0; count <= 60; count++) {
      const content = planFor(
        count,
        withBonus as boolean,
        (perDay as number) || count || 1,
      );
      assertEquals(validateWrapUpContent(content), true);

      const shown = [
        ...content.moments.flatMap((m) => [
          m.photo_id,
          ...m.collage_extras.map((p) => p.photo_id),
        ]),
        ...content.flurry_leftovers.flurry1.map((p) => p.photo_id),
        ...content.flurry_leftovers.flurry2.map((p) => p.photo_id),
      ];
      assertEquals(new Set(shown).size, shown.length, `repeat at ${count}`);

      for (const m of content.moments) {
        if (m.badge !== null) assertEquals(m.layout, null);
        if (m.layout === null) assertEquals(m.collage_extras.length, 0);
        for (const extra of m.collage_extras) {
          assertEquals(extra.day_date, m.day_date, `mixed days at ${count}`);
        }
      }
      if (content.cut === "highlight") {
        assertEquals(layouts(content).every((l) => l === null), true);
        assertEquals(flurrySizes(content), [0, 0]);
      }
      if (content.cut === "compact") {
        const allowed = [null, "stack3", "torn4"];
        assertEquals(layouts(content).every((l) => allowed.includes(l)), true);
        assertEquals(content.flurry_leftovers.flurry2.length, 0);
      }
      for (const size of flurrySizes(content)) {
        assertEquals(
          size === 0 || size >= 6,
          true,
          `sparse flurry at ${count}`,
        );
      }
    }
  }
});

Deno.test("invitationLine1 handles missing dates without crashing", () => {
  assertEquals(invitationLine1(null, null), "Your trip.");
  assertEquals(invitationLine1("2026-06-01", "2026-06-01"), "One day.");
  assertEquals(invitationLine1("2026-06-01", "2026-06-05"), "Five days.");
});

Deno.test("formatDateRange: single day, same month, cross-month, cross-year", () => {
  assertEquals(formatDateRange("2026-08-12", "2026-08-12"), "12 August 2026");
  assertEquals(
    formatDateRange("2026-08-12", "2026-08-16"),
    "12–16 August 2026",
  );
  assertEquals(
    formatDateRange("2026-02-25", "2026-03-01"),
    "25 February – 1 March 2026",
  );
  assertEquals(
    formatDateRange("2026-12-30", "2027-01-02"),
    "30 December 2026 – 2 January 2027",
  );
});

Deno.test("splitKeepsakeTitle splits multi-word names and leaves single words alone", () => {
  assertEquals(splitKeepsakeTitle("Lisbon Getaway"), {
    title_line1: "Lisbon",
    title_line2: "Getaway",
  });
  assertEquals(splitKeepsakeTitle("Portugal Road Trip 2026"), {
    title_line1: "Portugal Road",
    title_line2: "Trip 2026",
  });
  assertEquals(splitKeepsakeTitle("Reykjavik"), {
    title_line1: "Reykjavik",
    title_line2: "",
  });
});

// --- #292: the film follows the trip in time order ----------------------

function photo(
  id: string,
  day_date: string | null,
  taken_at: string | null,
  created_at = "2026-06-10T00:00:00Z",
  use_in_wrap_up: boolean | null = null,
): TripData["photos"][number] {
  return {
    id,
    day_date,
    taken_at,
    created_at,
    storage_path: `u/t/${id}.jpg`,
    caption: `caption ${id}`,
    use_in_wrap_up,
  };
}

Deno.test("sortPhotosChronologically: by day, then capture time, undated last", () => {
  const sorted = sortPhotosChronologically([
    photo("undated", null, "2026-06-01T08:00:00Z"),
    photo("d3", "2026-06-03", "2026-06-03T09:00:00Z"),
    photo("d1-late", "2026-06-01", "2026-06-01T18:00:00Z"),
    // No capture time: falls back to upload time.
    photo("d2-upload", "2026-06-02", null, "2026-06-02T12:00:00Z"),
    photo("d1-early", "2026-06-01", "2026-06-01T07:00:00Z"),
    photo("d2-taken", "2026-06-02", "2026-06-02T11:00:00+02:00"),
  ]);
  assertEquals(sorted.map((p) => p.id), [
    "d1-early",
    "d1-late",
    "d2-taken",
    "d2-upload",
    "d3",
    "undated",
  ]);
});

Deno.test("spreadEvenly keeps order and covers the whole list", () => {
  const list = Array.from({ length: 15 }, (_, i) => i);
  assertEquals(spreadEvenly(list, 8), [0, 2, 4, 6, 8, 10, 12, 14]);
  assertEquals(spreadEvenly(list, 3), [2, 7, 12]);
  assertEquals(spreadEvenly([1, 2], 8), [1, 2]);
  assertEquals(spreadEvenly(list, 0), []);
});

Deno.test("moments play in day order even when bonus photos come late", () => {
  // 3-day trip, photos fed in scrambled order; the bonus tasks were done
  // on days 3 and 2, and bonus completion order is day 3 first.
  const days = ["2026-06-01", "2026-06-02", "2026-06-03"];
  const list = days.flatMap((day, d) =>
    Array.from(
      { length: 6 },
      (_, i) => photo(`d${d + 1}-${i}`, day, `${day}T${10 + i}:00:00Z`),
    )
  ).reverse();
  const content = assembleWrapUpContent(
    tripData({
      photos: list,
      completedBonusTasks: [
        {
          completed_at: "2026-06-03T12:00:00Z",
          photo_id: "d3-2",
          title: "Late dare",
          points: 2,
        },
        {
          completed_at: "2026-06-02T12:00:00Z",
          photo_id: "d2-1",
          title: "Middle dare",
          points: 1,
        },
      ],
    }),
    validAiFields,
  );

  const moments = content.moments;
  assertEquals(moments.length, 8);
  for (let i = 1; i < moments.length; i++) {
    assertEquals(
      moments[i - 1].day_date! <= moments[i].day_date!,
      true,
      `M${i} (${moments[i - 1].day_date}) after M${i + 1} (${
        moments[i].day_date
      })`,
    );
  }
  // Every day of the trip gets moments, not just the first one.
  assertEquals(new Set(moments.map((m) => m.day_date)).size, 3);
  // A card flip's caption is its own photo's; a collage's comes from its
  // day's note (#298). Either way it belongs to the moment's day.
  const byId = new Map(list.map((p) => [p.id, p]));
  const noteByDay = new Map(
    validTripData.notes.map((n) => [n.day_date, n.content]),
  );
  for (const m of moments) {
    assertEquals(m.day_date, byId.get(m.photo_id)!.day_date);
    assertEquals(
      m.note,
      m.layout === null
        ? byId.get(m.photo_id)!.caption
        : noteByDay.get(m.day_date!) ?? null,
    );
  }
  // Badges stay on their bonus photos.
  assertEquals(
    moments.filter((m) => m.badge !== null).map((m) => m.photo_id),
    ["d2-1", "d3-2"],
  );
});

// --- #294: the user's per-photo picks ------------------------------------

// 20 photos over 5 days, c0..c19 in time order; [picks] maps index → pick.
function pickedPhotos(
  picks: Record<number, boolean>,
): TripData["photos"] {
  return photos(20).map((p, i) => ({
    ...p,
    taken_at: `${p.day_date}T${String(8 + (i % 4)).padStart(2, "0")}:00:00Z`,
    use_in_wrap_up: picks[i] ?? null,
  }));
}

function momentIds(list: TripData["photos"], bonusIds: string[] = []) {
  return pickMomentPhotos(list, bonusIds).map((p) => p.id).sort((a, b) =>
    Number(a.slice(1)) - Number(b.slice(1))
  );
}

function shownIds(content: WrapUpContent) {
  return [
    ...content.moments.flatMap((m) => [
      m.photo_id,
      ...m.collage_extras.map((p) => p.photo_id),
    ]),
    ...content.flurry_leftovers.flurry1.map((p) => p.photo_id),
    ...content.flurry_leftovers.flurry2.map((p) => p.photo_id),
    ...content.flurry_leftovers.photos.map((p) => p.photo_id),
  ];
}

Deno.test("picks: all on Auto spreads the moments over the trip", () => {
  assertEquals(momentIds(pickedPhotos({})), [
    "c1",
    "c3",
    "c6",
    "c8",
    "c11",
    "c13",
    "c16",
    "c18",
  ]);
});

Deno.test("picks: 3 Always photos all get moments, Auto fills the rest", () => {
  const ids = momentIds(pickedPhotos({ 0: true, 9: true, 19: true }));
  assertEquals(ids.length, 8);
  for (const id of ["c0", "c9", "c19"]) {
    assertEquals(ids.includes(id), true, `${id} missing`);
  }
});

Deno.test("picks: 10 Always photos fill all 8 moments, the 2 extra go to the Flurries", () => {
  const always: Record<number, boolean> = Object.fromEntries(
    Array.from({ length: 10 }, (_, i) => [i * 2, true]),
  );
  const list = pickedPhotos(always);
  const ids = momentIds(list);
  assertEquals(ids.length, 8);
  assertEquals(ids.every((id) => always[Number(id.slice(1))] === true), true);

  const content = assembleWrapUpContent(
    tripData({ photos: list, completedBonusTasks: [] }),
    validAiFields,
  );
  const shown = new Set(shownIds(content));
  // Never dropped: every Always photo is somewhere in the film.
  for (const index of Object.keys(always)) {
    assertEquals(shown.has(`c${index}`), true, `c${index} dropped`);
  }
});

Deno.test("picks: Leave out photos appear nowhere, moments or Flurries", () => {
  // All but 4 left out.
  const leftOut: Record<number, boolean> = Object.fromEntries(
    Array.from({ length: 16 }, (_, i) => [i + 2, false]),
  );
  const content = assembleWrapUpContent(
    tripData({ photos: pickedPhotos(leftOut), completedBonusTasks: [] }),
    validAiFields,
  );
  assertEquals(validateWrapUpContent(content), true);
  assertEquals(content.moments.map((m) => m.photo_id), [
    "c0",
    "c1",
    "c18",
    "c19",
  ]);
  assertEquals(shownIds(content).sort(), ["c0", "c1", "c18", "c19"]);
  // The cut follows what can be shown, not what was taken.
  assertEquals(content.cut, "highlight");
  assertEquals(content.footnote.photo_count, 20);
});

Deno.test("picks: a left-out bonus photo loses its badge slot", () => {
  const content = assembleWrapUpContent(
    tripData({
      photos: pickedPhotos({ 5: false }),
      completedBonusTasks: [{
        completed_at: "2026-06-02T12:00:00Z",
        photo_id: "c5",
        title: "Dare",
        points: 2,
      }],
    }),
    validAiFields,
  );
  assertEquals(content.moments.some((m) => m.badge !== null), false);
  assertEquals(shownIds(content).includes("c5"), false);
});

Deno.test("picks: bonus slots fall back to Auto picks, and an Always bonus photo keeps its badge", () => {
  // No Always photos: a bonus photo still takes a moment ahead of Auto ones.
  assertEquals(momentIds(pickedPhotos({}), ["c4"]).includes("c4"), true);

  // 7 Always + 2 bonus: only one moment is left, the first bonus gets it.
  const always: Record<number, boolean> = Object.fromEntries(
    [0, 3, 6, 9, 12, 15, 18].map((i) => [i, true]),
  );
  assertEquals(
    momentIds(pickedPhotos(always), ["c10", "c11"]).filter((id) =>
      !always[Number(id.slice(1))]
    ),
    ["c10"],
  );

  const content = assembleWrapUpContent(
    tripData({
      photos: pickedPhotos({ 7: true }),
      completedBonusTasks: [{
        completed_at: "2026-06-02T12:00:00Z",
        photo_id: "c7",
        title: "Dare",
        points: 2,
      }],
    }),
    validAiFields,
  );
  const moment = content.moments.find((m) => m.photo_id === "c7");
  assertEquals(moment?.badge, "Dare · Dare · ✦2");
  assertEquals(moment?.layout, null);
});

Deno.test("picks: moments stay in time order with Always photos late in the trip", () => {
  const content = assembleWrapUpContent(
    tripData({
      photos: pickedPhotos({ 19: true, 18: true, 0: true }).reverse(),
      completedBonusTasks: [],
    }),
    validAiFields,
  );
  const days = content.moments.map((m) => m.day_date!);
  assertEquals([...days].sort(), days);
});

// --- #298: a collage is one day, captioned with that day's note ----------

// [perDay] photos on each of [days] days, d{day}-{i} in time order.
function dayPhotos(days: number, perDay: number): TripData["photos"] {
  return Array.from({ length: days }, (_, d) => `2026-06-0${d + 1}`).flatMap(
    (day, d) =>
      Array.from(
        { length: perDay },
        (_, i) =>
          photo(
            `d${d + 1}-${i}`,
            day,
            `${day}T10:${String(i).padStart(2, "0")}:00Z`,
          ),
      ),
  );
}

Deno.test("collage tiles never come from another day", () => {
  // 24 photos (full cut) over 3 days of 8.
  const content = assembleWrapUpContent(
    tripData({ photos: dayPhotos(3, 8), notes: [], completedBonusTasks: [] }),
    validAiFields,
  );
  assertEquals(content.cut, "full");
  assertEquals(content.moments.some((m) => m.layout !== null), true);
  for (const m of content.moments) {
    for (const extra of m.collage_extras) {
      assertEquals(extra.day_date, m.day_date);
    }
  }
});

Deno.test("a day with too few photos steps the collage down, then to a card flip", () => {
  // 12 photos, one per day: no moment has a same-day partner.
  const content = assembleWrapUpContent(
    tripData({
      photos: Array.from(
        { length: 12 },
        (_, i) =>
          photo(
            `s${i}`,
            `2026-06-${String(i + 1).padStart(2, "0")}`,
            `2026-06-${String(i + 1).padStart(2, "0")}T10:00:00Z`,
          ),
      ),
      notes: [],
      completedBonusTasks: [],
    }),
    validAiFields,
  );
  assertEquals(content.cut, "compact");
  assertEquals(content.moments.every((m) => m.layout === null), true);
  // Nothing is lost: the unused photos are still leftovers.
  assertEquals(content.flurry_leftovers.photos.length, 4);
});

Deno.test("collages are captioned with their day's note, card flips with the photo's caption", () => {
  const content = assembleWrapUpContent(
    tripData({
      photos: dayPhotos(3, 8),
      notes: [
        { day_date: "2026-06-01", content: "Rain all morning. Then sun." },
        { day_date: "2026-06-03", content: "Last swim." },
      ],
      completedBonusTasks: [],
    }),
    validAiFields,
  );
  const collages = content.moments.filter((m) => m.layout !== null);
  assertEquals(collages.length > 0, true);
  for (const m of content.moments) {
    if (m.layout === null) {
      assertEquals(m.note, `caption ${m.photo_id}`);
    } else if (m.day_date === "2026-06-02") {
      // No note that day: no caption, never a photo's caption.
      assertEquals(m.note, null);
    }
  }
  const day1 = collages.filter((m) => m.day_date === "2026-06-01");
  assertEquals(day1[0]?.note, "Rain all morning. Then sun.");
});

Deno.test("two collages on one day show different parts of its note", () => {
  // One 30-photo day: all four collages land on it.
  const sentence = (n: number) => `Sentence ${n} ${"x".repeat(60)}.`;
  const content = assembleWrapUpContent(
    tripData({
      photos: dayPhotos(1, 30),
      notes: [{
        day_date: "2026-06-01",
        content: [1, 2, 3].map(sentence).join(" "),
      }],
      completedBonusTasks: [],
    }),
    validAiFields,
  );
  const notes = content.moments
    .filter((m) => m.layout !== null)
    .map((m) => m.note);
  assertEquals(notes, [sentence(1), sentence(2), sentence(3), null]);
});

Deno.test("noteExcerpts groups whole sentences up to the limit", () => {
  assertEquals(noteExcerpts(""), []);
  assertEquals(noteExcerpts("Last tram ride before the flight home"), [
    "Last tram ride before the flight home",
  ]);
  assertEquals(noteExcerpts("One. Two! Three?", 9), ["One. Two!", "Three?"]);
  // Line breaks split too.
  assertEquals(noteExcerpts("Morning swim\nLong lunch", 12), [
    "Morning swim",
    "Long lunch",
  ]);
  // Russian notes split the same way.
  assertEquals(noteExcerpts("Дождь с утра. Потом солнце.", 14), [
    "Дождь с утра.",
    "Потом солнце.",
  ]);
});

Deno.test("noteExcerpts cuts an over-long sentence at a word, on its own", () => {
  assertEquals(
    noteExcerpts("We walked along the canals, all the way. Then bed.", 24),
    ["We walked along the…", "Then bed."],
  );
  // No space to cut at: a hard cut, still marked.
  assertEquals(noteExcerpts("Supercalifragilistic", 6), ["Super…"]);
});

Deno.test("noteExcerpts drops the unfinished tail of a note cut at 500 chars", () => {
  const head = `${"Fine day. ".repeat(48)}`; // 480 chars
  const note = `${head}We walked to the old harbour and`.slice(0, 500);
  assertEquals(note.length, 500);
  const excerpts = noteExcerpts(note);
  assertEquals(excerpts.some((e) => e.includes("walked")), false);
  // A short note without a final full stop keeps its last sentence.
  assertEquals(noteExcerpts("Fine day. We walked home"), [
    "Fine day. We walked home",
  ]);
});
