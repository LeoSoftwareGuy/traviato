import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { WRAP_UP_LIMITS, wrapUpMissing } from "./wrap_up_limits.ts";

Deno.test("limits come from the shared config", () => {
  assertEquals(WRAP_UP_LIMITS.minPhotos, 15);
  assertEquals(WRAP_UP_LIMITS.maxFilmPhotos, 60);
  assertEquals(WRAP_UP_LIMITS.minNotes, 1);
});

Deno.test("14 photos are locked, 15 are not; 0 notes are locked", () => {
  assertEquals(wrapUpMissing(14, 1), { photos: 1, notes: 0 });
  assertEquals(wrapUpMissing(15, 1), null);
  assertEquals(wrapUpMissing(40, 0), { photos: 0, notes: 1 });
  assertEquals(wrapUpMissing(12, 0), { photos: 3, notes: 1 });
});
