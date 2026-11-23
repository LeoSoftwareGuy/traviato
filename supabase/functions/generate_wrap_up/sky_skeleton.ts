// Sky Story cut by code (#463, the pattern of Neon's #454 and Golden
// Vows' #458): the film's pages and their photos, decided before the
// director runs — it only picks the words (sky_slots.ts).
//
// - Pages: one per logical day (on #461's local clocks). The film holds
//   as many pages as its limit allows (75 s, and about 4 s a film photo
//   below; never more than MAX_SKY_PAGES). More days than that: the
//   neighbouring days share pages, as evenly as the days allow (#463: a
//   9-day memory is 2 + 2 + 2 + 2 + 1), the arrangement with the fewest
//   photos on its fullest page. A day is never dropped.
// - Pages to spare: a long day in parts at its 2 h breaks while each part
//   keeps SKY_MIN_PART_PHOTOS (the longest break first); then a page with
//   more Always picks than it shows splits in two at its middle (#378's
//   continuation page).
// - Each page: a hero — Always, then captioned, then a photo a note was
//   written on or among, then the hero score — and up to MAX_SKY_EXTRAS
//   more, Always first, then the best shot of each stretch of the page,
//   in time order.
// - The mosaic: every other film photo (decorative.ts), so every photo
//   is on a page or in the closing mosaic.

import type { TripData } from "./gather.ts";
import { decorativePhotos } from "./decorative.ts";
import { tripLogicalDays } from "./logical_day.ts";
import { timeOf } from "./neon_night.ts";
import { noteAnchors, photoRank, spreadPicks } from "./film_slots.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
import { isFilmLengthRuleOn, skyPagesFor } from "./film_length.ts";
import {
  dayNumberOf,
  MAX_SKY_EXTRAS,
  MAX_SKY_MOSAIC_PHOTOS,
  MAX_SKY_PAGES,
  SKY_PAGE_SLOTS,
  skyPhotos,
} from "./sky_story.ts";

type Photo = TripData["photos"][number];

// A part of a long day becomes a page of its own only with this many
// photos: a hero and a few more.
export const SKY_MIN_PART_PHOTOS = 4;
// A break this long inside a day can start a page.
export const SKY_PART_BREAK_MINUTES = 120;
// About this many seconds a film photo at most (#463, Golden Vows' #460).
export const SKY_SECONDS_PER_PHOTO = 4;

export interface SkySkeletonPage {
  // The page's logical days, in order ('YYYY-MM-DD'); several on a page
  // that groups days.
  days: string[];
  // 1 = the memory's first day.
  first_day: number;
  last_day: number;
  // Every film photo of the page, in time order.
  photos: Photo[];
  hero: Photo;
  // Up to MAX_SKY_EXTRAS, in time order.
  extras: Photo[];
  // A part of a day the page shares with another page.
  is_part: boolean;
}

export interface SkySkeleton {
  pages: SkySkeletonPage[];
  // Every film photo on no page, for the closing mosaic.
  mosaic: string[];
  // The film's photos (pages + mosaic).
  photos: Photo[];
  // The most pages its length holds, and the length it was cut for.
  max_pages: number;
  limit_seconds: number;
}

// Sky Story's limit (#463): 75 s, and about 4 s a film photo below.
export function skyLimitSeconds(photos: number): number {
  return Math.min(
    WRAP_UP_LIMITS.longestFilmSeconds,
    SKY_SECONDS_PER_PHOTO * photos,
  );
}

// The most pages a film of [photos] photos holds within its limit (with
// the length rule off in tests: every page).
export function skyPageRoom(photos: number): number {
  if (!isFilmLengthRuleOn()) return MAX_SKY_PAGES;
  return Math.max(
    1,
    Math.min(MAX_SKY_PAGES, skyPagesFor(skyLimitSeconds(photos))),
  );
}

// [count] items in [groups] contiguous runs whose sizes differ by at most
// one: every way to place the longer runs (#463: "evenly").
function evenSplits(count: number, groups: number): number[][] {
  const base = Math.floor(count / groups);
  const longer = count - base * groups;
  const out: number[][] = [];
  const walk = (at: number, left: number, sizes: number[]) => {
    if (sizes.length === groups) {
      if (left === 0) out.push(sizes);
      return;
    }
    const room = groups - sizes.length;
    // The longer runs first: on a tie the earlier days share.
    if (left > 0) walk(at + 1, left - 1, [...sizes, base + 1]);
    if (left < room) walk(at + 1, left, [...sizes, base]);
  };
  walk(0, longer, []);
  return out;
}

// [days] (each its photos, in order) on [pages] pages: evenly by days,
// the arrangement whose fullest page has the fewest photos (the earliest
// such on a tie).
export function groupDaysEvenly<T>(days: T[][], pages: number): T[][][] {
  if (days.length <= pages) return days.map((d) => [d]);
  let best: T[][][] | null = null;
  let bestMax = Infinity;
  for (const sizes of evenSplits(days.length, pages)) {
    const groups: T[][][] = [];
    let at = 0;
    for (const size of sizes) {
      groups.push(days.slice(at, at + size));
      at += size;
    }
    const max = Math.max(...groups.map((g) => g.flat().length));
    if (max < bestMax) {
      best = groups;
      bestMax = max;
    }
  }
  return best!;
}

// The longest break inside [photos] (time order) that leaves
// SKY_MIN_PART_PHOTOS on each side and is at least
// SKY_PART_BREAK_MINUTES, as the index it starts a part at; else null.
function longestBreak(photos: readonly Photo[]):
  | { at: number; gap: number }
  | null {
  let best: { at: number; gap: number } | null = null;
  for (
    let k = SKY_MIN_PART_PHOTOS;
    k <= photos.length - SKY_MIN_PART_PHOTOS;
    k++
  ) {
    const a = timeOf(photos[k - 1]);
    const b = timeOf(photos[k]);
    if (a <= 0 || b <= 0) continue;
    const gap = b - a;
    if (gap >= SKY_PART_BREAK_MINUTES * 60_000 && (!best || gap > best.gap)) {
      best = { at: k, gap };
    }
  }
  return best;
}

// Sky Story's pages of [tripData] (#463). [heroScores]: the photo
// analysis's.
export function buildSkySkeleton(
  tripData: TripData,
  heroScores: Readonly<Record<string, number>> = {},
): SkySkeleton {
  const photos = skyPhotos(tripData);
  const start = tripData.trip.start_date;
  const maxPages = skyPageRoom(photos.length);
  const empty: SkySkeleton = {
    pages: [],
    mosaic: [],
    photos,
    max_pages: maxPages,
    limit_seconds: skyLimitSeconds(photos.length),
  };
  if (!start || photos.length === 0) return empty;

  // By logical day (skyPhotos already put each photo on its own).
  const logical = tripLogicalDays(tripData);
  const dayOf = (p: Photo) => logical.get(p.id) ?? p.day_date!;
  const byDay: Photo[][] = [];
  for (const p of photos) {
    const last = byDay[byDay.length - 1];
    if (last && dayOf(last[0]) === dayOf(p)) last.push(p);
    else byDay.push([p]);
  }

  // A page as its days' photos, and whether it's a part of a day.
  const groups: { photos: Photo[]; part: boolean }[] = groupDaysEvenly(
    byDay,
    maxPages,
  ).map((g) => ({ photos: g.flat(), part: false }));

  // Pages to spare: a long day in parts (only single-day pages).
  while (groups.length < maxPages) {
    let cut: { g: number; at: number; gap: number } | null = null;
    groups.forEach((g, gi) => {
      const days = new Set(g.photos.map(dayOf));
      if (days.size !== 1) return;
      const b = longestBreak(g.photos);
      if (b && (!cut || b.gap > cut.gap)) cut = { g: gi, ...b };
    });
    if (!cut) break;
    const { g, at } = cut as { g: number; at: number; gap: number };
    const whole = groups[g].photos;
    groups.splice(
      g,
      1,
      { photos: whole.slice(0, at), part: true },
      { photos: whole.slice(at), part: true },
    );
  }
  // Still pages to spare: a page with more Always picks than it shows
  // gets a continuation page (#378), the most overflowing first.
  while (groups.length < maxPages) {
    let worst = -1;
    let over = 0;
    groups.forEach((g, gi) => {
      const always = g.photos.filter((p) => p.use_in_wrap_up === true).length;
      if (always - SKY_PAGE_SLOTS > over && g.photos.length >= 2) {
        worst = gi;
        over = always - SKY_PAGE_SLOTS;
      }
    });
    if (worst < 0) break;
    const whole = groups[worst].photos;
    const half = Math.ceil(whole.length / 2);
    groups.splice(
      worst,
      1,
      { photos: whole.slice(0, half), part: true },
      { photos: whole.slice(half), part: true },
    );
  }

  const anchors = noteAnchors(tripData, photos);
  const noteCount = new Map<string, number>();
  for (const [noteId, photoId] of anchors) {
    const own = tripData.notes.find((n) => n.id === noteId)?.photo_id ===
      photoId;
    noteCount.set(photoId, (noteCount.get(photoId) ?? 0) + (own ? 2 : 1));
  }
  const rank = (p: Photo) => photoRank(p, heroScores, noteCount);

  const pages: SkySkeletonPage[] = groups.map(({ photos: own, part }) => {
    const hero = [...own].sort((a, b) =>
      rank(b) - rank(a) || timeOf(a) - timeOf(b)
    )[0];
    const rest = own.filter((p) => p !== hero);
    const extras = spreadPicks(
      rest,
      Math.min(MAX_SKY_EXTRAS, rest.length),
      (p) => rank(p),
    );
    const days = [...new Set(own.map(dayOf))].sort();
    return {
      days,
      first_day: dayNumberOf(start, days[0]),
      last_day: dayNumberOf(start, days[days.length - 1]),
      photos: own,
      hero,
      extras,
      is_part: part,
    };
  });
  const shown = new Set(pages.flatMap((p) => [p.hero, ...p.extras]));
  const mosaic = decorativePhotos(
    photos,
    new Set([...shown].map((p) => p.id)),
    MAX_SKY_MOSAIC_PHOTOS,
  )
    .map((p) => p.id);
  return { ...empty, pages, mosaic };
}
