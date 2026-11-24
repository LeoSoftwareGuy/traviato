// Sky Story on real memories (#463): ADE-Amsterdam (a Neon Night memory)
// and "Elmas birthday" in Budapest (a Golden Vows one), both forced to
// Sky Story — as when their film fails while it plays, or a Cultural
// memory like them. Code's words (no recorded Sky picks yet).

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import type { TripData } from "./gather.ts";
import { adeFilmMemory } from "./ade_amsterdam.ts";
import {
  budapestFilmMemory,
  budapestHeroScores,
  budapestSummaries,
} from "./budapest_birthday.ts";
import { skyStoryFilm } from "./sky_film.ts";
import { skyNoteHomes } from "./sky_slots.ts";
import { tripLogicalDays } from "./logical_day.ts";
import { sameLine } from "./neon_night.ts";

function asSky(memory: TripData): TripData {
  return { ...memory, trip: { ...memory.trip, vibes: ["Cultural"] } };
}

const memories = () => {
  const ade = adeFilmMemory();
  return [
    { name: "ade", memory: asSky(ade.memory), heroScores: ade.heroScores },
    {
      name: "budapest",
      memory: asSky(budapestFilmMemory()),
      heroScores: budapestHeroScores(),
      summaries: budapestSummaries(),
    },
  ];
};

Deno.test("real memories: every day a page, every photo on a page or in the mosaic", () => {
  for (const { name, memory, heroScores, summaries } of memories()) {
    const film = skyStoryFilm(memory, null, { heroScores, summaries });
    const content = film.content!;
    const days = tripLogicalDays(memory);
    const photoDays = new Set(
      film.skeleton.photos.map((p) => days.get(p.id) ?? p.day_date),
    );
    const pageDays = new Set(film.skeleton.pages.flatMap((p) => p.days));
    assertEquals(pageDays, photoDays, name);
    assert(content.pages.length <= 5, name);
    const shown = new Set([
      ...content.pages.flatMap((p) => [p.hero_photo_id, ...p.extra_photo_ids]),
      ...content.mosaic_photo_ids,
    ]);
    assert(film.skeleton.photos.every((p) => shown.has(p.id)), name);
    assertEquals(content.title, memory.trip.name, name);
  }
});

Deno.test("real memories: within 75 s, each line on its own page, nothing twice", () => {
  for (const { name, memory, heroScores, summaries } of memories()) {
    const film = skyStoryFilm(memory, null, { heroScores, summaries });
    assert(film.seconds <= 75 + 1e-9, `${name}: ${film.seconds} s`);
    const homes = skyNoteHomes(memory, film.skeleton);
    const texts: string[] = [];
    film.content!.pages.forEach((p, k) => {
      for (const e of p.excerpts) {
        assertEquals(homes.get(e.note_id), k, `${name}: ${e.text}`);
        texts.push(e.text);
      }
      if (p.headline) {
        assert(!/\d{1,2}:\d{2}/.test(p.headline), p.headline);
        assert(!sameLine(p.headline, memory.trip.name), p.headline);
        texts.push(p.headline);
      }
      if (p.sky_line) texts.push(p.sky_line);
      // A sky line only on a page without a note line.
      assert(!(p.sky_line && p.excerpts.length > 0), name);
    });
    for (const [i, t] of texts.entries()) {
      assert(
        !texts.slice(i + 1).some((u) => sameLine(t, u)),
        `${name}: «${t}» twice`,
      );
    }
    // Every page of a day with notes shows one of them.
    for (const [k, p] of film.content!.pages.entries()) {
      const own = [...homes].filter(([, page]) => page === k);
      if (own.length > 0) assert(p.excerpts.length > 0, `${name}: p${k + 1}`);
    }
    assert(film.unlisted.every((u) => u.reason.length > 0), name);
  }
});

Deno.test("Budapest: the birthday line plays on the spa day, the flight on day one", () => {
  const film = skyStoryFilm(asSky(budapestFilmMemory()), null, {
    heroScores: budapestHeroScores(),
    summaries: budapestSummaries(),
  });
  const pages = film.content!.pages;
  const lines = pages.map((p) => p.excerpts.map((e) => e.text).join(" "));
  assert(lines[0].includes("Tallinn to Budapest"), lines[0]);
  const spa = pages.findIndex((p) => p.headline === "Famous spas");
  assert(spa >= 0);
  assert(lines[spa].includes("Elmas birthday"), lines[spa]);
});

Deno.test("ADE and Budapest: the parts rejoin their days before a line goes", () => {
  for (const { name, memory, heroScores, summaries } of memories()) {
    const film = skyStoryFilm(memory, null, { heroScores, summaries });
    // Nothing went for length: only a split day, and what a page's box
    // doesn't hold.
    assert(
      film.trims.every((t) =>
        t.includes("split day") || t.includes("fit the page")
      ),
      `${name}: ${film.trims.join(" · ")}`,
    );
    assert(film.content!.pages.every((p) => p.excerpts.length > 0), name);
  }
});

Deno.test("ADE: day one's page plays day one's own lines", () => {
  const ade = adeFilmMemory();
  const memory = asSky(ade.memory);
  const film = skyStoryFilm(memory, null, { heroScores: ade.heroScores });
  const first = film.content!.pages[0];
  const day = film.skeleton.pages[0].days[0];
  const homes = skyNoteHomes(memory, film.skeleton);
  for (const e of first.excerpts) assertEquals(homes.get(e.note_id), 0);
  assertEquals(film.skeleton.pages[0].days, [day]);
});
