import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  filmSeconds,
  GV_FIXED_SECONDS,
  gvShapeFor,
  nnChaptersFor,
  skyPagesFor,
} from "./film_length.ts";
import {
  filmLengthFixtures,
  FIXTURE_FILMS,
  FIXTURE_PHOTO_COUNTS,
  lengthContent,
} from "./test_film_lengths.ts";
import fixtures from "./film_lengths.json" with { type: "json" };

Deno.test("filmSeconds: 30 s at 15 photos, 75 s at 40 or more (#434)", () => {
  assertEquals(filmSeconds(10), 30);
  assertEquals(filmSeconds(15), 30);
  assertEquals(filmSeconds(25), 48);
  assertEquals(filmSeconds(40), 75);
  assertEquals(filmSeconds(60), 75);
});

Deno.test("Sky Story: pages by length", () => {
  assertEquals(skyPagesFor(30), 1);
  assertEquals(skyPagesFor(48), 2);
  assertEquals(skyPagesFor(75), 5);
});

Deno.test("Neon Night: chapters by length", () => {
  assertEquals(nnChaptersFor(30), 1);
  assert(nnChaptersFor(48) >= 2 && nnChaptersFor(48) <= 3);
  assertEquals(nnChaptersFor(75), 5);
});

Deno.test("Golden Vows: photo pages first, the carousel last", () => {
  const all = {
    heroSeconds: [4.25, 4.25, 4.25, 4.25, 4.25, 4.25],
    chapters: 4,
    packingCard: true,
    carousel: true,
  };
  assertEquals(gvShapeFor(30, all), {
    heroes: 1,
    chapters: 0,
    packingCard: false,
    carousel: false,
  });
  const mid = gvShapeFor(48, all);
  assert(mid.heroes >= 3 && !mid.carousel, JSON.stringify(mid));
  const long = gvShapeFor(75, all);
  assert(long.carousel && long.packingCard, JSON.stringify(long));
  // Never without a photo page, however short.
  assertEquals(gvShapeFor(GV_FIXED_SECONDS - 10, all).heroes, 1);
});

Deno.test("content: Sky pages, chapters and album pages grow with photos", () => {
  const sky = FIXTURE_PHOTO_COUNTS.map((n) =>
    (lengthContent("sky_story", n).sky as { pages: unknown[] }).pages.length
  );
  assertEquals(sky, [1, 2, 5]);
  const nn = FIXTURE_PHOTO_COUNTS.map((n) =>
    (lengthContent("neon_night", n).neon_night as { chapters: unknown[] })
      .chapters.length
  );
  assert(nn[0] === 1 && nn[0] <= nn[1] && nn[1] <= nn[2], `${nn}`);
  const gv = FIXTURE_PHOTO_COUNTS.map((n) => {
    const c = lengthContent("golden_vows", n).golden_vows as {
      heroes: unknown[];
      chapters: unknown[];
      heart_photo_ids: string[];
    };
    return {
      pages: c.heroes.length + c.chapters.length,
      heart: c.heart_photo_ids.length,
    };
  });
  assert(gv[0].pages < gv[1].pages && gv[1].pages < gv[2].pages);
  // Every photo forms the heart, shown ones too.
  assertEquals(gv.map((g) => g.heart), FIXTURE_PHOTO_COUNTS);
});

Deno.test("film_lengths.json is up to date (deno run --allow-write write_film_lengths.ts)", () => {
  assertEquals(
    fixtures.length,
    FIXTURE_FILMS.length * FIXTURE_PHOTO_COUNTS.length,
  );
  assertEquals(JSON.parse(JSON.stringify(filmLengthFixtures())), fixtures);
});
