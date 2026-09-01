import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { gatherTripData } from "./gather.ts";
import { fakeSupabaseClient } from "./test_fakes.ts";

Deno.test("gatherTripData maps trip, quests, notes, photos and truncates long notes", async () => {
  const client = fakeSupabaseClient({
    trips: [
      {
        name: "Lisbon",
        destination: "Portugal",
        country_code: "PT",
        start_date: "2026-06-01",
        end_date: "2026-06-05",
        vibes: ["Foodie"],
        user_id: "user-1",
      },
    ],
    quests: [
      { day_date: "2026-06-01", time: "09:00", title: "Try pasteis de nata", place_text: "Belem", completed_at: null },
    ],
    day_notes: [{ day_date: "2026-06-01", content: "x".repeat(600) }],
    photos: [
      { id: "photo-1", day_date: "2026-06-01", place_text: "Belem", people_tags: ["Alex"], caption: "Golden hour" },
    ],
    user_achievements: [
      {
        earned_at: "2026-06-03",
        achievement_templates: { code: "first_adventure", title: "First Adventure", description: "..." },
      },
    ],
  });

  const result = await gatherTripData(client, "trip-1");

  assertEquals(result.trip.name, "Lisbon");
  assertEquals(result.trip.vibes, ["Foodie"]);
  assertEquals(result.quests.length, 1);
  assertEquals(result.quests[0].title, "Try pasteis de nata");
  assertEquals(result.notes[0].content.length, 500);
  assertEquals(result.photos[0].people_tags, ["Alex"]);
  assertEquals(result.latestAchievement, {
    code: "first_adventure",
    title: "First Adventure",
    description: "...",
  });
});

Deno.test("gatherTripData returns a null latestAchievement when none earned", async () => {
  const client = fakeSupabaseClient({
    trips: [
      {
        name: "Lisbon",
        destination: null,
        country_code: null,
        start_date: null,
        end_date: null,
        vibes: [],
        user_id: "user-1",
      },
    ],
    quests: [],
    day_notes: [],
    photos: [],
    user_achievements: [],
  });

  const result = await gatherTripData(client, "trip-1");

  assertEquals(result.latestAchievement, null);
  assertEquals(result.trip.vibes, []);
});

Deno.test("gatherTripData throws when the trip doesn't exist", async () => {
  const client = fakeSupabaseClient({ trips: [] });

  let threw = false;
  try {
    await gatherTripData(client, "missing-trip");
  } catch {
    threw = true;
  }
  assertEquals(threw, true);
});
