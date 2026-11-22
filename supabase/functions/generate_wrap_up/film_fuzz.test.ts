// The chosen film always plays (#433): thousands of random memories and
// random, broken or partial director outputs, and every one ends in a
// plan that passes its film's checks — never null, never another film.

import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import type { TripData } from "./gather.ts";
import { validTripData } from "./test_fixtures.ts";
import { withFilmPhotos } from "./film_photos.ts";
import { neonNightFilm } from "./neon_film.ts";
import { parseNeonPicks } from "./neon_slots.ts";
import { MAX_NN_TITLE_CHARS, sameLine } from "./neon_night.ts";
import { isDrugReference } from "./excerpts.ts";
import { MAX_GV_TITLE_CHARS, MIN_GV_HEROES } from "./golden_vows.ts";
import { goldenVowsFilm, gvShortestSeconds } from "./gv_film.ts";
import { parsePicks } from "./film_slots.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
import { BANNED_PHRASES } from "./film_plan.ts";

// A small seeded PRNG (mulberry32), so a failure can be replayed.
function rng(seed: number) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

type Rand = ReturnType<typeof rng>;
const int = (r: Rand, lo: number, hi: number) =>
  lo + Math.floor(r() * (hi - lo + 1));
const pick = <T>(r: Rand, list: readonly T[]): T =>
  list[int(r, 0, list.length - 1)];

const SENTENCES = [
  "We danced until the lights came on at 4am.",
  "I felt so happy I almost cried.",
  "It was fun.",
  "Все устали.",
  "The DJ played our song and the whole crowd sang along!",
  "Ribs at Café de Klos, 3 plates between us.",
  "An unforgettable, epic night of wanderlust.",
  "Lost my jacket somewhere in the second room.",
  "Мы впервые увидели рассвет над каналом.",
  "Fuck, that bass.",
  "The ferry back took 40 minutes.",
];

function randomTrip(r: Rand): TripData {
  const days = int(r, 1, 4);
  const count = r() < 0.1 ? int(r, 2, 14) : int(r, 15, 80);
  const photos: TripData["photos"] = [];
  let t = Date.UTC(2026, 8, 1, 18);
  for (let i = 0; i < count; i++) {
    t += r() < 0.08 ? int(r, 2, 14) * 3_600_000 : int(r, 1, 40) * 60_000;
    const day = Math.min(
      days - 1,
      Math.floor((t - Date.UTC(2026, 8, 1, 8)) / 86_400_000),
    );
    photos.push({
      id: `f${i}`,
      day_date: `2026-09-0${1 + Math.max(0, day)}`,
      taken_at: r() < 0.9 ? new Date(t).toISOString() : null,
      created_at: new Date(t).toISOString(),
      storage_path: `u/t/f${i}.jpg`,
      caption: r() < 0.3 ? pick(r, SENTENCES) : null,
      use_in_wrap_up: r() < 0.15 ? true : r() < 0.05 ? false : null,
      place_text: r() < 0.3
        ? pick(r, [
          "Shelter",
          "De School",
          "NDSM",
          "A very long place name indeed",
        ])
        : null,
    });
  }
  const notes: TripData["notes"] = Array.from(
    { length: int(r, 1, 8) },
    (_, k) => ({
      id: `n${k}`,
      day_date: `2026-09-0${int(r, 1, days)}`,
      content: Array.from({ length: int(r, 1, 4) }, () => pick(r, SENTENCES))
        .join(" "),
      taken_at: new Date(Date.UTC(2026, 8, 1, 20) + k * 3_600_000)
        .toISOString(),
      photo_id: r() < 0.3 ? `f${int(r, 0, count - 1)}` : null,
    }),
  );
  return {
    ...validTripData,
    trip: {
      ...validTripData.trip,
      start_date: "2026-09-01",
      end_date: `2026-09-0${days}`,
    },
    photos,
    notes,
    utc_offset_minutes: pick(r, [0, 60, 120, -300]),
  };
}

// A random value of any shape.
function junk(r: Rand, depth = 0): unknown {
  switch (int(r, 0, depth > 2 ? 4 : 6)) {
    case 0:
      return null;
    case 1:
      return int(r, -5, 99);
    case 2:
      return pick(r, [
        "",
        "x",
        "f0",
        "f9999",
        "n0",
        "timeline",
        BANNED_PHRASES[0],
        "A title that is far too long for any neon sign",
      ]);
    case 3:
      return r() < 0.5;
    case 4:
      return undefined;
    case 5:
      return Array.from({ length: int(r, 0, 4) }, () => junk(r, depth + 1));
    default:
      return Object.fromEntries(
        Array.from(
          { length: int(r, 0, 3) },
          (_, k) => [`k${k}`, junk(r, depth + 1)],
        ),
      );
  }
}

// [plan] broken in random ways: fields dropped or swapped for junk, ids
// invented, lines too long or banned, lists shuffled, duplicated, emptied.
function mutate(r: Rand, value: unknown, ids: string[], depth = 0): unknown {
  if (r() < 0.04) return junk(r);
  if (Array.isArray(value)) {
    let list = value.map((v) => mutate(r, v, ids, depth + 1));
    if (r() < 0.15) list = list.reverse();
    if (r() < 0.1 && list.length) list.push(list[0]);
    if (r() < 0.08) list = list.slice(0, int(r, 0, list.length));
    if (r() < 0.05) list = [];
    return list;
  }
  if (typeof value === "object" && value !== null) {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value)) {
      if (r() < 0.05) continue;
      out[k] = mutate(r, v, ids, depth + 1);
    }
    return out;
  }
  if (typeof value === "string") {
    const roll = r();
    if (roll < 0.05) return pick(r, ids);
    if (roll < 0.08) return "invented";
    if (roll < 0.12) {
      return `${value} ${pick(r, BANNED_PHRASES)} and much more text`;
    }
    if (roll < 0.14) return "";
  }
  return value;
}

const RUNS = 2500;

// A pick_neon_lines answer for [slots] broken in random ways (#454): ids
// from other slots, invented ones, the same id twice, free titles too
// long, banned or in another language, or junk for the whole answer.
function randomPicks(
  r: Rand,
  slots: { slot: string; candidates: { id: string }[] }[],
): unknown {
  if (r() < 0.1) return junk(r);
  const every = slots.flatMap((s) => s.candidates.map((c) => c.id));
  return {
    picks: slots.filter(() => r() > 0.1).map((s) => ({
      slot: r() < 0.03 ? "ch99.card" : s.slot,
      ids: Array.from({ length: int(r, 0, 4) }, () => {
        const roll = r();
        if (roll < 0.6 && s.candidates.length) {
          return pick(r, s.candidates).id;
        }
        if (roll < 0.85 && every.length) return pick(r, every);
        return pick(r, ["invented", "", "h:0", "c:f9999"]);
      }),
      free_title: r() < 0.3
        ? pick(r, [
          "Doors open",
          "Брюссель",
          "A title that is far too long for any neon sign",
          BANNED_PHRASES[0],
          "Day 2",
          "23:15",
          "",
        ])
        : null,
    })),
  };
}

Deno.test(`Neon Night: ${RUNS} random memories and broken picks all play (#454)`, () => {
  for (let seed = 1; seed <= RUNS; seed++) {
    const r = rng(seed);
    const trip = withFilmPhotos(randomTrip(r));
    if (trip.photos.length < 2) continue;
    const cut = neonNightFilm(trip, null);
    const picks = parseNeonPicks(randomPicks(r, cut.slots));
    const { content, report } = neonNightFilm(trip, picks);
    if (trip.photos.length >= 15) {
      assert(content.chapters.length > 0, `seed ${seed}`);
    }
    // Every slot resolved from its own list (or a checked free title).
    for (const x of report) {
      for (const c of x.chosen) {
        if (c.id === "day" || c.id === "free") continue;
        assert(
          x.candidates.some((k) => k.id === c.id),
          `seed ${seed}: ${x.slot} ${c.id}`,
        );
      }
    }
    const ids = report.flatMap((x) =>
      x.chosen.map((c) => c.id).filter((id) => id !== "day" && id !== "free")
    );
    assertEquals(new Set(ids).size, ids.length, `seed ${seed}: an id twice`);
    for (const c of content.chapters) {
      assert(c.title.length > 0, `seed ${seed}: untitled`);
      assert(
        [...c.title].length <= MAX_NN_TITLE_CHARS,
        `seed ${seed}: ${c.title}`,
      );
    }
    const shown = [
      ...content.chapters.flatMap((c) => [
        c.title,
        c.note,
        ...c.moments.flatMap((m) => (m.words ?? []).map((w) => w.text)),
      ]),
      content.note?.text,
      content.headline,
    ].filter((t): t is string => !!t);
    for (let i = 0; i < shown.length; i++) {
      assertEquals(isDrugReference(shown[i]), false, `seed ${seed}`);
      for (let j = i + 1; j < shown.length; j++) {
        assertEquals(
          sameLine(shown[i], shown[j]),
          false,
          `seed ${seed}: ${shown[i]} / ${shown[j]}`,
        );
      }
    }
  }
});

Deno.test(`Golden Vows: ${RUNS} random memories and broken picks all play (#458)`, () => {
  for (let seed = 1; seed <= RUNS; seed++) {
    const r = rng(seed * 7919);
    const trip = withFilmPhotos(randomTrip(r));
    if (trip.photos.filter((p) => p.use_in_wrap_up !== false).length < 5) {
      continue;
    }
    const cut = goldenVowsFilm(trip, null);
    const picks = parsePicks(randomPicks(r, cut.slots));
    const { content, report, skeleton } = goldenVowsFilm(trip, picks, {
      language: pick(r, ["en", "ru"] as const),
    });
    // Never a chapter lost, every chapter titled; at least 2 main pages
    // when there are photos for them.
    assertEquals(content.chapters.length, skeleton.chapters.length);
    for (const c of content.chapters) {
      assert(c.title.length > 0, `seed ${seed}: untitled`);
      assert([...c.title].length <= MAX_GV_TITLE_CHARS, `seed ${seed}`);
    }
    assert(
      content.heroes.length >= Math.min(MIN_GV_HEROES, skeleton.mains.length),
      `seed ${seed}: ${content.heroes.length} main pages`,
    );
    // A captioned main page shows its caption as written, no time.
    const byId = new Map(trip.photos.map((p) => [p.id, p]));
    for (const h of content.heroes) {
      const caption = byId.get(h.photo_id)?.caption?.trim();
      if (caption) {
        assertEquals(h.note, caption, `seed ${seed}`);
        assertEquals(h.taken_at, null, `seed ${seed}`);
      }
    }
    // Every pick from its own list (or checked words of the director's).
    for (const x of report) {
      for (const c of x.chosen) {
        if (c.id === "day" || c.id === "free") continue;
        assert(
          x.candidates.some((k) => k.id === c.id),
          `seed ${seed}: ${x.slot} ${c.id}`,
        );
      }
    }
    // No words twice, nothing about drugs.
    const shown = [
      content.occasion_line,
      content.end_line,
      content.carousel?.title,
      ...content.heroes.flatMap((h) => [h.label, h.note]),
      ...content.chapters.map((c) => c.title),
    ].filter((t): t is string => !!t);
    for (let i = 0; i < shown.length; i++) {
      assertEquals(isDrugReference(shown[i]), false, `seed ${seed}`);
      for (let j = i + 1; j < shown.length; j++) {
        assertEquals(
          sameLine(shown[i], shown[j]),
          false,
          `seed ${seed}: ${shown[i]} / ${shown[j]}`,
        );
      }
    }
    // Within the longest film, unless every trim is spent.
    assert(
      gvShortestSeconds(content) <=
          WRAP_UP_LIMITS.longestFilmSeconds ||
        content.heroes.length <= MIN_GV_HEROES,
      `seed ${seed}: ${gvShortestSeconds(content)}`,
    );
  }
});
