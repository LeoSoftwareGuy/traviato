// Sky Story's film (#463): code's pages (sky_skeleton.ts) with the words
// picked for them (sky_slots.ts), as content.sky — the same shape the app
// has always read (sky_story.ts's SkyContent).
//
// Length: the app plays each page for its share of content.film_seconds
// (SkyStoryTimeline.fittedChapterDurs), never under its words' reading
// time. skySecondsAt mirrors that. Past the film's limit (75 s, and about
// 4 s a film photo below) the film gives way in this order:
// - below 75 s only what has no words: a part of a day without a line, a
//   sky line or a caption joins its day's other page;
// - past 75 s also the user's words: a page's second (third) line, then
//   the sky lines, then a line to a shorter clause of its note, then a
//   page's last line — the last page first.
// Never a day, a caption or the memory's name.

import type { TripData } from "./gather.ts";
import type { WrapUpLanguage } from "./language.ts";
import { decorativePhotos } from "./decorative.ts";
import { filmSecondsOf, readingSeconds } from "./film_length.ts";
import { namesOf, type SlotPicks } from "./film_slots.ts";
import { timeOf } from "./neon_night.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
import {
  firstNameOf,
  MAX_SKY_EXTRAS,
  MAX_SKY_MOSAIC_PHOTOS,
  SKY_VERSION,
  type SkyContent,
  type SkyPageContent,
} from "./sky_story.ts";
import {
  buildSkySkeleton,
  type SkySkeleton,
  type SkySkeletonPage,
} from "./sky_skeleton.ts";
import {
  buildSkySlots,
  resolveSkySlots,
  SKY_CARD_CHARS,
  SKY_SKY_CHARS,
  skyLanguage,
  type SkySlot,
  type SkySlotResult,
  skyUnlistedNotes,
  skyWordGuard,
} from "./sky_slots.ts";

type Photo = TripData["photos"][number];

export interface SkySlotReport {
  slot: string;
  candidates: { id: string; text: string; score: number }[];
  pick: { ids: string[]; free_title: string | null } | null;
  chosen: { id: string; text: string }[];
  source: SkySlotResult["source"];
  reason: string;
}

export interface SkyFilm {
  // null: no photo on any day of the memory — the classic film plays.
  content: SkyContent | null;
  skeleton: SkySkeleton;
  slots: SkySlot[];
  report: SkySlotReport[];
  // What the film gave up for its length, in order.
  trims: string[];
  // "N / M photos on pages" (the mosaic holds the rest).
  shown: { pages: number; photos: number };
  // Notes on no page's list, and why.
  unlisted: { note_id: string; text: string; reason: string }[];
  // The estimated length and the limit it was held to.
  seconds: number;
  limit_seconds: number;
}

export interface SkyFilmOptions {
  heroScores?: Readonly<Record<string, number>>;
  // Photo summaries (photo_analysis): words the director may not use.
  summaries?: ReadonlyMap<string, string>;
  language?: WrapUpLanguage;
}

// --- Length: SkyStoryTimeline in seconds --------------------------------

const OPENING = 5;
const FIRST_INTERLUDE = 2;
const INTERLUDE = 3;
const LAST_INTERLUDE = 2.5;
const CHAPTER = 9.5;
const SHORT_CHAPTER = 8.5;
const LAST_CHAPTER = 11.5;
const ONLY_CHAPTER = 14.5;
const GATHER = 3;
const OUTRO = 8;
const MIN_FIT = 0.75;
const MAX_FIT = 1.6;
const MIN_CHAPTER = 7;
const MAX_PAGES = 5;
const MIN_TAPED_EXTRAS = 2;

type Layout = "fan" | "taped" | "flyOut";

// SkyPageLayout.forPage.
export function skyLayout(i: number, count: number, extras: number): Layout {
  const layout: Layout = i === 0
    ? "fan"
    : i === count - 1
    ? "flyOut"
    : i % 2 === 1
    ? "taped"
    : "fan";
  return layout === "taped" && extras < MIN_TAPED_EXTRAS ? "fan" : layout;
}

const WORDS_AT: Record<Layout, number> = { fan: 1.2, taped: 1.95, flyOut: 4.4 };
const HERO_AT: Record<Layout, number> = {
  fan: 0.35,
  taped: 0.75,
  flyOut: 3.25,
};

function chapterSeconds(i: number, count: number, min: number): number {
  const base = count === 1
    ? ONLY_CHAPTER
    : i === count - 1
    ? LAST_CHAPTER
    : count === MAX_PAGES
    ? SHORT_CHAPTER
    : CHAPTER;
  return Math.max(base, min);
}

// What a page needs to be read (SkyStoryTimeline.readingDur): its words
// (the lines, else the sky line) and its hero's caption.
function readingOf(
  page: { words: string | null; caption: string | null },
  layout: Layout,
  isLast: boolean,
): number {
  const exit = isLast ? 1.75 : 0.25;
  return Math.max(
    page.words ? WORDS_AT[layout] + readingSeconds(page.words) + exit : 0,
    page.caption ? HERO_AT[layout] + readingSeconds(page.caption) + exit : 0,
  );
}

// The film's length with [pages] at [target] s (the app's fit).
export function skySecondsAt(
  pages: readonly {
    extras: number;
    words: string | null;
    caption: string | null;
  }[],
  target: number | null,
): number {
  const count = pages.length;
  if (count === 0) return 0;
  const mins = pages.map((p, i) =>
    readingOf(p, skyLayout(i, count, p.extras), i === count - 1)
  );
  let fixed = OPENING + GATHER + OUTRO;
  for (let i = 0; i < count; i++) {
    fixed += i === 0
      ? FIRST_INTERLUDE
      : i === count - 1
      ? LAST_INTERLUDE
      : INTERLUDE;
  }
  // As the app's fittedChapterDurs + forChapters: a fitted length is a
  // page's minimum, so a page stretches for the target but never plays
  // shorter than its reference.
  const scaled = (f: number) =>
    pages.reduce(
      (s, _, i) =>
        s + chapterSeconds(
          i,
          count,
          f === 1 ? mins[i] : Math.max(
            Math.max(chapterSeconds(i, count, 0) * f, MIN_CHAPTER),
            mins[i],
          ),
        ),
      0,
    );
  if (target === null) return fixed + scaled(1);
  let lo = MIN_FIT;
  let hi = MAX_FIT;
  for (let k = 0; k < 40; k++) {
    const mid = (lo + hi) / 2;
    if (fixed + scaled(mid) < target) lo = mid;
    else hi = mid;
  }
  return fixed + scaled((lo + hi) / 2);
}

// --- The film -----------------------------------------------------------

interface WorkPage {
  page: SkySkeletonPage;
  headline: string | null;
  lines: { slot: string; note_id: string; text: string; at: number }[];
  sky_line: { slot: string; text: string } | null;
}

function dateOf(start: string, day: number): string {
  const ms = Date.parse(`${start}T00:00:00Z`) + (day - 1) * 86_400_000;
  return new Date(ms).toISOString().slice(0, 10);
}

// Sky Story for [tripData] with the director's [picks] (null: code picks
// every slot).
//
// When the user's words would go past 75 s, the pages are cut again with
// one split day fewer (a day's parts back on one page) before any line
// gives way: a split is a spare page, the user's words aren't.
export function skyStoryFilm(
  tripData: TripData,
  picks: SlotPicks | null,
  options: SkyFilmOptions = {},
  maxSplits = Infinity,
): SkyFilm {
  const heroScores = options.heroScores ?? {};
  const skeleton = buildSkySkeleton(tripData, heroScores, maxSplits);
  const appLanguage = options.language ?? "en";
  const language = skyLanguage(tripData, appLanguage);
  const slots = buildSkySlots(tripData, skeleton, appLanguage);
  const resolved = resolveSkySlots(slots, picks, {
    language,
    names: namesOf(tripData),
    guard: skyWordGuard(tripData, options.summaries ?? new Map()),
    shown: [
      tripData.trip.name,
      ...skeleton.pages.map((p) => p.hero.caption?.trim() ?? ""),
    ],
  });
  const notes = new Map(
    tripData.notes.filter((n) => n.id).map((n) => [n.id!, n]),
  );
  const noteAt = (id: string) => {
    const n = notes.get(id);
    const t = n && !n.legacy ? Date.parse(n.taken_at ?? n.created_at ?? "") : 0;
    return Number.isNaN(t) ? 0 : t;
  };

  let work: WorkPage[] = skeleton.pages.map((page, k) => {
    const of = (kind: string) =>
      slots.filter((s) => s.page === k && s.kind === kind);
    const lines = of("line").flatMap((s) =>
      (resolved.get(s.slot)?.chosen ?? []).flatMap((c) =>
        c.note_id
          ? [{
            slot: s.slot,
            note_id: c.note_id,
            text: c.text,
            at: noteAt(c.note_id),
          }]
          : []
      )
    ).sort((a, b) => a.at - b.at);
    const sky = of("sky_line")[0];
    const skyText = sky ? resolved.get(sky.slot)?.chosen[0]?.text : undefined;
    const head = resolved.get(`p${k + 1}.headline`)?.chosen[0]?.text ?? null;
    return {
      page,
      headline: head,
      lines,
      sky_line: skyText && lines.length === 0
        ? { slot: sky.slot, text: skyText }
        : null,
    };
  });

  // At most WRAP_UP_LIMITS.maxNoteLines lines in the film (#433): the
  // last pages give theirs up first.
  const trims: string[] = [];
  const dropped = new Map<string, string>();
  const shortened = new Map<string, string>();
  const lineCount = () => work.reduce((n, w) => n + w.lines.length, 0);
  for (let k = work.length - 1; k >= 0; k--) {
    while (
      work[k].lines.length > 1 && lineCount() > WRAP_UP_LIMITS.maxNoteLines
    ) {
      const l = work[k].lines.pop()!;
      dropped.set(l.slot, `over ${WRAP_UP_LIMITS.maxNoteLines} lines`);
    }
  }

  const target = filmSecondsOf(tripData);
  const shape = (pages: WorkPage[]) =>
    pages.map((w) => ({
      extras: Math.min(MAX_SKY_EXTRAS, w.page.extras.length),
      words: w.lines.length > 0
        ? w.lines.map((l) => l.text).join(" ")
        : w.sky_line?.text ?? null,
      caption: w.page.hero.caption?.trim() || null,
    }));
  const seconds = () => skySecondsAt(shape(work), target);
  const limit = skeleton.limit_seconds;
  const longest = WRAP_UP_LIMITS.longestFilmSeconds;

  // 1. A wordless part of a day joins its day's neighbour (the last
  // first): its photos go to the mosaic.
  while (seconds() > limit + 1e-9) {
    const k = work.findLastIndex((w, i) =>
      w.page.is_part && w.lines.length === 0 && !w.sky_line &&
      !w.page.hero.caption?.trim() &&
      work.some((o, j) => j !== i && o.page.days.join() === w.page.days.join())
    );
    if (k < 0) break;
    trims.push(
      `p${k + 1}: a wordless part of ${work[k].page.days[0]} left out`,
    );
    for (const l of work[k].lines) dropped.set(l.slot, "page left out");
    work = work.filter((_, i) => i !== k);
  }
  // A page shows only the words its box holds (the app drops the rest):
  // the last line to a shorter clause of its note, else left out.
  const chars = (w: WorkPage) =>
    [...w.lines.map((l) => l.text).join(" ")].length;
  const room = (k: number) =>
    skyLayout(
        k,
        work.length,
        Math.min(MAX_SKY_EXTRAS, work[k].page.extras.length),
      ) ===
        "flyOut"
      ? SKY_SKY_CHARS
      : SKY_CARD_CHARS;
  work.forEach((w, k) => {
    while (w.lines.length > 0 && chars(w) > room(k)) {
      const l = w.lines[w.lines.length - 1];
      const others = new Set(
        work.flatMap((o) => o.lines).filter((o) => o !== l).map((o) => o.text),
      );
      const shorter = slots.find((x) => x.slot === l.slot)!.candidates
        .filter((c) =>
          c.note_id === l.note_id &&
          [...c.text].length < [...l.text].length && !others.has(c.text) &&
          [...c.text].length - [...l.text].length + chars(w) <= room(k)
        )
        .sort((a, b) => b.score - a.score)[0];
      if (shorter) {
        l.text = shorter.text;
        shortened.set(l.slot, shorter.text);
        trims.push(`p${k + 1}: a line to a shorter clause to fit the page`);
      } else {
        w.lines.pop();
        dropped.set(l.slot, "doesn't fit the page");
        trims.push(`p${k + 1}: a line doesn't fit the page`);
      }
    }
  });

  // 2–4. Past 75 s only: first a split day fewer, then the user's words,
  // the last page first.
  const past = () => seconds() > longest + 1e-9;
  if (past() && skeleton.splits > 0) {
    const fewer = skyStoryFilm(
      tripData,
      picks,
      options,
      skeleton.splits - 1,
    );
    return {
      ...fewer,
      trims: [
        `${skeleton.splits} split day(s) → ${
          skeleton.splits - 1
        }: the words need the time`,
        ...fewer.trims,
      ],
    };
  }
  for (let k = work.length - 1; k >= 0 && past(); k--) {
    while (work[k].lines.length > 1 && past()) {
      const l = work[k].lines.pop()!;
      dropped.set(l.slot, "for length");
      trims.push(`p${k + 1}: a second line left out`);
    }
  }
  for (let k = work.length - 1; k >= 0 && past(); k--) {
    if (work[k].sky_line) {
      dropped.set(work[k].sky_line!.slot, "for length");
      work[k].sky_line = null;
      trims.push(`p${k + 1}: its sky line left out`);
    }
  }
  // A line to a shorter clause of its note (one of its slot's
  // candidates), the last page first; then no line.
  const shown = () => new Set(work.flatMap((w) => w.lines.map((l) => l.text)));
  for (let k = work.length - 1; k >= 0 && past(); k--) {
    for (const l of work[k].lines) {
      while (past()) {
        const shorter = slots.find((x) => x.slot === l.slot)!.candidates
          .filter((c) =>
            c.note_id === l.note_id &&
            [...c.text].length < [...l.text].length &&
            !shown().has(c.text)
          )
          .sort((a, b) => b.score - a.score)[0];
        if (!shorter) break;
        l.text = shorter.text;
        shortened.set(l.slot, shorter.text);
        trims.push(`p${k + 1}: its line to a shorter clause`);
      }
    }
  }
  for (let k = work.length - 1; k >= 0 && past(); k--) {
    const l = work[k].lines.pop();
    if (l) {
      dropped.set(l.slot, "for length");
      shortened.delete(l.slot);
      trims.push(`p${k + 1}: its line left out`);
    }
  }

  const start = tripData.trip.start_date;
  const pages: SkyPageContent[] = start
    ? work.map((w) => {
      const multi = w.page.last_day > w.page.first_day;
      const noteId = w.lines[0]?.note_id ?? null;
      return {
        first_day: w.page.first_day,
        last_day: multi ? w.page.last_day : null,
        date: dateOf(start, w.page.first_day),
        end_date: multi ? dateOf(start, w.page.last_day) : null,
        photo_count: w.page.photos.length,
        headline: w.headline,
        hero_photo_id: w.page.hero.id,
        extra_photo_ids: [...w.page.extras].sort((a, b) =>
          timeOf(a) - timeOf(b)
        ).map((p) => p.id),
        note_id: noteId,
        note: noteId ? notes.get(noteId)?.content.trim() || null : null,
        excerpts: w.lines.map((l) => ({ note_id: l.note_id, text: l.text })),
        sky_line: w.sky_line?.text ?? null,
      };
    })
    : [];
  const shownIds = new Set(
    pages.flatMap((p) => [p.hero_photo_id, ...p.extra_photo_ids]),
  );
  const mosaic = decorativePhotos(
    skeleton.photos,
    shownIds,
    MAX_SKY_MOSAIC_PHOTOS,
  );
  const content: SkyContent | null = pages.length === 0 ? null : {
    sky_version: SKY_VERSION,
    source: picks ? "director" : "code",
    title: tripData.trip.name,
    first_name: firstNameOf(tripData.username),
    moment_count: tripData.photos.length,
    mosaic_photo_ids: mosaic.map((p: Photo) => p.id),
    pages,
  };
  return {
    content,
    skeleton,
    slots,
    report: slots.map((s) => {
      const r = resolved.get(s.slot)!;
      const pick = picks?.[s.slot];
      const gone = dropped.get(s.slot);
      const short = shortened.get(s.slot);
      return {
        slot: s.slot,
        candidates: s.candidates.map((c) => ({
          id: c.id,
          text: c.text,
          score: c.score,
        })),
        pick: pick
          ? { ids: pick.ids, free_title: pick.free_title ?? null }
          : null,
        chosen: gone
          ? []
          : short
          ? [{ id: r.chosen[0]?.id ?? "", text: short }]
          : r.chosen.map((c) => ({ id: c.id, text: c.text })),
        source: r.source,
        reason: gone
          ? `${r.reason}; ${gone}: not shown`
          : short
          ? `${r.reason}; for length: a shorter clause`
          : r.reason,
      };
    }),
    trims,
    shown: { pages: shownIds.size, photos: skeleton.photos.length },
    unlisted: skyUnlistedNotes(tripData, skeleton, slots),
    seconds: Math.round(seconds() * 10) / 10,
    limit_seconds: limit,
  };
}
