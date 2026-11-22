// Neon Night (#363, phase 9): the beat-synced party film, stored as
// wrap_ups.content.neon_night next to everything the other films read.
//
// Since #454 code builds the whole film — chapters by day and part, the
// photos of every scene, its length — and the director only picks the
// words from code's candidates (neon_slots.ts); neon_film.ts puts it
// together. This file holds what both share: the chapter starts, the
// dealing of a chapter's photos, the content's shape and the text rules.
// What code fills in, never the AI: the plan rows (the user's quests with
// times), every photo and its time, the totals, the signature.

import type { TripData } from "./gather.ts";
import { sortPhotosChronologically, spreadEvenly } from "./assemble.ts";
import { tripLogicalDays } from "./logical_day.ts";

export const NN_VERSION = 1;

export const NN_MOMENT_TYPES = ["split", "burst", "timeline", "peak"] as const;
export type NnMomentType = typeof NN_MOMENT_TYPES[number];

// Photos per moment, as [min, max] (NEON_NIGHT_SPEC.md §7).
export const NN_MOMENT_PHOTOS: Record<NnMomentType, [number, number]> = {
  split: [2, 4],
  burst: [2, 4],
  timeline: [2, 8],
  peak: [3, 5],
};

// What the director may plan (#386): no peak — its tapered strips looked
// bad. Peaks in plans made before still check; the content turns them
// into a moment that fits (contentMoments).
export const PLANNED_NN_MOMENT_TYPES = ["split", "burst", "timeline"] as const;

// A timeline is filled up to this many photos from its chapter's unused
// ones (#386): its two columns looked empty with 3.
export const NN_TIMELINE_FILL = 6;

export const MIN_NN_CHAPTERS = 1;
export const MAX_NN_CHAPTERS = 5;
export const MAX_NN_MOMENTS = 2;
// The heart shows about 220 tiles; more photos are sampled evenly.
export const MAX_NN_PHOTOS = 200;
// Photos the moments can show at most: every chapter's moments at their
// largest (a timeline's 8).
export const MAX_NN_MOMENT_SLOTS = MAX_NN_CHAPTERS * MAX_NN_MOMENTS * 8;

// Lengths the film's type fits at its sizes.
export const MAX_NN_TITLE_CHARS = 22;
export const MAX_NN_HEADLINE_CHARS = 18;
// A card's typed line wraps to at most 2 lines (mono 40 over 936 px: ~39
// a line, "> " included). 72 since #456, so a line of the card's own
// photos ("Сидим в баре скоро принесут полтора метра ребер…", 63) fits.
export const MAX_NN_CARD_NOTE_CHARS = 72;
// The note scene: up to 5 lines of about 18 characters.
export const MAX_NN_NOTE_CHARS = 90;

type Photo = TripData["photos"][number];

export interface NeonNightContentExcerpt {
  text: string;
  note_id: string;
  // The photo it plays over; null = the app picks.
  photo_id: string | null;
  // director: chosen by the director; code: picked by the score.
  source: "director" | "code";
  score: number;
}

export interface NeonNightContent {
  nn_version: typeof NN_VERSION;
  // The memory's name (the app shows it in capitals) and first day.
  title: string;
  start_date: string | null;
  place: string | null;
  // The user's quests with a time, in order: "Tonight's plan".
  plan: { time: string; title: string; done: boolean }[];
  chapters: {
    title: string;
    // Chronological; taken_at is an ISO instant the app shows in local
    // time.
    photos: {
      id: string;
      taken_at: string;
      caption: string | null;
      hero_score?: number | null;
    }[];
    // The card's own photos (#390): its grid and zooms, never a moment's.
    // Older content has none — the app then uses every chapter photo.
    card_photo_ids: string[];
    // The card's typed line (#448: the chapter's best excerpt), or null.
    note: string | null;
    // How many photos the card zooms (#448); absent in older content = 2.
    card_zooms?: number;
    // The chapter's lines (#398), in time order, each over its photo:
    // the card types the first, the note moments play them (#416).
    // Older content has none.
    excerpts: NeonNightContentExcerpt[];
    // The chapter's logical days, 'YYYY-MM-DD' (#398 R1).
    days: string[];
    // What code weighed and left (inspector): the best rejected lines.
    rejected_excerpts: { text: string; score: number }[];
    moments: {
      type: NnMomentType;
      photo_ids: string[];
      // A split's label: the first photo's place, when tagged.
      place: string | null;
      // The words it shows, on their photos (#448); absent = every
      // photo's caption or line.
      words?: { photo_id: string; text: string }[];
    }[];
  }[];
  note: {
    text: string;
    // Its place among the memory's notes, from 1: "NOTE 04".
    number: number;
    written_at: string | null;
    photo_id: string | null;
  } | null;
  headline: string | null;
  first_name: string | null;
  totals: { photos: number; notes: number; ticks: number; moments: number };
  // The Finale's heart (#378): the photos without a moment of their own,
  // Always picks only to top it up. Older content has none — the app then
  // uses every chapter photo.
  heart_photo_ids: string[];
}

// --- Where the chapters start -------------------------------------------

export interface NnCheckContext {
  // Chronological index of every photo the section may use.
  photoOrder: ReadonlyMap<string, number>;
  excludedIds: ReadonlySet<string>;
  // "Always" picks (#294): each in a moment (#378).
  mustIncludeIds: ReadonlySet<string>;
  notes: ReadonlyMap<string, string>;
  // Each photo's logical day (#398 R1), 'YYYY-MM-DD'; absent = unknown.
  photoDays?: ReadonlyMap<string, string>;
  // Each photo's tagged place: a title for a day the director folded.
  photoPlaces?: ReadonlyMap<string, string>;
  // Each timed photo's local wall-clock time as UTC millis (#426): where
  // a long day breaks into parts. Untimed photos are absent.
  photoTimes?: ReadonlyMap<string, number>;
  // note id → its logical day (#448: titles from a part's notes).
  noteDays?: ReadonlyMap<string, string>;
  // note id → when it was written, on the phone's clock (ms).
  noteTimes?: ReadonlyMap<string, number>;
  // Each photo's caption (#448: a part's title from the user's words).
  photoCaptions?: ReadonlyMap<string, string>;
}

// Every photo's and note's logical day (#398 R1); notes as `note:<id>`.
export const nnLogicalDays = tripLogicalDays;

// The days the film's photos fall on, in order, each with the index of
// its first photo; [photoDays] maps a photo to its day.
function dayStarts(
  photoOrder: ReadonlyMap<string, number>,
  photoDays: ReadonlyMap<string, string> | undefined,
): { day: string; start: number }[] {
  if (!photoDays) return [];
  const ordered = [...photoOrder.entries()].sort((a, b) => a[1] - b[1]);
  const starts: { day: string; start: number }[] = [];
  for (const [id, at] of ordered) {
    const day = photoDays.get(id);
    if (day === undefined) continue;
    if (starts.length === 0 || starts[starts.length - 1].day !== day) {
      starts.push({ day, start: at });
    }
  }
  return starts;
}

// A day needs this many photos for a chapter of its own (#433): fewer
// can't make a moment, so the day joins its neighbour instead of the film
// failing.
export const MIN_NN_DAY_PHOTOS = 2;

// [days] with each day of fewer than MIN_NN_DAY_PHOTOS photos joined to
// the day before (the first one to the day after). [total] is the photo
// count, where the last day ends.
function mergeSmallDays(
  days: { day: string; start: number }[],
  total: number,
): { day: string; start: number }[] {
  const out = [...days];
  for (let k = 0; k < out.length && out.length > 1;) {
    const end = out[k + 1]?.start ?? total;
    if (end - out[k].start >= MIN_NN_DAY_PHOTOS) {
      k++;
      continue;
    }
    if (k === 0) {
      out.splice(1, 1);
    } else {
      out.splice(k, 1);
    }
  }
  return out;
}

// Where the chapters of a several-day memory must start (#398 R1): each
// day's first photo, neighbouring days grouped evenly when there are more
// than MAX_NN_CHAPTERS. Empty for a single day: the director splits it.
export function dayChapterStarts(context: NnCheckContext): number[] {
  const days = mergeSmallDays(
    dayStarts(context.photoOrder, context.photoDays),
    context.photoOrder.size,
  );
  if (days.length <= 1) return [];
  if (days.length <= MAX_NN_CHAPTERS) return days.map((d) => d.start);
  const starts: number[] = [];
  for (let g = 0; g < MAX_NN_CHAPTERS; g++) {
    starts.push(days[Math.floor(g * days.length / MAX_NN_CHAPTERS)].start);
  }
  return starts;
}

// A day of a several-day memory breaks into parts at a gap of this long
// or more (#426), each part with at least MIN_NN_PART_PHOTOS photos, so a
// chapter is one stretch of the day: arriving, the evening, the rave.
export const NN_PART_GAP_MS = 2 * 60 * 60 * 1000;
export const MIN_NN_PART_PHOTOS = 4;

// Where the chapters of a several-day memory start (#398 R1, #426): each
// day's first photo, then — while there are fewer than MAX_NN_CHAPTERS —
// the longest gaps within a day (NN_PART_GAP_MS or more) that leave each
// side at least MIN_NN_PART_PHOTOS. A chapter never crosses a day. Empty
// for a single day: the director splits it.
export function nnChapterStarts(context: NnCheckContext): number[] {
  const starts = dayChapterStarts(context);
  if (starts.length === 0 || starts.length >= MAX_NN_CHAPTERS) return starts;
  const times = context.photoTimes;
  if (!times) return starts;
  const ordered = [...context.photoOrder.entries()].sort((a, b) => a[1] - b[1])
    .map(([id]) => id);
  const days = context.photoDays;
  const gaps: { at: number; gap: number }[] = [];
  for (let k = 1; k < ordered.length; k++) {
    const a = times.get(ordered[k - 1]);
    const b = times.get(ordered[k]);
    if (a === undefined || b === undefined) continue;
    if (days?.get(ordered[k - 1]) !== days?.get(ordered[k])) continue;
    if (b - a >= NN_PART_GAP_MS) gaps.push({ at: k, gap: b - a });
  }
  gaps.sort((x, y) => y.gap - x.gap || x.at - y.at);
  const parts = [...starts];
  for (const { at } of gaps) {
    if (parts.length >= MAX_NN_CHAPTERS) break;
    const sorted = [...parts].sort((x, y) => x - y);
    const from = [...sorted].reverse().find((s) => s < at)!;
    const to = sorted.find((s) => s > at) ?? ordered.length;
    if (at - from >= MIN_NN_PART_PHOTOS && to - at >= MIN_NN_PART_PHOTOS) {
      parts.push(at);
    }
  }
  return parts.sort((x, y) => x - y);
}

// Photos the film may show, chronological: not left out.
export function nnPhotos(tripData: TripData): Photo[] {
  return sortPhotosChronologically(
    tripData.photos.filter((p) => p.use_in_wrap_up !== false),
  );
}

export function nnCheckContext(
  tripData: TripData,
  notRequiredIds: ReadonlySet<string> = new Set(),
): NnCheckContext {
  const photos = nnPhotos(tripData);
  return {
    photoOrder: new Map(photos.map((p, i) => [p.id, i])),
    excludedIds: new Set(
      tripData.photos.filter((p) => p.use_in_wrap_up === false).map((p) =>
        p.id
      ),
    ),
    mustIncludeIds: new Set(
      photos.filter((p) =>
        p.use_in_wrap_up === true && !notRequiredIds.has(p.id)
      ).map((p) => p.id),
    ),
    notes: new Map(
      tripData.notes.filter((n) => n.id).map((n) => [n.id!, n.content]),
    ),
    photoDays: (() => {
      const days = nnLogicalDays(tripData);
      const map = new Map<string, string>();
      for (const p of photos) {
        const day = days.get(p.id);
        if (day) map.set(p.id, day);
      }
      return map;
    })(),
    photoPlaces: new Map(
      photos.filter((p) => p.place_text?.trim()).map((
        p,
      ) => [p.id, p.place_text!]),
    ),
    photoTimes: new Map(
      photos.filter((p) => p.taken_at).map((p) => [
        p.id,
        Date.parse(p.taken_at!) + (tripData.utc_offset_minutes ?? 0) * 60_000,
      ]),
    ),
    noteDays: (() => {
      const days = nnLogicalDays(tripData);
      const map = new Map<string, string>();
      for (const n of tripData.notes) {
        const day = n.id ? days.get(`note:${n.id}`) ?? n.day_date : null;
        if (n.id && day) map.set(n.id, day);
      }
      return map;
    })(),
    photoCaptions: new Map(
      photos.filter((p) => p.caption?.trim()).map((p) => [
        p.id,
        p.caption!.trim(),
      ]),
    ),
    noteTimes: new Map(
      tripData.notes.filter((n) => n.id && !n.legacy && n.taken_at).map((
        n,
      ) => [
        n.id!,
        Date.parse(n.taken_at!) + (tripData.utc_offset_minutes ?? 0) * 60_000,
      ]),
    ),
  };
}

// --- A single night's parts ----------------------------------------------

// A single night's chapters, when code plans it: parts split at the
// longest breaks of NN_PART_GAP_MS or more, each keeping at least this
// many photos, up to this many chapters.
const CODE_NN_PART_PHOTOS = 8; // MIN_NN_CHAPTER_PHOTOS
const CODE_NN_MAX_PARTS = 3;

// Where a single night's chapters start when code plans it.
export function singleNightStarts(context: NnCheckContext, ordered: string[]) {
  const times = context.photoTimes;
  const gaps: { at: number; gap: number }[] = [];
  for (let k = 1; k < ordered.length && times; k++) {
    const a = times.get(ordered[k - 1]);
    const b = times.get(ordered[k]);
    if (a !== undefined && b !== undefined && b - a >= NN_PART_GAP_MS) {
      gaps.push({ at: k, gap: b - a });
    }
  }
  gaps.sort((x, y) => y.gap - x.gap || x.at - y.at);
  const starts = [0];
  for (const { at } of gaps) {
    if (starts.length >= CODE_NN_MAX_PARTS) break;
    const sorted = [...starts].sort((x, y) => x - y);
    const from = [...sorted].reverse().find((x) => x < at)!;
    const to = sorted.find((x) => x > at) ?? ordered.length;
    if (at - from >= CODE_NN_PART_PHOTOS && to - at >= CODE_NN_PART_PHOTOS) {
      starts.push(at);
    }
  }
  return starts.sort((x, y) => x - y);
}

// The memory's best line of all for the Note scene: specific, nothing

export interface EnsuredSection<T> {
  plan: T;
  // director: the director's section, repaired; code: built by code.
  source: "director" | "code";
  // What was wrong and put right, for the Plan inspector.
  repairs: string[];
}

// --- Building content.neon_night -----------------------------------------

// 'HH:MM:SS' or 'HH:MM' → 'HH:MM'; anything else → null.
function clockOf(time: string | null | undefined): string | null {
  const m = /^(\d{2}):(\d{2})/.exec(time ?? "");
  return m ? `${m[1]}:${m[2]}` : null;
}

export function planRows(tripData: TripData): NeonNightContent["plan"] {
  const rows: NeonNightContent["plan"] = [];
  for (const quest of tripData.quests ?? []) {
    const time = clockOf(quest.time);
    if (!time || !quest.title.trim()) continue;
    rows.push({
      time,
      title: quest.title.trim(),
      done: quest.completed_at !== null,
    });
  }
  // A plan of one or two rows isn't worth a scene (#390).
  return rows.length >= MIN_NN_PLAN_ROWS ? rows : [];
}

// The film's photos: all of them up to MAX_NN_PHOTOS, else an even spread
// that still keeps every photo the plan names; chronological.
export function filmPhotos(
  photos: Photo[],
  named: ReadonlySet<string>,
): Photo[] {
  if (photos.length <= MAX_NN_PHOTOS) return photos;
  const kept = new Set([
    ...photos.filter((p) => named.has(p.id)),
    ...spreadEvenly(photos, MAX_NN_PHOTOS),
  ]);
  return photos.filter((p) => kept.has(p));
}

export type ContentMoment = { type: NnMomentType; photo_ids: string[] };

// A chapter as code deals it: its shown photos, its card and moments.
export interface DealtChapter {
  photos: Photo[];
  card: string[];
  moments: ContentMoment[];
}

// A chapter is merged into a neighbour while it has fewer photos (#390):
// fewer, fuller scenes rather than half-empty ones.
export const MIN_NN_CHAPTER_PHOTOS = 8;
// The card's own photos, up to one row of heroes (#390).
export const MAX_NN_CARD_PHOTOS = 4;
// A timeline under this many photos plays as a split or burst (#390).
export const MIN_NN_TIMELINE_PHOTOS = 5;
// The Plan scene needs this many rows (#390).
export const MIN_NN_PLAN_ROWS = 3;

// A chapter's card: its first photos in time (#444), 4 — 5 from
// NN_CARD_FIVE photos, 6 from NN_CARD_SIX — so its grid is always full.
export const MIN_NN_CARD_PHOTOS = 4;
const NN_CARD_FIVE = 12;
const NN_CARD_SIX = 14;
// A split or burst shows 3–4 photos (#444, was 2–4).
export const NN_SCENE_PHOTOS: [number, number] = [3, 4];
// A moment's type from its photos' time spread (#444): within
// NN_BURST_SPREAD_MS a burst, within NN_SPLIT_SPREAD_MS a split, else
// (or from 5 photos) a timeline.
export const NN_BURST_SPREAD_MS = 2 * 60 * 1000;
export const NN_SPLIT_SPREAD_MS = 10 * 60 * 1000;
// A chapter gets a second moment when this many photos are left after
// its card.
export const NN_TWO_MOMENTS_FROM = 6;
// A dealt timeline shows at most this many photos (#448: a scene stays
// under ~12 s); more go to the chapter's other moment or the heart.
export const NN_TIMELINE_ROOM = 6;

export function timeOf(p: Photo): number {
  return Date.parse(p.taken_at ?? p.created_at ?? "") || 0;
}

// The moment [photos] (time order, 3 or more) play as (#444). Past a
// timeline's 8, the best photos stay (#446) — Always picks, then captioned
// ones (the user's own words, as the zooms rank them), then the highest
// [heroScores], an even spread breaking ties — so the heart gets the
// lowest-rated, never just the last in time.
export function momentFor(
  photos: Photo[],
  heroScores: Readonly<Record<string, number>> = {},
): ContentMoment {
  const room = NN_TIMELINE_ROOM;
  if (photos.length > NN_SCENE_PHOTOS[1]) {
    const spread = new Set(spreadEvenly(photos, room).map((p) => p.id));
    const rank = (p: Photo) =>
      (p.use_in_wrap_up === true ? 1000 : 0) +
      (p.caption?.trim() ? 100 : 0) +
      (heroScores[p.id] ?? 0) * 10 +
      (spread.has(p.id) ? 1 : 0);
    const kept = new Set(
      [...photos].sort((a, b) => rank(b) - rank(a)).slice(0, room).map((p) =>
        p.id
      ),
    );
    return {
      type: "timeline",
      photo_ids: photos.filter((p) => kept.has(p.id)).map((p) => p.id),
    };
  }
  const spread = timeOf(photos[photos.length - 1]) - timeOf(photos[0]);
  return {
    // Hours apart but only 3–4 photos: a split too — a timeline of 3–4
    // leaves its columns half empty (#390).
    type: spread <= NN_BURST_SPREAD_MS ? "burst" : "split",
    photo_ids: photos.map((p) => p.id),
  };
}

// Where [photos] (time order) split into two runs: at the longest gap
// that leaves each side NN_SCENE_PHOTOS[0], and — when the photos allow —
// no side past a timeline's room, so none is left out.
function splitAtGap(photos: Photo[]): number {
  const min = NN_SCENE_PHOTOS[0];
  const room = NN_TIMELINE_ROOM;
  const fits = photos.length <= 2 * room;
  let at = Math.floor(photos.length / 2);
  let best = -1;
  for (let k = min; k <= photos.length - min; k++) {
    if (fits && (k > room || photos.length - k > room)) continue;
    // More than both hold: each side fills its moment (#448).
    if (!fits && (k < room || photos.length - k < room)) continue;
    const gap = timeOf(photos[k]) - timeOf(photos[k - 1]);
    if (gap > best) {
      best = gap;
      at = k;
    }
  }
  return at;
}

// Deals [chapter]'s photos in time order (#444), whatever the director's
// moments said: the card takes the first 4–6, the rest make one moment —
// two from NN_TWO_MOMENTS_FROM, split at the longest gap — each typed by
// its time spread. A chapter too small for both shows its photos on the
// card alone. The note scene's photo is left out.
// Photos past a moment's room go to the heart.
export function dealChapter(
  chapter: DealtChapter,
  notePhoto: string | null,
  heroScores: Readonly<Record<string, number>> = {},
): void {
  const photos = chapter.photos.filter((p) => p.id !== notePhoto);
  const pool = photos.length >= NN_SCENE_PHOTOS[0] ? photos : chapter.photos;
  const n = pool.length;
  const cardSize = n >= NN_CARD_SIX
    ? 6
    : n >= NN_CARD_FIVE
    ? 5
    : n >= MIN_NN_CARD_PHOTOS + NN_SCENE_PHOTOS[0]
    ? MIN_NN_CARD_PHOTOS
    : Math.min(n, 6);
  // Up to 4 photos: one full card of them all, no moment. 5–6 (#448 — not
  // a slideshow of cards): a card of 3 and a moment of the rest. A
  // captioned photo sits on a card unzoomed when its caption is too long;
  // it never pulls photos off the card (#448).
  if (n <= MIN_NN_CARD_PHOTOS) {
    chapter.card = pool.map((p) => p.id);
    chapter.moments = [];
    return;
  }
  if (n < MIN_NN_CARD_PHOTOS + NN_SCENE_PHOTOS[0]) {
    chapter.card = pool.slice(0, 3).map((p) => p.id);
    chapter.moments = [momentFor(pool.slice(3), heroScores)];
    return;
  }
  chapter.card = pool.slice(0, cardSize).map((p) => p.id);
  const rest = pool.slice(cardSize);
  if (rest.length >= NN_TWO_MOMENTS_FROM) {
    const at = splitAtGap(rest);
    chapter.moments = [
      momentFor(rest.slice(0, at), heroScores),
      momentFor(rest.slice(at), heroScores),
    ];
  } else {
    chapter.moments = [momentFor(rest, heroScores)];
  }
}

// At most this many photos of a moment show words (#448): lines and
// captions; the others play with no label.
export const MAX_NN_MOMENT_WORDS = 3;
// A moment's words fit this long a scene (#448).
export const MAX_NN_SCENE_SECONDS = 12;

// [text] without a trailing comma, semicolon, colon or dash (#450:
// "…позавтракали,"); a line still ends as the user wrote it otherwise.
export function tidyEnd(text: string | null): string | null {
  return text === null ? null : text.replace(/[\s,;:—–-]+$/u, "");
}

// Whether two lines are the same words (#448: no line twice), ignoring
// case, spacing and punctuation; or one is most of the other.
export function sameLine(a: string, b: string): boolean {
  const norm = (t: string) =>
    t.toLowerCase().replace(/ё/g, "е").replace(/[^\p{L}\p{N}]+/gu, " ")
      .trim();
  const x = norm(a);
  const y = norm(b);
  if (x.length === 0 || y.length === 0) return false;
  // One inside the other and most of it: a title of a few words inside a
  // long line is its own (#448: "Брюссель" over "Брюссель не меняется…").
  const [short, long] = x.length <= y.length ? [x, y] : [y, x];
  return long.includes(short) && short.length >= 0.6 * long.length;
}

// Whether [a] and [b] show the same words (#448): [sameLine], or the
// shorter (3 words at least) is inside the longer — a card's clause of a
// line a moment plays whole.
export function overlaps(a: string, b: string): boolean {
  const norm = (t: string) =>
    t.toLowerCase().replace(/ё/g, "е").replace(/[^\p{L}\p{N}]+/gu, " ").trim();
  const [short, long] = norm(a).length <= norm(b).length
    ? [norm(a), norm(b)]
    : [norm(b), norm(a)];
  return sameLine(a, b) ||
    (short.split(" ").length >= 3 && ` ${long} `.includes(` ${short} `));
}

// Whether [text] repeats [title] (#448): the same words, or it opens
// with them ("Домой пришли в 8 утра, ноги…" under "Домой пришли в 8 утра").
export function repeatsTitle(text: string, title: string | null): boolean {
  if (!title) return false;
  const norm = (t: string) =>
    t.toLowerCase().replace(/ё/g, "е").replace(/[^\p{L}\p{N}]+/gu, " ").trim();
  // A title of a word or two (a place: "Брюссель") may open a line.
  return sameLine(text, title) ||
    (norm(title).split(" ").length >= 3 && norm(text).startsWith(norm(title)));
}
