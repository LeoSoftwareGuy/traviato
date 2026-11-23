import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { filmSeconds, nnChaptersFor, skyPagesFor } from "./film_length.ts";
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

Deno.test("content: Sky pages, chapters and album pages grow with photos", () => {
  const sky = FIXTURE_PHOTO_COUNTS.map((n) =>
    (lengthContent("sky_story", n).sky as { pages: unknown[] }).pages.length
  );
  // A page per day (#463): the fixture's 3 days at every size — the length
  // never takes a day away, it only groups days past what fits.
  assertEquals(sky, [3, 3, 3]);
  const nn = FIXTURE_PHOTO_COUNTS.map((n) =>
    (lengthContent("neon_night", n).neon_night as { chapters: unknown[] })
      .chapters.length
  );
  // The film's length never takes a chapter away (#444): the days and
  // parts are the story; a short film shortens their scenes instead.
  assert(nn.every((n) => n === nn[0]), `${nn}`);
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
  // More photos, more pages (#458: chapters follow the days, main pages
  // the photos); never fewer.
  assert(
    gv[0].pages <= gv[1].pages && gv[1].pages <= gv[2].pages,
    `${gv.map((g) => g.pages)}`,
  );
  // Every photo forms the heart, shown ones too.
  assertEquals(gv.map((g) => g.heart), FIXTURE_PHOTO_COUNTS);
});

Deno.test("film_lengths.json is up to date (deno run --allow-write write_film_lengths.ts)", () => {
  assertEquals(
    fixtures.length,
    // …and ADE-Amsterdam (#448).
    FIXTURE_FILMS.length * FIXTURE_PHOTO_COUNTS.length + 1,
  );
  assertEquals(JSON.parse(JSON.stringify(filmLengthFixtures())), fixtures);
});
