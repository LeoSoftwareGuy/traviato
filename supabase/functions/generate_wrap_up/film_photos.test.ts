import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import type { TripData } from "./gather.ts";
import { filmPhotoIds, withFilmPhotos } from "./film_photos.ts";
import { validTripData } from "./test_fixtures.ts";

function tripWith(
  count: number,
  pick: (i: number) => boolean | null = () => null,
): TripData {
  return {
    ...validTripData,
    photos: Array.from({ length: count }, (_, i) => ({
      id: `p${String(i).padStart(3, "0")}`,
      day_date: "2026-06-01",
      taken_at: new Date(Date.UTC(2026, 5, 1, 8) + i * 60_000).toISOString(),
      created_at: "2026-06-01T08:00:00Z",
      storage_path: `u/t/p${i}.jpg`,
      caption: null,
      use_in_wrap_up: pick(i),
    })),
  };
}

Deno.test("up to 60 photos all play (#433)", () => {
  assertEquals(filmPhotoIds(tripWith(40)).length, 40);
  assertEquals(filmPhotoIds(tripWith(60)).length, 60);
});

Deno.test("more than 60: the best Auto photos, spread, in time order", () => {
  const trip = tripWith(120);
  const scores = { p005: 5, p100: 5 };
  const ids = filmPhotoIds(trip, scores);
  assertEquals(ids.length, 60);
  assertEquals(ids.includes("p005") && ids.includes("p100"), true);
  assertEquals([...ids].sort(), ids);
  // Spread over the memory, not just its first hour.
  assertEquals(ids.some((id) => id > "p100"), true);
});

Deno.test("15+ Always picks are exactly the film's photos", () => {
  const trip = tripWith(50, (i) => i % 2 === 0 ? true : null); // 25 Always
  const ids = filmPhotoIds(trip);
  assertEquals(ids.length, 25);
  assertEquals(ids.every((id) => Number(id.slice(1)) % 2 === 0), true);
  // The others are left out of the film's copy of the memory.
  const film = withFilmPhotos(trip);
  assertEquals(
    film.photos.filter((p) => p.use_in_wrap_up !== false).length,
    25,
  );
});

Deno.test("fewer than 15 Always picks: all in, topped up with Auto", () => {
  const trip = tripWith(80, (i) => i < 5 ? true : i === 79 ? false : null);
  const ids = filmPhotoIds(trip);
  assertEquals(ids.length, 60);
  for (let i = 0; i < 5; i++) assertEquals(ids.includes(`p00${i}`), true);
  assertEquals(ids.includes("p079"), false);
});

Deno.test("an unchanged memory is returned as it is", () => {
  const trip = tripWith(20);
  assertEquals(withFilmPhotos(trip), trip);
});
