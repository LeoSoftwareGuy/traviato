import {
  assertEquals,
  assertRejects,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { gatherTripData } from "./gather.ts";
import { fakeSupabaseClient } from "./test_fakes.ts";

Deno.test("gatherTripData maps trip, notes, photos, bonus tasks, stars and truncates long notes", async () => {
  const client = fakeSupabaseClient({
    trips: [
      {
        name: "Lisbon",
        destination: "Portugal",
        country_code: "PT",
        start_date: "2026-06-01",
        end_date: "2026-06-05",
        vibes: ["Foodie"],
        cover_image_path: "asset:sunset",
        user_id: "user-1",
      },
    ],
    day_notes: [{ day_date: "2026-06-01", content: "x".repeat(600) }],
    photos: [
      {
        id: "photo-1",
        day_date: "2026-06-01",
        created_at: "2026-06-01T09:00:00Z",
        storage_path: "u/t/photo-1.jpg",
        caption: "Golden hour",
      },
    ],
    bonus_task_assignments: [
      {
        completed_at: "2026-06-01T10:00:00Z",
        photo_id: "photo-1",
        bonus_task_templates: { title: "Snap anything at all", points: 1 },
      },
    ],
    points_ledger: [{ points: 1 }, { points: 2 }],
    user_achievements: [
      {
        earned_at: "2026-06-03",
        achievement_templates: {
          code: "first_adventure",
          title: "First Adventure",
          description: "...",
        },
      },
    ],
  });

  const result = await gatherTripData(client, "trip-1");

  assertEquals(result.trip.name, "Lisbon");
  assertEquals(result.trip.vibes, ["Foodie"]);
  assertEquals(result.trip.cover_image_path, "asset:sunset");
  assertEquals(result.notes[0].content.length, 500);
  assertEquals(result.photos[0].storage_path, "u/t/photo-1.jpg");
  assertEquals(result.completedBonusTasks, [
    {
      completed_at: "2026-06-01T10:00:00Z",
      photo_id: "photo-1",
      title: "Snap anything at all",
      points: 1,
    },
  ]);
  assertEquals(result.starsEarned, 3);
  assertEquals(result.latestAchievement, {
    code: "first_adventure",
    title: "First Adventure",
    description: "...",
  });
});

Deno.test("gatherTripData returns null cover_image_path, empty vibes and zero stars when unset", async () => {
  const client = fakeSupabaseClient({
    trips: [
      {
        name: "Lisbon",
        destination: null,
        country_code: null,
        start_date: null,
        end_date: null,
        vibes: null,
        cover_image_path: null,
        user_id: "user-1",
      },
    ],
    day_notes: [],
    photos: [],
    bonus_task_assignments: [],
    points_ledger: [],
    user_achievements: [],
  });

  const result = await gatherTripData(client, "trip-1");

  assertEquals(result.latestAchievement, null);
  assertEquals(result.trip.vibes, []);
  assertEquals(result.trip.cover_image_path, null);
  assertEquals(result.starsEarned, 0);
  assertEquals(result.completedBonusTasks, []);
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

// #109: a permission error on any of the parallel queries must throw rather
// than silently default to an empty array — an empty array there previously
// meant a wrap-up could be generated from missing data instead of failing
// loudly.
Deno.test("gatherTripData throws with a descriptive message when a query errors", async () => {
  const client = fakeSupabaseClient(
    {
      trips: [
        {
          name: "Lisbon",
          destination: null,
          country_code: null,
          start_date: null,
          end_date: null,
          vibes: [],
          cover_image_path: null,
          user_id: "user-1",
        },
      ],
    },
    { photos: { message: "permission denied for table photos" } },
  );

  await assertRejects(
    () => gatherTripData(client, "trip-1"),
    Error,
    "failed to load photos: permission denied for table photos",
  );
});
