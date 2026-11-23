// Golden Vows cut by code (#458, Neon's #454 pattern): the album's pages
// and their photos, decided before the director runs — it only picks the
// words (gv_slots.ts).
//
// - Chapters: one per logical day (after midnight stays on the evening),
//   neighbouring days together past MAX_GV_CHAPTERS, a long day in parts
//   at its 2 h breaks while each part keeps GV_MIN_PART_PHOTOS. A chapter
//   is never dropped (#458: that's how Neon lost Brussels), and a short
//   day stays its own (#460): 2 photos are a page of 2 prints, the day's
//   best note its line; no photo shows twice. Only a day of 1 joins its
//   neighbour.
// - Main pages: about one per 7 photos, 2–6, each chapter's best photo
//   first — Always picks, then captioned photos, then the photos the
//   user's notes were written on or among (#460: a note plays on its own
//   photo), then the hero score.
// - Prints: up to 6 per chapter from what its main pages leave (#460),
//   Always first, then the best shot of each stretch of the chapter, in
//   time order — one page of 2–3, or two pages for 4–6.
// - Play order (#460): chapter after chapter; in each, its first page of
//   prints (the heading), then its main pages and its second page of
//   prints by time.
// - The carousel: the photos left, Always first, shown with 6 or more.
// - The heart: every photo (content). Every Always pick is on a page
//   while there is room.
// - The occasion: a wedding, engagement, anniversary or date night only
//   when the notes, captions or photo summaries say so — the word that
//   did is kept for the inspector — else "romance".

import type { TripData } from "./gather.ts";
import { tripLogicalDays } from "./logical_day.ts";
import { spreadEvenly } from "./assemble.ts";
import { filmPhotoIds } from "./film_photos.ts";
import { nearestPhoto, noteTime, SCENE_NEAR_MINUTES } from "./film_slots.ts";
import {
  chapterLayout,
  GV_CHAPTER_PHOTOS,
  type GvLayout,
  type GvOccasion,
  gvPhotos,
  MAX_GV_CAROUSEL,
  MAX_GV_CHAPTER_PRINTS,
  MAX_GV_CHAPTERS,
  MAX_GV_HEROES,
  MIN_GV_CAROUSEL,
  MIN_GV_HEROES,
  MIN_GV_PAGE_PRINTS,
} from "./golden_vows.ts";
import { sameLine, timeOf } from "./neon_night.ts";

type Photo = TripData["photos"][number];

// A part of a long day becomes a chapter of its own only with this many
// photos: its 3 prints and a main page.
export const GV_MIN_PART_PHOTOS = 4;
// A day this small joins its neighbour (#460): one photo.
export const GV_MIN_DAY_PHOTOS = 2;
// A break this long inside a day can start a chapter.
export const GV_PART_BREAK_MINUTES = 120;
// About one main page per this many photos, within 2–6.
// 15 photos → 2, 25 → 4, 40 → 6 (#460: a small album plays quick).
export const GV_PHOTOS_PER_MAIN = 7;

export interface GvSkeletonChapter {
  // Its photos, in time order.
  photos: Photo[];
  // Its logical days, 'YYYY-MM-DD'.
  days: string[];
  // Its prints (2–6), in time order, and their pages: 1 or 2.
  prints: string[];
  pages: { prints: string[]; layout: GvLayout }[];
  // Its first page's arrangement.
  layout: GvLayout;
}

// One page of the album in play order (#460).
export type GvSkeletonPage =
  | { kind: "prints"; chapter: number; page: number }
  | { kind: "main"; main: number };

export interface GvSkeletonMain {
  photo_id: string;
  // The chapter it is from, 0-based.
  chapter: number;
}

// Why code chose the occasion (#458): the word and where it was found.
export interface GvOccasionTrigger {
  word: string;
  source: "note" | "caption" | "photo";
  // The note's or photo's id.
  id: string;
}

export interface GvSkeleton {
  occasion: GvOccasion;
  trigger: GvOccasionTrigger | null;
  chapters: GvSkeletonChapter[];
  // In time order.
  mains: GvSkeletonMain[];
  // In time order; empty below MIN_GV_CAROUSEL.
  carousel: string[];
  // Every chapter's pages and main pages, in the order they play (#460).
  sequence: GvSkeletonPage[];
}

// The words that make a memory a wedding, an engagement, an anniversary
// or a date night (#433: wedding words only when the memory shows one).
// The first occasion with a match wins.
const OCCASION_WORDS: [GvOccasion, RegExp][] = [
  [
    "wedding",
    /(^|[^\p{L}])(wedding|bride|groom|vows|just married|got married|свадьб\p{L}*|невест\p{L}*|жених\p{L}*|венчани\p{L}*|расписал\p{L}*|бракосочетан\p{L}*)(?!\p{L})/iu,
  ],
  [
    "engagement",
    /(^|[^\p{L}])(engaged|engagement|proposal|proposed|she said yes|помолвк\p{L}*|предложение руки|сделал предложение)(?!\p{L})/iu,
  ],
  ["anniversary", /(^|[^\p{L}])(anniversary|годовщин\p{L}*)(?!\p{L})/iu],
  ["date_night", /(^|[^\p{L}])(date night|свидани\p{L}*)(?!\p{L})/iu],
];

// The occasion of [tripData] and what showed it (#458).
export function gvOccasionOf(
  tripData: TripData,
  summaries: ReadonlyMap<string, string> = new Map(),
): { occasion: GvOccasion; trigger: GvOccasionTrigger | null } {
  const texts: {
    text: string;
    source: GvOccasionTrigger["source"];
    id: string;
  }[] = [
    ...tripData.notes.filter((n) => n.id).map((n) => ({
      text: n.content,
      source: "note" as const,
      id: n.id!,
    })),
    ...tripData.photos.filter((p) => p.caption?.trim()).map((p) => ({
      text: p.caption!,
      source: "caption" as const,
      id: p.id,
    })),
    ...[...summaries].map(([id, text]) => ({
      text,
      source: "photo" as const,
      id,
    })),
  ];
  for (const [occasion, words] of OCCASION_WORDS) {
    for (const t of texts) {
      const m = t.text.match(words);
      if (m) {
        return {
          occasion,
          trigger: { word: m[2], source: t.source, id: t.id },
        };
      }
    }
  }
  return { occasion: "romance", trigger: null };
}

// [photos] (time order) as chapters' photo groups (#458): by logical day,
// neighbouring days together past MAX_GV_CHAPTERS, then long days in
// parts at their longest breaks while there's room.
function chapterGroups(
  photos: readonly Photo[],
  days: ReadonlyMap<string, string | null>,
): Photo[][] {
  const groups: Photo[][] = [];
  let day: string | null | undefined;
  for (const p of photos) {
    const d = days.get(p.id) ?? p.day_date;
    if (groups.length === 0 || d !== day) groups.push([]);
    groups[groups.length - 1].push(p);
    day = d;
  }
  // Past the most chapters: the neighbours with the fewest photos join.
  while (groups.length > MAX_GV_CHAPTERS) {
    let best = 0;
    for (let i = 1; i < groups.length - 1; i++) {
      if (
        groups[i].length + groups[i + 1].length <
          groups[best].length + groups[best + 1].length
      ) best = i;
    }
    groups.splice(best, 2, [...groups[best], ...groups[best + 1]]);
  }
  // A long day in parts, the longest break first.
  while (groups.length < MAX_GV_CHAPTERS) {
    let cut: { g: number; at: number; gap: number } | null = null;
    groups.forEach((g, gi) => {
      for (
        let k = GV_MIN_PART_PHOTOS;
        k <= g.length - GV_MIN_PART_PHOTOS;
        k++
      ) {
        const gap = timeOf(g[k]) - timeOf(g[k - 1]);
        if (
          gap >= GV_PART_BREAK_MINUTES * 60_000 &&
          timeOf(g[k - 1]) > 0 && (!cut || gap > cut.gap)
        ) cut = { g: gi, at: k, gap };
      }
    });
    if (!cut) break;
    const { g, at } = cut as { g: number; at: number; gap: number };
    groups.splice(g, 1, groups[g].slice(0, at), groups[g].slice(at));
  }
  // Too few photos for a main page and 2 prints: into the neighbour,
  // never lost.
  for (let i = 0; i < groups.length && groups.length > 1;) {
    if (groups[i].length >= GV_MIN_DAY_PHOTOS) {
      i++;
      continue;
    }
    const into = i === 0 ? 1 : i === groups.length - 1 ||
        groups[i - 1].length <= groups[i + 1].length
      ? i - 1
      : i + 1;
    const merged = into < i
      ? [...groups[into], ...groups[i]]
      : [...groups[i], ...groups[into]];
    groups.splice(Math.min(i, into), 2, merged);
    i = 0;
  }
  return groups;
}

// How a photo ranks for a main page (#458): Always, then captioned, then
// one a note was written on or among ([withNote], #460: a main page shows
// a note), then its hero score. Higher is better.
export function gvRank(
  p: Photo,
  heroScores: Readonly<Record<string, number>>,
  withNote: ReadonlySet<string> | ReadonlyMap<string, number> = new Set(),
): number {
  // The more notes belong to it, the better (#460), up to 3 (a note
  // written on it counts 2).
  const notes = withNote instanceof Map
    ? Math.min(3, withNote.get(p.id) ?? 0)
    : withNote.has(p.id)
    ? 1
    : 0;
  return (p.use_in_wrap_up === true ? 100 : 0) +
    (p.caption?.trim() ? 20 : 0) + 10 * notes + (heroScores[p.id] ?? 0);
}

// The photos the notes belong to (#460): a note's own photo, else the
// film photo taken nearest when it was written, within
// SCENE_NEAR_MINUTES. A note written far from every photo anchors none.
export function noteAnchors(
  tripData: TripData,
  photos: readonly Photo[],
): Map<string, string> {
  const anchors = new Map<string, string>();
  const ids = new Set(photos.map((p) => p.id));
  for (const n of tripData.notes) {
    if (!n.id || !n.content.trim()) continue;
    if (n.photo_id && ids.has(n.photo_id)) {
      anchors.set(n.id, n.photo_id);
      continue;
    }
    const near = nearestPhoto(photos, noteTime(n));
    if (
      near &&
      Math.abs(timeOf(near) - noteTime(n)) <= SCENE_NEAR_MINUTES * 60_000
    ) anchors.set(n.id, near.id);
  }
  return anchors;
}

// [n] prints as pages (#460): 2–3 on one page, 4 as 2 + 2, 5 as 3 + 2,
// 6 as 3 + 3.
function pageSizes(n: number): number[] {
  return n <= GV_CHAPTER_PHOTOS ? [n] : [Math.ceil(n / 2), Math.floor(n / 2)];
}

// [count] of [photos] (time order) for a page of prints: Always picks
// first, then the best shot of each equal stretch of the rest; in time
// order.
function printsOf(
  photos: readonly Photo[],
  count: number,
  score: (p: Photo) => number,
): Photo[] {
  // The best of each stretch of [list], [room] of them.
  const spread = (list: readonly Photo[], room: number, picked: Photo[]) => {
    for (let k = 0; k < room && list.length > 0; k++) {
      const from = Math.floor(k * list.length / room);
      const to = Math.max(from + 1, Math.floor((k + 1) * list.length / room));
      const best = list.slice(from, to).filter((p) => !picked.includes(p))
        .sort((x, y) => score(y) - score(x))[0];
      if (best) picked.push(best);
    }
  };
  const always = photos.filter((p) => p.use_in_wrap_up === true);
  const picked: Photo[] = [];
  // More Always picks than room (#460): spread over the chapter too, not
  // its first ones.
  if (always.length >= count) spread(always, count, picked);
  else {
    picked.push(...always);
    spread(
      photos.filter((p) => !always.includes(p)),
      count - always.length,
      picked,
    );
  }
  return photos.filter((p) => picked.includes(p));
}

// The album of [tripData] (#458): every page and its photos.
export function buildGvSkeleton(
  tripData: TripData,
  heroScores: Readonly<Record<string, number>> = {},
  orientations: Readonly<Record<string, string>> = {},
  summaries: ReadonlyMap<string, string> = new Map(),
): GvSkeleton {
  // The film's photos (at most maxFilmPhotos, Always picks kept).
  const film = new Set(filmPhotoIds(tripData, heroScores));
  const photos = gvPhotos(tripData).filter((p) => film.has(p.id))
    .sort((a, b) => timeOf(a) - timeOf(b));
  const days = tripLogicalDays(tripData);
  const groups = chapterGroups(photos, days);
  const { occasion, trigger } = gvOccasionOf(tripData, summaries);

  // Main pages: about one per GV_PHOTOS_PER_MAIN photos, within 2–6
  // (#460: they scale with the album, not with its chapters or notes),
  // each chapter keeping 2 prints; a note without a main page plays on
  // its page of prints.
  // A note written on the photo counts twice: it beats one only written
  // near it.
  const anchored = new Map<string, number>();
  const ownPhoto = new Map(tripData.notes.map((n) => [n.id, n.photo_id]));
  for (const [note, id] of noteAnchors(tripData, photos)) {
    const weight = ownPhoto.get(note) === id ? 2 : 1;
    anchored.set(id, (anchored.get(id) ?? 0) + weight);
  }
  // A 2-photo day is its page of 2 prints alone (#460: no photo twice).
  const spare = groups.map((g) => g.length - MIN_GV_PAGE_PRINTS);
  const count = Math.min(
    MAX_GV_HEROES,
    Math.max(MIN_GV_HEROES, Math.round(photos.length / GV_PHOTOS_PER_MAIN)),
    spare.reduce((s, n) => s + Math.max(0, n), 0),
  );
  const withNote = anchored;
  const rank = (p: Photo) => gvRank(p, heroScores, withNote);
  // A main page plays its caption: two pages never the same caption — a
  // repeat stays a print or on the carousel.
  // "The same" as the album's own check (#460): "Café de Klos" and "Ribs
  // at Café de Klos" too.
  const repeated = new Set<string>();
  const captions: string[] = [];
  for (const p of [...photos].sort((a, b) => rank(b) - rank(a))) {
    const c = p.caption?.trim();
    if (!c) continue;
    if (captions.some((k) => sameLine(k, c))) repeated.add(p.id);
    else captions.push(c);
  }
  const ranked = groups.map((g) =>
    [...g].filter((p) => !repeated.has(p.id)).sort((a, b) => rank(b) - rank(a))
  );
  // Each chapter's best photo first, then the best of the rest wherever
  // they are (#460: a photo a note belongs to beats a chapter's turn).
  const mains: GvSkeletonMain[] = [];
  const firsts = groups.map((_, i) => i).filter((i) =>
    spare[i] > 0 && ranked[i].length > 0
  ).sort((a, b) => rank(ranked[b][0]) - rank(ranked[a][0]));
  for (const i of firsts.slice(0, count)) {
    mains.push({ photo_id: ranked[i][0].id, chapter: i });
  }
  const rest = groups.flatMap((_, i) =>
    ranked[i].slice(1, Math.max(1, spare[i])).map((p) => ({ p, i }))
  ).sort((a, b) => rank(b.p) - rank(a.p));
  for (const { p, i } of rest) {
    if (mains.length >= count) break;
    mains.push({ photo_id: p.id, chapter: i });
  }
  const main = new Set(mains.map((m) => m.photo_id));
  const order = new Map(photos.map((p, i) => [p.id, i]));
  mains.sort((a, b) => order.get(a.photo_id)! - order.get(b.photo_id)!);

  const chapters: GvSkeletonChapter[] = groups.map((g, i) => {
    const rest = g.filter((p) => !main.has(p.id));
    const prints = printsOf(
      rest,
      Math.min(MAX_GV_CHAPTER_PRINTS, rest.length),
      rank,
    ).map((p) => p.id);
    let at = 0;
    const pages = pageSizes(prints.length).map((n, k) => {
      const ids = prints.slice(at, at += n);
      return { prints: ids, layout: chapterLayout(ids, orientations, i + k) };
    });
    return {
      photos: g,
      days: [
        ...new Set(
          g.map((p) => days.get(p.id) ?? p.day_date).filter((
            d,
          ): d is string => !!d),
        ),
      ].sort(),
      prints,
      pages,
      layout: pages[0]?.layout ?? "B2",
    };
  });

  // The play order (#460): each chapter's heading page, then its main
  // pages and its second page by their first photo's time.
  const at = (id: string) => order.get(id) ?? 0;
  const sequence: GvSkeletonPage[] = [];
  chapters.forEach((c, i) => {
    if (c.pages.length > 0) {
      sequence.push({ kind: "prints", chapter: i, page: 0 });
    }
    const rest: { at: number; page: GvSkeletonPage }[] = [
      ...mains.flatMap((m, k) =>
        m.chapter === i
          ? [{ at: at(m.photo_id), page: { kind: "main" as const, main: k } }]
          : []
      ),
      ...c.pages.slice(1).map((p, k) => ({
        at: at(p.prints[0]),
        page: { kind: "prints" as const, chapter: i, page: k + 1 },
      })),
    ];
    for (const r of rest.sort((a, b) => a.at - b.at)) sequence.push(r.page);
  });

  // The carousel: the photos left, Always first, the rest spread.
  const used = new Set([...main, ...chapters.flatMap((c) => c.prints)]);
  const left = photos.filter((p) => !used.has(p.id));
  const always = left.filter((p) => p.use_in_wrap_up === true)
    .slice(0, MAX_GV_CAROUSEL);
  const picked = new Set([
    ...always,
    ...spreadEvenly(
      left.filter((p) => p.use_in_wrap_up !== true),
      MAX_GV_CAROUSEL - always.length,
    ),
  ]);
  const carousel = left.filter((p) => picked.has(p)).map((p) => p.id);
  return {
    occasion,
    trigger,
    chapters,
    mains,
    carousel: carousel.length >= MIN_GV_CAROUSEL ? carousel : [],
    sequence,
  };
}
