// The Journal is the truth (#468) on a real backfilled memory: "Arabic
// retreat" (arabic_retreat.ts). Every photo and note plays on the Journal
// day it shows under, never on a day worked out from its capture or typing
// time; a backfilled note goes, within its day, to the photos that show
// what it says.

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import type { TripData } from "./gather.ts";
import {
  arabicFilmMemory,
  arabicHeroScores,
  arabicNote,
  arabicSummaries,
} from "./arabic_retreat.ts";
import { skyStoryFilm } from "./sky_film.ts";
import { skyNoteHomes } from "./sky_slots.ts";
import { goldenVowsFilm } from "./gv_film.ts";
import { gvNoteHomes } from "./gv_slots.ts";
import { neonNightFilm } from "./neon_film.ts";
import { isBackfilled, noteChapters } from "./film_slots.ts";
import { filmPhotoIds } from "./film_photos.ts";
import fixture from "./fixtures/arabic_retreat.json" with { type: "json" };

const MOSQUE = "Went to grand Kabul mosque";
// "Wadi Shab", as dictated.
const WADI_SHAB = "Today we decided to go visit body shop";
const BAZAAR = "Went to the bazaar place";
const NIZWA = "Nizwa";
const NIZWA_TOWN = "Then we decided to visit really old city";

const sky = () =>
  skyStoryFilm(arabicFilmMemory(), null, {
    heroScores: arabicHeroScores(),
    summaries: arabicSummaries(),
  });

const summaryOf = (id: string) => arabicSummaries().get(id) ?? "";
const shows = (photos: { id: string }[], word: RegExp) =>
  photos.filter((p) => word.test(summaryOf(p.id))).length;

Deno.test("Arabic retreat: every note was typed after the trip — backfilled", () => {
  const memory = arabicFilmMemory();
  assertEquals(memory.notes.length, 15);
  assert(memory.notes.every(isBackfilled));
});

Deno.test("Arabic retreat: every Journal day with photos keeps a film photo, past the 60 cap", () => {
  const ids = new Set(
    filmPhotoIds(
      structuredClone(fixture.trip_data) as unknown as TripData,
      arabicHeroScores(),
    ),
  );
  const days = new Set(fixture.trip_data.photos.map((p) => p.day_date));
  for (const day of days) {
    assert(
      fixture.trip_data.photos.some((p) => p.day_date === day && ids.has(p.id)),
      day!,
    );
  }
  // All 60 Always picks stay; 04-16 and 04-18 (no Always pick) add theirs.
  const always = fixture.trip_data.photos.filter((p) => p.use_in_wrap_up);
  assertEquals(always.length, 60);
  assert(always.every((p) => ids.has(p.id)));
  assertEquals(ids.size, 62);
});

Deno.test("Arabic retreat: Sky Story — 8 Journal days on 5 pages, none dropped, photos on their Journal day", () => {
  const film = sky();
  const pages = film.skeleton.pages;
  assertEquals(pages.length, 5);
  assertEquals(pages.flatMap((p) => p.days), [
    "2026-04-11",
    "2026-04-12",
    "2026-04-13",
    "2026-04-14",
    "2026-04-15",
    "2026-04-16",
    "2026-04-17",
    "2026-04-18",
  ]);
  for (const p of pages) {
    for (const photo of p.photos) assert(p.days.includes(photo.day_date!));
  }
});

Deno.test("Arabic retreat: Sky Story — every note on a page of its own Journal day", () => {
  const memory = arabicFilmMemory();
  const film = sky();
  const homes = skyNoteHomes(memory, film.skeleton);
  for (const n of memory.notes) {
    const home = homes.get(n.id!);
    assert(home !== null && home !== undefined, n.content);
    assert(film.skeleton.pages[home].days.includes(n.day_date), n.content);
  }
  // Notes on no list only for their lines (long dictated sentences), never
  // for their day.
  for (const u of film.unlisted) {
    assert(!u.reason.includes("no page"), u.reason);
  }
  // Every line plays on its note's page.
  film.content!.pages.forEach((p, k) => {
    for (const e of p.excerpts) assertEquals(homes.get(e.note_id), k, e.text);
  });
});

Deno.test("Arabic retreat: Sky Story — the mosque, Wadi Shab and Nizwa text on their own photos' page", () => {
  const memory = arabicFilmMemory();
  const film = sky();
  const homes = skyNoteHomes(memory, film.skeleton);
  const pageOf = (start: string) =>
    film.skeleton.pages[homes.get(arabicNote(start))!];
  assert(shows(pageOf(MOSQUE).photos, /mosque/i) >= 5);
  assert(shows(pageOf(WADI_SHAB).photos, /canyon|waterfall/i) >= 5);
  assert(shows(pageOf(NIZWA).photos, /fort/i) >= 2);
  assert(shows(pageOf(NIZWA_TOWN).photos, /fort/i) >= 2);
  // The bazaar is 04-15's, never the Nizwa fort page (it was, before #468).
  assertEquals(shows(pageOf(BAZAAR).photos, /fort/i), 0);
  assertEquals(pageOf(MOSQUE).days, ["2026-04-13"]);
  assertEquals(shows(pageOf(MOSQUE).photos, /canyon|waterfall/i), 0);
});

Deno.test('Arabic retreat: no headline from a list\'s label ("Size Measures")', () => {
  const film = sky();
  for (const r of film.report.filter((x) => x.slot.endsWith(".headline"))) {
    for (const c of r.candidates) {
      for (const bad of ["Size Measures", "Weight Weighs", "Knots Contains"]) {
        assertEquals(c.text === bad, false, `${r.slot}: ${c.text}`);
      }
    }
  }
  for (const p of film.content!.pages) {
    for (const e of p.excerpts) assertEquals(e.text.startsWith("•"), false);
  }
});

Deno.test("Arabic retreat: Golden Vows — notes on their Journal day's chapter, the mosque text on a mosque page", () => {
  const memory = arabicFilmMemory();
  const film = goldenVowsFilm(memory, null, {
    heroScores: arabicHeroScores(),
    summaries: arabicSummaries(),
  });
  const { chapters, mains } = film.skeleton;
  const owners = noteChapters(memory, chapters, true);
  for (const n of memory.notes) {
    const own = owners.get(n.id!) ?? [];
    assert(own.length > 0, n.content);
    for (const i of own) {
      assert(chapters[i].days.includes(n.day_date), n.content);
    }
  }
  const homes = gvNoteHomes(memory, film.skeleton);
  const photosOf = (start: string) => {
    const home = homes.get(arabicNote(start))!;
    assert(home !== "none", start);
    if ("main" in home) return [{ id: mains[home.main].photo_id }];
    return chapters[home.chapter].pages[home.page].prints.map((id) => ({ id }));
  };
  assert(shows(photosOf(MOSQUE), /mosque|chandelier|dome/i) > 0);
  assert(shows(photosOf(WADI_SHAB), /canyon|waterfall|pool/i) > 0);
});

Deno.test("Arabic retreat: Neon Night — every note on its Journal day's chapter", () => {
  const memory = arabicFilmMemory();
  const { chapters } = neonNightFilm(memory, null, arabicHeroScores());
  const owners = noteChapters(memory, chapters);
  for (const n of memory.notes) {
    const own = owners.get(n.id!) ?? [];
    assert(own.length > 0, n.content);
    for (const i of own) {
      assert(chapters[i].days.includes(n.day_date), n.content);
    }
  }
});
