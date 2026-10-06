import {
  assertEquals,
  assertNotEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { computeAiInputHash } from "./ai_input_hash.ts";
import { validTripData } from "./test_fixtures.ts";

Deno.test("computeAiInputHash is stable for the same inputs", async () => {
  assertEquals(
    await computeAiInputHash(validTripData),
    await computeAiInputHash(structuredClone(validTripData)),
  );
});

Deno.test("photo, date and stat changes never change the hash", async () => {
  const edited = {
    ...validTripData,
    trip: { ...validTripData.trip, start_date: "2030-01-01" },
    photos: [],
    completedBonusTasks: [],
    starsEarned: 999,
  };
  assertEquals(
    await computeAiInputHash(edited),
    await computeAiInputHash(validTripData),
  );
});

Deno.test("note, name, destination, vibe and achievement changes do", async () => {
  const base = await computeAiInputHash(validTripData);
  const variants = [
    {
      ...validTripData,
      notes: [...validTripData.notes, { day_date: "2026-06-09", content: "x" }],
    },
    { ...validTripData, trip: { ...validTripData.trip, name: "Renamed" } },
    { ...validTripData, trip: { ...validTripData.trip, destination: "Oslo" } },
    { ...validTripData, trip: { ...validTripData.trip, vibes: ["Wellness"] } },
    { ...validTripData, latestAchievement: null },
  ];
  for (const v of variants) {
    assertNotEquals(await computeAiInputHash(v), base);
  }
});
