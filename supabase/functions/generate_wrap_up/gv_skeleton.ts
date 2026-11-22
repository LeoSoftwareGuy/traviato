// Golden Vows cut by code (#458, Neon's #454 pattern): the album's pages
// and their photos, decided before the director runs — it only picks the
// words (gv_slots.ts).
//
// - Chapters: one per logical day (after midnight stays on the evening),
//   neighbouring days together past MAX_GV_CHAPTERS, a long day in parts
//   at its 2 h breaks while each part keeps GV_MIN_PART_PHOTOS. A chapter
//   is never dropped (#458: that's how Neon lost Brussels); one with too
//   few photos for its prints joins its neighbour.
// - Main pages: 2–6, spread over the chapters, each chapter's best photo
//   first — Always picks, then captioned photos, then photos with a note
//   on them, then the hero score.
// - Prints: 3 per chapter from what its main pages leave, Always first,
//   then the best shot of each stretch of the chapter, in time order.
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
import {
  chapterLayout,
  GV_CHAPTER_PHOTOS,
  type GvLayout,
  type GvOccasion,
  gvPhotos,
  MAX_GV_CAROUSEL,
  MAX_GV_CHAPTERS,
  MAX_GV_HEROES,
  MIN_GV_CAROUSEL,
  MIN_GV_HEROES,
} from "./golden_vows.ts";
import { timeOf } from "./neon_night.ts";

type Photo = TripData["photos"][number];

// A part of a long day becomes a chapter of its own only with this many
// photos: its 3 prints and a main page.
export const GV_MIN_PART_PHOTOS = 4;
// A break this long inside a day can start a chapter.
export const GV_PART_BREAK_MINUTES = 120;
// About one main page per this many photos, within 2–6.
const GV_PHOTOS_PER_MAIN = 6;

export interface GvSkeletonChapter {
  // Its photos, in time order.
  photos: Photo[];
  // Its logical days, 'YYYY-MM-DD'.
  days: string[];
  // Its page's 3 prints, in time order, and their arrangement.
  prints: string[];
  layout: GvLayout;
}

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
  // Too few photos for a page of prints: into the neighbour, never lost.
  for (let i = 0; i < groups.length && groups.length > 1;) {
    if (groups[i].length >= GV_CHAPTER_PHOTOS) {
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
// one the user wrote a note on (a main page shows a note), then its hero
// score. Higher is better.
export function gvRank(
  p: Photo,
  heroScores: Readonly<Record<string, number>>,
  withNote: ReadonlySet<string> = new Set(),
): number {
  return (p.use_in_wrap_up === true ? 100 : 0) +
    (p.caption?.trim() ? 20 : 0) + (withNote.has(p.id) ? 10 : 0) +
    (heroScores[p.id] ?? 0);
}

// [count] of [photos] (time order) for a page of prints: Always picks
// first, then the best shot of each equal stretch of the rest; in time
// order.
function printsOf(
  photos: readonly Photo[],
  count: number,
  heroScores: Readonly<Record<string, number>>,
): Photo[] {
  const always = photos.filter((p) => p.use_in_wrap_up === true)
    .slice(0, count);
  const rest = photos.filter((p) => !always.includes(p));
  const room = count - always.length;
  const picked = [...always];
  for (let k = 0; k < room && rest.length > 0; k++) {
    const from = Math.floor(k * rest.length / room);
    const to = Math.max(from + 1, Math.floor((k + 1) * rest.length / room));
    const stretch = rest.slice(from, to).filter((p) => !picked.includes(p));
    const best = [...stretch].sort((a, b) =>
      (heroScores[b.id] ?? 0) - (heroScores[a.id] ?? 0)
    )[0];
    if (best) {
      picked.push(best);
    }
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

  // Main pages: about one per GV_PHOTOS_PER_MAIN photos, within 2–6, at
  // least one a chapter while a chapter can spare a photo for one.
  const spare = groups.map((g) => g.length - GV_CHAPTER_PHOTOS);
  const count = Math.min(
    MAX_GV_HEROES,
    Math.max(
      MIN_GV_HEROES,
      groups.length,
      Math.round(photos.length / GV_PHOTOS_PER_MAIN),
    ),
    spare.reduce((s, n) => s + Math.max(0, n), 0),
  );
  const withNote = new Set(
    tripData.notes.flatMap((n) =>
      n.photo_id && n.content.trim() ? [n.photo_id] : []
    ),
  );
  const rank = (p: Photo) => gvRank(p, heroScores, withNote);
  const ranked = groups.map((g) => [...g].sort((a, b) => rank(b) - rank(a)));
  const mains: GvSkeletonMain[] = [];
  for (let round = 0; mains.length < count; round++) {
    let added = false;
    // The chapters with the best photo still free go first in a round.
    const order = groups.map((_, i) => i).filter((i) => round < spare[i])
      .sort((a, b) => rank(ranked[b][round]) - rank(ranked[a][round]));
    for (const i of order) {
      if (mains.length >= count) break;
      mains.push({ photo_id: ranked[i][round].id, chapter: i });
      added = true;
    }
    if (!added) break;
  }
  const main = new Set(mains.map((m) => m.photo_id));
  const order = new Map(photos.map((p, i) => [p.id, i]));
  mains.sort((a, b) => order.get(a.photo_id)! - order.get(b.photo_id)!);

  const chapters: GvSkeletonChapter[] = groups.map((g, i) => {
    const prints = printsOf(
      g.filter((p) => !main.has(p.id)),
      GV_CHAPTER_PHOTOS,
      heroScores,
    ).map((p) => p.id);
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
      layout: chapterLayout(prints, orientations, i),
    };
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
  };
}
