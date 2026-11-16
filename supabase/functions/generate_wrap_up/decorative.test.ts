import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { decorativePhotos, MIN_DECORATIVE_PHOTOS } from "./decorative.ts";
import type { TripData } from "./gather.ts";

type Photo = TripData["photos"][number];

function photos(picks: (boolean | null)[]): Photo[] {
  return picks.map((pick, k) => ({
    id: `p${k}`,
    day_date: "2026-06-01",
    taken_at: `2026-06-01T${String(k % 24).padStart(2, "0")}:${
      String(Math.floor(k / 24)).padStart(2, "0")
    }:00Z`,
    created_at: "2026-06-01T23:59:00Z",
    storage_path: `u/t/p${k}.jpg`,
    caption: null,
    use_in_wrap_up: pick,
  }));
}

const ids = (list: Photo[]) => list.map((p) => p.id);

Deno.test("decorativePhotos: Auto photos only, when there are enough", () => {
  const all = photos([
    true,
    ...Array(MIN_DECORATIVE_PHOTOS).fill(null),
    true,
    false,
  ]);
  const shown = new Set(["p0", "p13"]);
  const picked = ids(decorativePhotos(all, shown, 100));
  assertEquals(picked.length, MIN_DECORATIVE_PHOTOS);
  assertEquals(picked.includes("p0") || picked.includes("p13"), false);
  assertEquals(picked.includes("p14"), false); // left out
});

Deno.test("decorativePhotos: an Always pick with no moment stays in", () => {
  const all = photos([true, ...Array(MIN_DECORATIVE_PHOTOS).fill(null)]);
  assertEquals(
    ids(decorativePhotos(all, new Set(), 100)).includes("p0"),
    true,
  );
});

Deno.test("decorativePhotos: too few Auto photos → topped up with Always picks", () => {
  const all = photos([...Array(20).fill(true), null, null]);
  const shown = new Set(ids(all));
  const picked = decorativePhotos(all, shown, 100);
  assertEquals(picked.length, MIN_DECORATIVE_PHOTOS);
  assertEquals(
    ids(picked).includes("p20") && ids(picked).includes("p21"),
    true,
  );
});

Deno.test("decorativePhotos: every photo Always → still a full ending", () => {
  const all = photos(Array(5).fill(true));
  assertEquals(
    ids(decorativePhotos(all, new Set(ids(all)), 100)),
    ["p0", "p1", "p2", "p3", "p4"],
  );
});

Deno.test("decorativePhotos: capped at max, chronological", () => {
  const all = photos(Array(50).fill(null));
  const picked = decorativePhotos(all, new Set(), 10);
  assertEquals(picked.length, 10);
  const times = picked.map((p) => p.taken_at!);
  assertEquals([...times].sort(), times);
});
