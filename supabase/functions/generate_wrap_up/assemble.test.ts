import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  assembleWrapUpContent,
  invitationLine1,
  splitKeepsakeTitle,
} from "./assemble.ts";
import { validateWrapUpContent } from "./content.ts";
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

Deno.test("flurry label announces the count beyond the 15+15 display cap", () => {
  const manyPhotos = Array.from({ length: 45 }, (_, i) => ({
    id: `q${i}`,
    day_date: "2026-06-01",
    created_at: `2026-06-01T${String(i).padStart(2, "0")}:00:00Z`,
    storage_path: `u/t/q${i}.jpg`,
    caption: null,
  }));
  const data = tripData({ photos: manyPhotos, completedBonusTasks: [] });
  const content = assembleWrapUpContent(data, validAiFields);
  // 45 photos - 8 moments = 37 leftovers; 37 - 30 display cap = 7 -> still under 10, suppressed
  assertEquals(content.flurry_leftovers.photos.length, 37);
  assertEquals(content.flurry_leftovers.total_remaining_label, null);

  const evenMorePhotos = Array.from({ length: 60 }, (_, i) => ({
    id: `r${i}`,
    day_date: "2026-06-01",
    created_at: `2026-06-01T${String(i % 24).padStart(2, "0")}:00:00Z`,
    storage_path: `u/t/r${i}.jpg`,
    caption: null,
  }));
  const bigData = tripData({ photos: evenMorePhotos, completedBonusTasks: [] });
  const bigContent = assembleWrapUpContent(bigData, validAiFields);
  // 60 - 8 = 52 leftovers; 52 - 30 = 22 -> labeled
  assertEquals(
    bigContent.flurry_leftovers.total_remaining_label,
    "And 22 more.",
  );
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
