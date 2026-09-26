import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  assembleWrapUpContent,
  invitationLine1,
  selectCut,
  splitKeepsakeTitle,
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
  assertEquals(content.flurry_leftovers.photos.map((p) => p.photo_id), [
    "p9",
    "p10",
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

function photos(count: number, prefix = "c"): TripData["photos"] {
  return Array.from({ length: count }, (_, i) => ({
    id: `${prefix}${i}`,
    day_date: `2026-06-${String(1 + Math.floor(i / 4)).padStart(2, "0")}`,
    created_at: `2026-06-01T00:00:00Z`,
    storage_path: `u/t/${prefix}${i}.jpg`,
    caption: null,
  }));
}

function planFor(count: number, withBonus = false) {
  const list = photos(count);
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
  // M2 is c1; the pool is c8..c14, so its two extras are c8 and c9.
  assertEquals(
    content.moments[1].collage_extras.map((p) => p.photo_id),
    ["c8", "c9"],
  );
});

Deno.test("no cut at any photo count ever repeats a photo", () => {
  for (const withBonus of [false, true]) {
    for (let count = 0; count <= 60; count++) {
      const content = planFor(count, withBonus);
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
