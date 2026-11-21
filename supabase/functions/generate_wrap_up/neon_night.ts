// Neon Night (#363, phase 9): the beat-synced party film, stored as
// wrap_ups.content.neon_night next to everything the other films read.
//
// A memory whose vibes choose Neon Night (#433) always plays it: the
// director's `neon_night` section, repaired here against the memory as it
// is now — and when nothing of it can be kept (no section, the director
// off or failed, a section still broken after repair), a plan code builds
// for the same film ([codeNeonNight]). Never another template.
//
// The director picks: where each chapter starts (its first photo — every
// photo of the night falls into a chapter, so new photos join one on their
// own), chapter titles, each chapter's 1–2 moments and their photos, which
// of the user's notes to type out (exact excerpts only, never reworded),
// the note scene's background photo and the Finale's headline.
// What code fills in, never the AI: the plan rows (the user's quests with
// times), every photo and its time, the totals, the signature.

import type { TripData } from "./gather.ts";
import { sortPhotosChronologically, spreadEvenly } from "./assemble.ts";
import { decorativePhotos } from "./decorative.ts";
import { bannedPhraseIn, cleanAiLine, cleanLine } from "./film_plan.ts";
import type { WrapUpLanguage } from "./language.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
import {
  filmSecondsOf,
  nnBeatsFor,
  nnFilmBeats,
  nnFitsWithin,
  nnMomentBeats,
  type NnShapeMoment,
} from "./film_length.ts";
import { wholeWords } from "./text_fit.ts";
export { wholeWords };
import { isExcerptOf } from "./golden_vows.ts";
import { firstNameOf } from "./sky_story.ts";
import { tripLogicalDays } from "./logical_day.ts";
import {
  excerptCandidates,
  excerptScore,
  isDrugReference,
  isGeneric,
  isSensitive,
  MAX_EXCERPT_CHARS,
  snapToNote,
  SPECIFIC_SCORE,
} from "./excerpts.ts";

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
// A card's typed line wraps to at most 2 lines.
export const MAX_NN_CARD_NOTE_CHARS = 60;
// The note scene: up to 5 lines of about 18 characters.
export const MAX_NN_NOTE_CHARS = 90;

type Photo = TripData["photos"][number];

export interface NeonNightChapterPlan {
  title: string;
  // Where the chapter starts; it runs to the next chapter's first photo.
  first_photo_id: string;
  // A note to type out on the card and an exact excerpt of it, or both
  // null.
  note_id: string | null;
  note_excerpt: string | null;
  moments: { type: NnMomentType; photo_ids: string[] }[];
  // The chapter's best lines (#398 R3/R4): exact excerpts of notes, each
  // with the photo it belongs to. Absent in plans made before.
  excerpts?: NeonNightExcerptPlan[];
}

export interface NeonNightExcerptPlan {
  note_id: string;
  text: string;
  photo_id: string | null;
}

// Excerpts a chapter carries (#398 R3).
export const MIN_NN_EXCERPTS = 2;
export const MAX_NN_EXCERPTS = 3;

export interface NeonNightPlan {
  chapters: NeonNightChapterPlan[];
  // The note written out in neon; null = no Note scene.
  note_moment: {
    note_id: string;
    excerpt: string;
    // The blurred background; null = the haze.
    photo_id: string | null;
  } | null;
  // The Finale's headline; null = the app's fallback.
  headline: string | null;
}

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

function isString(v: unknown): v is string {
  return typeof v === "string";
}

function collapse(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

// --- The director's tool section -----------------------------------------

const lineProperty = (description: string) => ({
  type: "string",
  description,
});

const excerptDescription = (max: number) =>
  `With note_id: words copied exactly from that note, at most ${max} characters, never reworded. Otherwise null.`;

export const neonNightToolProperty = {
  type: ["object", "null"],
  description:
    "The Neon Night film: a loud, beat-synced neon party film for this memory's night.",
  properties: {
    chapters: {
      type: "array",
      description:
        `${MIN_NN_CHAPTERS}–${MAX_NN_CHAPTERS} chapters of the night, in order. Each starts at its first photo and runs to the next chapter's.`,
      items: {
        type: "object",
        properties: {
          title: lineProperty(
            `At most ${MAX_NN_TITLE_CHARS} characters, e.g. "Doors open".`,
          ),
          first_photo_id: { type: "string" },
          note_id: {
            type: ["string", "null"],
            description:
              "A note whose words fit this part of the night, typed out on its card, or null.",
          },
          note_excerpt: {
            type: ["string", "null"],
            description: excerptDescription(MAX_NN_CARD_NOTE_CHARS),
          },
          moments: {
            type: "array",
            description: `1–${MAX_NN_MOMENTS} blocks after the card.`,
            items: {
              type: "object",
              properties: {
                type: { type: "string", enum: [...PLANNED_NN_MOMENT_TYPES] },
                photo_ids: { type: "array", items: { type: "string" } },
              },
              required: ["type", "photo_ids"],
            },
          },
          excerpts: {
            type: "array",
            description:
              `${MIN_NN_EXCERPTS}–${MAX_NN_EXCERPTS} of the chapter's most specific lines from the notes, in time order; fewer only when its notes have no more. Empty when the chapter has no notes.`,
            items: {
              type: "object",
              properties: {
                note_id: { type: "string" },
                text: lineProperty(
                  `Words copied exactly from that note, one or more whole sentences or clauses, at most ${MAX_EXCERPT_CHARS} characters.`,
                ),
                photo_id: {
                  type: ["string", "null"],
                  description:
                    "The chapter's photo the line belongs to (the note's own photo, else the one it describes or nearest in time), or null.",
                },
              },
              required: ["note_id", "text", "photo_id"],
            },
          },
        },
        required: [
          "title",
          "first_photo_id",
          "note_id",
          "note_excerpt",
          "moments",
          "excerpts",
        ],
      },
    },
    note_moment: {
      type: ["object", "null"],
      description:
        "The one note written out in neon near the end, or null when no note fits.",
      properties: {
        note_id: { type: "string" },
        excerpt: lineProperty(excerptDescription(MAX_NN_NOTE_CHARS)),
        photo_id: {
          type: ["string", "null"],
          description: "A photo of the night behind it, or null.",
        },
      },
      required: ["note_id", "excerpt", "photo_id"],
    },
    headline: {
      type: ["string", "null"],
      description:
        `The Finale's headline, at most ${MAX_NN_HEADLINE_CHARS} characters, e.g. "Best night ever"; or null.`,
    },
  },
  required: ["chapters", "note_moment", "headline"],
} as const;

export const NEON_NIGHT_PROMPT_RULES = [
  "\n\nneon_night — a loud neon party film, chosen for this memory from ",
  "its vibes (#433). Always fill it.\n",
  "- Strict chronology: everything plays in time order. Photos are listed ",
  "in time order; a moment's photos and a chapter's moments follow it, and ",
  "no scene shows a photo older than the scene before.\n",
  `- chapters: ${MIN_NN_CHAPTERS}–${MAX_NN_CHAPTERS}. Each photo's \`day\` is `,
  "its logical day (the night until about 08:00 belongs to the evening ",
  "before). Several days: exactly one chapter per part, starting at each ",
  "photo marked chapter_start (each day's first photo, and the first ",
  "after a long break within a day) — never two days or two parts in one ",
  "chapter, no other chapters. One day or night: split it by time into parts ",
  "(arriving, the peak, late…). first_photo_id is the chapter's first ",
  "photo; the first chapter starts at the first photo. title is short, in ",
  "the night's mood and the notes' language, built on a real detail when ",
  'there is one ("4,5 кг рёбер", "Home at 8 am") rather than a generic ',
  'one ("Club night").\n',
  "- moments: 1–2 per chapter, photos from that chapter only, each photo at ",
  "most once. split: 2–3 photos within about 10 minutes. burst: 2–4 ",
  "photos within about a minute. timeline: 2–8 photos spread across the ",
  "chapter (code fills it up with more of the chapter's photos). Good ",
  "mix: chapter 1 split + burst, chapter 2 timeline, later whichever ",
  "fits.\n",
  "- Notes are the person's own words only: note_id points at a note and ",
  "note_excerpt / excerpt / excerpts[].text copy words from it exactly — ",
  "same words, same spelling, never reworded, corrected or shortened ",
  "inside; cut only at sentence or clause ends. Else null.\n",
  `- excerpts: ${MIN_NN_EXCERPTS}–${MAX_NN_EXCERPTS} per chapter when its notes allow, chosen `,
  "for detail: numbers, names, places, food, firsts, funny or surprising ",
  'moments, strong feelings. Never a generic summary ("it was fun", ',
  '"everyone was tired", "went home", "было весело", "все устали", ',
  '"пошли домой") while a specific line exists. A note about another ',
  'day ("yesterday…", "вчера…") goes in the chapter it describes. ',
  "photo_id: the note's own photo_id when it has one, else the chapter's ",
  "photo the line describes (from the summaries, captions, places), else ",
  "the one nearest in time. note_excerpt is the chapter's best line; ",
  "note_moment the single most heartfelt line of the night.\n",
  "- A photo's caption is the person's best line for that photo: prefer ",
  "captioned photos in moments.\n",
  "- Every must_include photo is in a moment of its chapter (or is the ",
  "note_moment's photo): pick moment types and sizes that fit them.\n",
  "- headline: a few loud words for the drop, in the notes' language, ",
  "built on the person's own details; never invent facts. null if nothing ",
  "fits.\n",
  "- Never choose drug references or profanity for a title, the headline ",
  "or note_moment, even when the notes contain them.",
].join("");

// --- Checking a section against the memory -------------------------------

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

function checkLine(
  problems: string[],
  where: string,
  line: unknown,
  maxChars: number,
): void {
  if (!isString(line) || line.trim().length === 0) {
    problems.push(`${where}: expected a non-empty string`);
    return;
  }
  if ([...line].length > maxChars) {
    problems.push(
      `${where}: ${[...line].length} characters, at most ${maxChars}`,
    );
  }
  const banned = bannedPhraseIn(line);
  if (banned) problems.push(`${where}: banned phrase "${banned}"`);
}

function checkExcerpt(
  problems: string[],
  where: string,
  noteId: unknown,
  excerpt: unknown,
  context: NnCheckContext,
  maxChars: number,
): void {
  const note = isString(noteId) ? context.notes.get(noteId) : undefined;
  if (note === undefined) {
    problems.push(`${where}.note_id: not a note id from the input`);
    return;
  }
  if (!isString(excerpt) || !isExcerptOf(excerpt, note)) {
    problems.push(`${where}: must be copied exactly from the note`);
  } else if ([...collapse(excerpt)].length > maxChars) {
    problems.push(
      `${where}: ${
        [...collapse(excerpt)].length
      } characters, at most ${maxChars}`,
    );
  }
}

// A chapter's excerpts (#398 R3/R4): at most MAX_NN_EXCERPTS, each the
// note's exact words, its photo one of the chapter's. Absent = none (a plan
// made before).
function checkExcerpts(
  problems: string[],
  where: string,
  excerpts: unknown,
  context: NnCheckContext,
  start: number | null,
  end: number,
): void {
  if (excerpts === undefined) return;
  if (!Array.isArray(excerpts)) {
    problems.push(`${where}.excerpts: expected an array`);
    return;
  }
  if (excerpts.length > MAX_NN_EXCERPTS) {
    problems.push(
      `${where}.excerpts: ${excerpts.length}, at most ${MAX_NN_EXCERPTS}`,
    );
  }
  excerpts.forEach((raw, k) => {
    const at = `${where}.excerpts[${k}]`;
    if (typeof raw !== "object" || raw === null) {
      problems.push(`${at}: expected an object`);
      return;
    }
    const e = raw as Record<string, unknown>;
    checkExcerpt(
      problems,
      `${at}.text`,
      e.note_id,
      e.text,
      context,
      MAX_EXCERPT_CHARS,
    );
    if (e.photo_id !== null && e.photo_id !== undefined) {
      const order = isString(e.photo_id)
        ? context.photoOrder.get(e.photo_id)
        : undefined;
      if (
        order === undefined ||
        (start !== null && (order < start || order >= end))
      ) {
        problems.push(`${at}.photo_id: not a photo of this chapter`);
      }
    }
  });
}

// Every way [data] breaks the neon_night rules, one readable line each —
// empty when it's valid. Call it only for a non-null section.
export function describeNeonNightProblems(
  data: unknown,
  context: NnCheckContext,
): string[] {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return ["neon_night: expected an object or null"];
  }
  const nn = data as Record<string, unknown>;
  const problems: string[] = [];

  const photoAt = (id: unknown, where: string): number | null => {
    if (!isString(id)) {
      problems.push(`${where}: expected a photo id`);
      return null;
    }
    if (context.excludedIds.has(id)) {
      problems.push(`${where}: "${id}" was left out by the user`);
      return null;
    }
    const at = context.photoOrder.get(id);
    if (at === undefined) {
      problems.push(`${where}: "${id}" is not a photo id from the input`);
      return null;
    }
    return at;
  };

  const chapters = nn.chapters;
  if (!Array.isArray(chapters)) {
    problems.push("neon_night.chapters: expected an array");
  } else {
    if (
      chapters.length < MIN_NN_CHAPTERS || chapters.length > MAX_NN_CHAPTERS
    ) {
      problems.push(
        `neon_night.chapters: ${chapters.length}, expected ${MIN_NN_CHAPTERS}–${MAX_NN_CHAPTERS}`,
      );
    }
    // Where each chapter starts, to check its moments' photos are its own.
    const starts = chapters.map((raw) =>
      typeof raw === "object" && raw !== null
        ? context.photoOrder.get(
          (raw as Record<string, unknown>).first_photo_id as string,
        ) ?? null
        : null
    );
    chapters.forEach((raw, i) => {
      const where = `neon_night.chapters[${i}]`;
      if (typeof raw !== "object" || raw === null) {
        problems.push(`${where}: expected an object`);
        return;
      }
      const chapter = raw as Record<string, unknown>;
      checkLine(problems, `${where}.title`, chapter.title, MAX_NN_TITLE_CHARS);
      if (isString(chapter.title) && isSensitive(chapter.title)) {
        problems.push(`${where}.title: no drug references or profanity`);
      }
      // The title rules (#450), so a section stored by older code — with
      // "Tallinn airport" or the headline as a title — is repaired on
      // open, not played as it was.
      if (isString(chapter.title) && chapter.title.trim()) {
        const title = chapter.title.trim();
        const place = [...(context.photoPlaces?.values() ?? [])].some((p) =>
          p.trim() === title
        );
        if (!place && titleInOtherLanguage(title, context)) {
          problems.push(`${where}.title: in the notes' language`);
        }
        if (isString(nn.headline) && sameLine(title, nn.headline)) {
          problems.push(`${where}.title: repeats the headline`);
        }
      }
      const start = photoAt(chapter.first_photo_id, `${where}.first_photo_id`);
      if (start !== null) {
        if (i === 0 && start !== 0) {
          problems.push(`${where}.first_photo_id: must be the first photo`);
        }
        const previous = i > 0 ? starts[i - 1] : null;
        if (previous !== null && start <= previous) {
          problems.push(
            `${where}.first_photo_id: must come after the previous chapter's`,
          );
        }
      }
      const end = starts.slice(i + 1).find((s) => s !== null) ??
        context.photoOrder.size;

      const noteId = chapter.note_id ?? null;
      const excerpt = chapter.note_excerpt ?? null;
      if (noteId === null) {
        if (excerpt !== null) {
          problems.push(`${where}.note_excerpt: only with a note_id`);
        }
      } else {
        checkExcerpt(
          problems,
          `${where}.note_excerpt`,
          noteId,
          excerpt,
          context,
          MAX_NN_CARD_NOTE_CHARS,
        );
      }

      checkExcerpts(problems, where, chapter.excerpts, context, start, end);

      const moments = chapter.moments;
      if (!Array.isArray(moments)) {
        problems.push(`${where}.moments: expected an array`);
        return;
      }
      if (moments.length < 1 || moments.length > MAX_NN_MOMENTS) {
        problems.push(
          `${where}.moments: ${moments.length}, expected 1–${MAX_NN_MOMENTS}`,
        );
      }
      const used = new Set<string>();
      moments.forEach((rawMoment, m) => {
        const at = `${where}.moments[${m}]`;
        if (typeof rawMoment !== "object" || rawMoment === null) {
          problems.push(`${at}: expected an object`);
          return;
        }
        const moment = rawMoment as Record<string, unknown>;
        const type = moment.type as NnMomentType;
        if (!NN_MOMENT_TYPES.includes(type)) {
          problems.push(
            `${at}.type: expected one of ${NN_MOMENT_TYPES.join(", ")}`,
          );
          return;
        }
        const ids = moment.photo_ids;
        if (!Array.isArray(ids)) {
          problems.push(`${at}.photo_ids: expected an array of ids`);
          return;
        }
        const [min, max] = NN_MOMENT_PHOTOS[type];
        if (ids.length < min || ids.length > max) {
          problems.push(
            `${at}.photo_ids: ${ids.length}, a ${type} takes ${min}–${max}`,
          );
        }
        let last = -1;
        ids.forEach((id, k) => {
          const order = photoAt(id, `${at}.photo_ids[${k}]`);
          if (order === null) return;
          if (start !== null && (order < start || order >= end)) {
            problems.push(
              `${at}.photo_ids[${k}]: "${id}" is not from this chapter`,
            );
          }
          if (used.has(id as string)) {
            problems.push(`${at}.photo_ids[${k}]: "${id}" is used twice`);
          }
          used.add(id as string);
          if (order < last) {
            problems.push(
              `${at}.photo_ids[${k}]: "${id}" is out of chronological order`,
            );
          }
          last = Math.max(last, order);
        });
      });
    });

    // One chapter per part of a day (#398 R1, #426).
    const required = nnChapterStarts(context);
    if (required.length > 0) {
      const actual = starts.filter((x): x is number => x !== null);
      if (
        actual.length !== required.length ||
        actual.some((x, k) => x !== required[k])
      ) {
        problems.push(
          `neon_night.chapters: the memory has ${required.length} parts — one chapter starting at each chapter_start photo`,
        );
      }
    }
  }

  const noteMoment = nn.note_moment;
  if (noteMoment !== null && noteMoment !== undefined) {
    if (typeof noteMoment !== "object" || Array.isArray(noteMoment)) {
      problems.push("neon_night.note_moment: expected an object or null");
    } else {
      const n = noteMoment as Record<string, unknown>;
      checkExcerpt(
        problems,
        "neon_night.note_moment.excerpt",
        n.note_id,
        n.excerpt,
        context,
        MAX_NN_NOTE_CHARS,
      );
      if (n.photo_id !== null && n.photo_id !== undefined) {
        photoAt(n.photo_id, "neon_night.note_moment.photo_id");
      }
      if (isString(n.excerpt) && isSensitive(n.excerpt)) {
        problems.push(
          "neon_night.note_moment: no drug references or profanity",
        );
      }
    }
  }

  if (nn.headline !== null && nn.headline !== undefined) {
    checkLine(
      problems,
      "neon_night.headline",
      nn.headline,
      MAX_NN_HEADLINE_CHARS,
    );
    if (isString(nn.headline) && isSensitive(nn.headline)) {
      problems.push("neon_night.headline: no drug references or profanity");
    }
  }

  // Always picks without a moment aren't a problem (#433): the Finale's
  // heart shows every one that found none.
  return problems;
}

function cleanExcerpt(text: string): string {
  return cleanLine(text).replace(/^(\.\.\.|…)\s*/u, "").replace(
    /\s*(\.\.\.|…)$/u,
    "",
  ).trim();
}

// Fixes what code can put right without guessing: stray quotes on lines,
// quotes or ellipses around an excerpt, a card excerpt that isn't the
// note's words (→ no typed line), a note moment that isn't (→ no Note
// scene), too many chapters or moments, chapters, moment photos out of
// order, a first chapter that starts late. Never throws.
export function repairNeonNight(
  data: unknown,
  context: NnCheckContext,
): unknown {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return data;
  }
  const nn = structuredClone(data) as Record<string, unknown>;
  const order = (id: unknown) =>
    isString(id) ? context.photoOrder.get(id) ?? Infinity : Infinity;
  // A line that differs from the note only in case, spaces, punctuation
  // or ё/е takes the note's exact words (#444) instead of being dropped.
  const snap = (noteId: unknown, excerpt: unknown) => {
    const note = isString(noteId) ? context.notes.get(noteId) : undefined;
    if (note === undefined || !isString(excerpt)) return excerpt;
    if (isExcerptOf(excerpt, note)) return excerpt;
    return snapToNote(excerpt, note) ?? excerpt;
  };
  const fitsNote = (noteId: unknown, excerpt: unknown, max: number) => {
    const note = isString(noteId) ? context.notes.get(noteId) : undefined;
    return note !== undefined && isString(excerpt) &&
      isExcerptOf(excerpt, note) && [...collapse(excerpt)].length <= max;
  };

  if (Array.isArray(nn.chapters)) {
    const chapters = (nn.chapters as unknown[]).slice(0, MAX_NN_CHAPTERS);
    for (const raw of chapters) {
      if (typeof raw !== "object" || raw === null) continue;
      const chapter = raw as Record<string, unknown>;
      if (isString(chapter.title)) chapter.title = cleanLine(chapter.title);
      chapter.note_id = chapter.note_id ?? null;
      chapter.note_excerpt = chapter.note_excerpt ?? null;
      if (isString(chapter.note_excerpt)) {
        chapter.note_excerpt = snap(
          chapter.note_id,
          cleanExcerpt(chapter.note_excerpt),
        );
      }
      if (
        fitsNote(chapter.note_id, chapter.note_excerpt, MAX_NN_CARD_NOTE_CHARS)
      ) {
        chapter.note_excerpt = collapse(chapter.note_excerpt as string);
      } else {
        chapter.note_id = null;
        chapter.note_excerpt = null;
      }
      if (isString(chapter.title) && isSensitive(chapter.title)) {
        chapter.title = null;
      }
      chapter.excerpts = cleanExcerpts(chapter.excerpts, context);
      if (Array.isArray(chapter.moments)) {
        chapter.moments = chapter.moments.slice(0, MAX_NN_MOMENTS);
        for (const m of chapter.moments as unknown[]) {
          if (typeof m !== "object" || m === null) continue;
          const moment = m as Record<string, unknown>;
          if (Array.isArray(moment.photo_ids)) {
            moment.photo_ids = [...moment.photo_ids].sort((a, b) =>
              order(a) - order(b)
            );
          }
        }
      }
    }
    chapters.sort((a, b) =>
      order((a as Record<string, unknown> | null)?.first_photo_id) -
      order((b as Record<string, unknown> | null)?.first_photo_id)
    );
    // The night starts with its first photo.
    const first = chapters[0] as Record<string, unknown> | undefined;
    const firstId = [...context.photoOrder].find(([, i]) => i === 0)?.[0];
    if (first && typeof first === "object" && firstId !== undefined) {
      first.first_photo_id = firstId;
    }
    nn.chapters = splitByDays(chapters, context);
    fitTitles(
      nn.chapters as unknown[],
      context,
      isString(nn.headline) ? cleanAiLine(nn.headline) : null,
    );
    repairMoments(nn, context);
    fitExcerptPhotos(nn, context);
  }

  if (typeof nn.note_moment === "object" && nn.note_moment !== null) {
    const n = nn.note_moment as Record<string, unknown>;
    if (isString(n.excerpt)) {
      n.excerpt = snap(n.note_id, cleanExcerpt(n.excerpt));
    }
    n.photo_id = n.photo_id ?? null;
    if (
      fitsNote(n.note_id, n.excerpt, MAX_NN_NOTE_CHARS) &&
      !isSensitive(n.excerpt as string)
    ) {
      // Keeps the note's own line breaks: only the ends are trimmed.
      n.excerpt = (n.excerpt as string).trim();
    } else {
      nn.note_moment = null;
    }
  }
  if (nn.note_moment === undefined) nn.note_moment = null;

  if (isString(nn.headline)) {
    nn.headline = cleanAiLine(nn.headline) || null;
    if (isString(nn.headline) && isSensitive(nn.headline)) nn.headline = null;
    // Too long: none — never cut mid-phrase (#444; was whole words off
    // its end). The headline is optional, never a reason to lose the film.
    if (
      isString(nn.headline) &&
      [...nn.headline].length > MAX_NN_HEADLINE_CHARS
    ) {
      nn.headline = null;
    }
  }
  if (nn.headline === undefined) nn.headline = null;
  return nn;
}

// A chapter's excerpts as code can keep them (#398): exact words of a
// known note, quotes and ellipses trimmed, at most MAX_EXCERPT_CHARS, no
// repeats, at most MAX_NN_EXCERPTS. Anything else is dropped.
function cleanExcerpts(
  raw: unknown,
  context: NnCheckContext,
): NeonNightExcerptPlan[] {
  if (!Array.isArray(raw)) return [];
  const kept: NeonNightExcerptPlan[] = [];
  for (const item of raw) {
    if (typeof item !== "object" || item === null) continue;
    const e = item as Record<string, unknown>;
    if (!isString(e.note_id) || !isString(e.text)) continue;
    const note = context.notes.get(e.note_id);
    const raw = collapse(cleanExcerpt(e.text));
    const text = note === undefined || isExcerptOf(raw, note)
      ? raw
      : collapse(snapToNote(raw, note) ?? raw);
    if (
      note === undefined || !isExcerptOf(text, note) ||
      [...text].length > MAX_EXCERPT_CHARS ||
      kept.some((k) => k.text.includes(text) || text.includes(k.text))
    ) {
      continue;
    }
    kept.push({
      note_id: e.note_id,
      text,
      photo_id: isString(e.photo_id) ? e.photo_id : null,
    });
  }
  return kept.slice(0, MAX_NN_EXCERPTS);
}

// One chapter per logical day (#398 R1): a several-day memory's chapters
// are rebuilt to start at each day's first photo (neighbouring days
// grouped past MAX_NN_CHAPTERS). Each keeps the director's title,
// card line, moments and excerpts that fall in its days; a day the
// director folded into another chapter gets that chapter's moments' photos
// of its own days, and as title the place most of its photos share, else
// the folding chapter's. A single day keeps the director's split.
function splitByDays(
  chapters: unknown[],
  context: NnCheckContext,
): unknown[] {
  const required = nnChapterStarts(context);
  if (required.length === 0) return chapters;
  const old = chapters.filter((c) =>
    typeof c === "object" && c !== null &&
    context.photoOrder.has(
      (c as Record<string, unknown>).first_photo_id as string,
    )
  ) as Record<string, unknown>[];
  if (old.length === 0) return chapters;
  const startOf = (c: Record<string, unknown>) =>
    context.photoOrder.get(c.first_photo_id as string)!;
  const ordered = [...context.photoOrder.entries()].sort((a, b) => a[1] - b[1])
    .map(([id]) => id);
  const groupOf = (at: number) => {
    let g = 0;
    while (g + 1 < required.length && at >= required[g + 1]) g++;
    return g;
  };
  const usedTitles = new Set<string>();
  return required.map((start, g) => {
    const end = required[g + 1] ?? ordered.length;
    const inside = old.filter((c) => groupOf(startOf(c)) === g);
    const covering = [...old].reverse().find((c) => startOf(c) <= start) ??
      old[0];
    const base = inside[0] ?? covering;
    // The director's title only for its own chapter (#450: a title moved
    // onto another day read "Куко Unreal" over AMF): the director chapter
    // most of this part's photos are in, with most of its own photos here.
    const sorted = [...old].sort((a, b) => startOf(a) - startOf(b));
    const spanOf = (c: Record<string, unknown>) => {
      const k = sorted.indexOf(c);
      return [
        startOf(c),
        k + 1 < sorted.length ? startOf(sorted[k + 1]) : ordered.length,
      ];
    };
    let title: string | null = null;
    for (const c of sorted) {
      const [from, to] = spanOf(c);
      const shared = Math.max(0, Math.min(to, end) - Math.max(from, start));
      if (
        shared * 2 >= end - start && shared * 2 >= to - from &&
        isString(c.title) && c.title.trim() && !usedTitles.has(c.title)
      ) {
        title = c.title;
        break;
      }
    }
    title ??= partTitle(ordered.slice(start, end), context, usedTitles);
    usedTitles.add(title);
    const moments = old.flatMap((c) =>
      Array.isArray(c.moments) ? c.moments as Record<string, unknown>[] : []
    ).filter((m) => typeof m === "object" && m !== null).map((m) => ({
      ...m,
      photo_ids: (Array.isArray(m.photo_ids) ? m.photo_ids : []).filter((
        id,
      ) => {
        const at = isString(id) ? context.photoOrder.get(id) : undefined;
        return at !== undefined && at >= start && at < end;
      }),
    })).filter((m) => (m.photo_ids as unknown[]).length > 0);
    const excerpts = old.flatMap((c) =>
      (Array.isArray(c.excerpts) ? c.excerpts as NeonNightExcerptPlan[] : [])
        .filter((e) => {
          const at = e.photo_id
            ? context.photoOrder.get(e.photo_id)
            : undefined;
          return at !== undefined ? groupOf(at) === g : c === base;
        })
    );
    return {
      ...base,
      title,
      first_photo_id: ordered[start],
      note_id: inside[0] ? base.note_id : null,
      note_excerpt: inside[0] ? base.note_excerpt : null,
      moments,
      excerpts: excerpts.slice(0, MAX_NN_EXCERPTS),
    };
  });
}

// Every chapter keeps a title that fits (#426): one over
// MAX_NN_TITLE_CHARS loses whole words from its end (never cut inside a
// word) — rather than the whole film falling back for one character; a
// missing one, or one that can't be shortened to at least 2 words' worth,
// takes its place, else its first photo's time.
function fitTitles(
  chapters: unknown[],
  context: NnCheckContext,
  // The Finale's headline: no title repeats it (#450).
  headline: string | null = null,
): void {
  const ordered = [...context.photoOrder.entries()].sort((a, b) => a[1] - b[1])
    .map(([id]) => id);
  const taken = new Set<string>(headline ? [headline] : []);
  for (const raw of chapters) {
    if (typeof raw !== "object" || raw === null) continue;
    const chapter = raw as Record<string, unknown>;
    let title = isString(chapter.title) ? cleanAiLine(chapter.title) : "";
    // In the notes' language (#448), unless it's a place's own name.
    const whole = title;
    if (
      title && titleInOtherLanguage(title, context) &&
      ![...(context.photoPlaces?.values() ?? [])].some((p) =>
        p.trim() === whole
      )
    ) title = "";
    // Too long: the part's own title — never cut mid-phrase (#450:
    // "Куко Unreal, home at").
    if ([...title].length > MAX_NN_TITLE_CHARS) title = "";
    if (title && isSensitive(title)) title = "";
    if (title && [...taken].some((t) => sameLine(t, title))) title = "";
    if (!title && isString(chapter.first_photo_id)) {
      const start = context.photoOrder.get(chapter.first_photo_id);
      const next = chapters
        .map((c) => (c as Record<string, unknown> | null)?.first_photo_id)
        .map((id) => isString(id) ? context.photoOrder.get(id) : undefined)
        .filter((at): at is number =>
          at !== undefined && start !== undefined &&
          at > start
        )
        .sort((a, b) => a - b)[0] ?? ordered.length;
      if (start !== undefined) {
        title = partTitle(ordered.slice(start, next), context, taken);
      }
    }
    if (title) {
      chapter.title = title;
      taken.add(title);
    }
  }
}

// The language the user writes in (#448): Russian when the notes' (else
// the captions') letters are ≥ 80 % Cyrillic, English when ≥ 80 % Latin;
// null when mixed or too few words to tell.
function notesLanguage(context: NnCheckContext): "ru" | "en" | null {
  for (
    const texts of [
      [...context.notes.values()],
      [...(context.photoCaptions?.values() ?? [])],
    ]
  ) {
    const text = texts.join(" ");
    const cyr = (text.match(/[\u0400-\u04FF]/g) ?? []).length;
    const lat = (text.match(/[A-Za-z]/g) ?? []).length;
    if (cyr + lat < 20) continue;
    // Mixed notes (neither ≥ 70 %: names like "Kuko", "AMF" don't make
    // Russian notes mixed) say nothing about the language.
    if (cyr >= 0.7 * (cyr + lat)) return "ru";
    if (lat >= 0.7 * (cyr + lat)) return "en";
    return null;
  }
  return null;
}

// Whether [title] is mostly written in another script than the notes
// (#448, #450: "Tallinn airport", "4.5kg ribs then Куко" over Russian
// notes; a name inside a Russian title is fine).
function titleInOtherLanguage(title: string, context: NnCheckContext): boolean {
  const cyr = (title.match(/[\u0400-\u04FF]/g) ?? []).length;
  const lat = (title.match(/[A-Za-z]/g) ?? []).length;
  const language = notesLanguage(context);
  if (language === null) return false;
  return language === "ru" ? lat > cyr : cyr > lat;
}

// A short line from the notes of [ids] (#448): those written during the
// part (up to 3 h after its last photo), else on its days; a whole
// sentence or clause that fits a title, the best-scoring. Null if none.
function notesTitle(
  ids: string[],
  context: NnCheckContext,
  duringOnly = false,
  taken: ReadonlySet<string> = new Set(),
): string | null {
  const times = ids.map((id) => context.photoTimes?.get(id))
    .filter((t): t is number => t !== undefined);
  const from = Math.min(...times);
  const to = Math.max(...times) + 3 * 60 * 60 * 1000;
  const days = new Set(ids.map((id) => context.photoDays?.get(id)));
  const during = [...context.notes.keys()].filter((id) => {
    const t = context.noteTimes?.get(id);
    return t !== undefined && t >= from && t <= to;
  });
  if (duringOnly && during.length === 0) return null;
  const own = duringOnly
    ? during
    : [...context.notes.keys()].filter((id) =>
      days.has(context.noteDays?.get(id))
    );
  let best: { text: string; score: number } | null = null;
  for (const id of own) {
    for (const sentence of excerptCandidates(context.notes.get(id)!)) {
      for (
        const clause of [sentence, ...sentence.split(/[,;:]\s|\s[—–-]\s/u)]
      ) {
        const text = clause.trim().replace(/[.!?…]+$/u, "");
        if ([...text].length > MAX_NN_TITLE_CHARS || !text.includes(" ")) {
          continue;
        }
        if (isSensitive(text) || isGeneric(text) || taken.has(text)) continue;
        if (bannedPhraseIn(text)) continue;
        const score = excerptScore(text, "night");
        if (best === null || score > best.score) best = { text, score };
      }
    }
  }
  return best?.text ?? null;
}

// "Day N" / "День N" in the notes' language (#448), N the day's place
// among the memory's photo days.
function dayTitle(
  ids: string[],
  context: NnCheckContext,
  taken: ReadonlySet<string> = new Set(),
): string {
  const all = [...new Set(context.photoDays?.values() ?? [])].sort();
  const n = Math.max(0, all.indexOf(context.photoDays?.get(ids[0]) ?? "")) +
    1;
  const day = notesLanguage(context) === "ru" ? `День ${n}` : `Day ${n}`;
  // A day in parts: "Day 1", "Day 1 · 2", …
  for (let k = 1;; k++) {
    const title = k === 1 ? day : `${day} · ${k}`;
    if (!taken.has(title)) return title;
  }
}

// The first caption of [ids] short enough for a title (#448): how the
// part opens.
function captionTitle(
  ids: string[],
  context: NnCheckContext,
  taken: ReadonlySet<string>,
): string | null {
  for (const id of ids) {
    const text = context.photoCaptions?.get(id)?.replace(/[.!?…]+$/u, "");
    if (!text || [...text].length > MAX_NN_TITLE_CHARS) continue;
    if (taken.has(text) || isSensitive(text) || isGeneric(text)) continue;
    if (bannedPhraseIn(text)) continue;
    return text;
  }
  return null;
}

// A part's title when the director gave none (#448, never a clock time):
// the place, else a line of the notes written during it, else one of its
// captions, else a line of its days' notes, else its day (#450: the
// chapter's own words before a caption like "some sweets for …"). Each
// in the notes' language. Never one
// [taken] already has.
function partTitle(
  ids: string[],
  context: NnCheckContext,
  taken: ReadonlySet<string> = new Set(),
): string {
  // In the notes' language, never a repeat (#450).
  const free = (t: string | null) =>
    t && ![...taken].some((u) => sameLine(u, t)) &&
      !titleInOtherLanguage(t, context)
      ? t
      : null;
  return free(placeOf(ids, context)) ??
    free(notesTitle(ids, context, true, taken)) ??
    free(captionTitle(ids, context, taken)) ??
    free(notesTitle(ids, context, false, taken)) ??
    dayTitle(ids, context, taken);
}

// The place most of [ids] share, short enough for a title; else null.
function placeOf(ids: string[], context: NnCheckContext): string | null {
  const counts = new Map<string, number>();
  for (const id of ids) {
    const place = context.photoPlaces?.get(id)?.trim();
    if (place && [...place].length <= MAX_NN_TITLE_CHARS) {
      counts.set(place, (counts.get(place) ?? 0) + 1);
    }
  }
  let best: string | null = null;
  for (const [place, n] of counts) {
    if (best === null || n > counts.get(best)!) best = place;
  }
  return best;
}

// An excerpt's photo must be its chapter's: else none (code matches it).
function fitExcerptPhotos(
  nn: Record<string, unknown>,
  context: NnCheckContext,
): void {
  const chapters = (nn.chapters as unknown[]).filter((c) =>
    typeof c === "object" && c !== null
  ) as Record<string, unknown>[];
  const starts = chapters.map((c) =>
    isString(c.first_photo_id)
      ? context.photoOrder.get(c.first_photo_id) ?? null
      : null
  );
  chapters.forEach((chapter, i) => {
    const start = starts[i];
    const end = starts.slice(i + 1).find((x) => x !== null) ??
      context.photoOrder.size;
    chapter.excerpts = (chapter.excerpts as NeonNightExcerptPlan[] ?? []).map(
      (e) => {
        const at = e.photo_id ? context.photoOrder.get(e.photo_id) : undefined;
        const own = at !== undefined && start !== null && at >= start &&
          at < end && !context.excludedIds.has(e.photo_id!);
        return own ? e : { ...e, photo_id: null };
      },
    );
  });
}

// A stored section healed to the memory as it is now (#393): a photo
// deleted or left out since the director ran no longer throws the whole
// film away. A chapter whose first photo is gone starts at its earliest
// remaining moment photo — inside its old span, so its moments stay its
// own — and one with none left folds into the chapter before. The note
// scene loses a background photo that's gone. Then [repairNeonNight]
// drops gone photos from moments, retypes them, and drops card lines or a
// note scene whose note no longer says those words. Never invents a
// photo; the caller still checks the result. Never throws.
export function healNeonNight(
  data: unknown,
  context: NnCheckContext,
): unknown {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return data;
  }
  const nn = structuredClone(data) as Record<string, unknown>;
  const known = (id: unknown): id is string =>
    isString(id) && context.photoOrder.has(id) && !context.excludedIds.has(id);
  if (Array.isArray(nn.chapters)) {
    nn.chapters = (nn.chapters as unknown[]).filter((raw) => {
      if (typeof raw !== "object" || raw === null) return true;
      const chapter = raw as Record<string, unknown>;
      if (known(chapter.first_photo_id)) return true;
      const remaining: string[] = [];
      for (const m of Array.isArray(chapter.moments) ? chapter.moments : []) {
        const ids = (m as Record<string, unknown> | null)?.photo_ids;
        if (Array.isArray(ids)) remaining.push(...ids.filter(known));
      }
      remaining.sort((a, b) =>
        context.photoOrder.get(a)! - context.photoOrder.get(b)!
      );
      if (remaining.length > 0) {
        chapter.first_photo_id = remaining[0];
        return true;
      }
      // Nothing of it left: the chapter before takes its span (for the
      // first chapter, repair starts the next one at the first photo).
      return false;
    });
  }
  const note = nn.note_moment as Record<string, unknown> | null | undefined;
  if (
    note && typeof note === "object" && note.photo_id != null &&
    !known(note.photo_id)
  ) {
    note.photo_id = null;
  }
  return repairNeonNight(nn, context);
}

// The moment types a photo count fits, most flexible first: what a moment
// becomes when its own type no longer fits (#382).
function typeFor(type: unknown, count: number): NnMomentType | null {
  const fits = (t: NnMomentType) =>
    count >= NN_MOMENT_PHOTOS[t][0] && count <= NN_MOMENT_PHOTOS[t][1];
  if (NN_MOMENT_TYPES.includes(type as NnMomentType)) {
    if (fits(type as NnMomentType)) return type as NnMomentType;
  }
  // Never a peak (#386).
  for (const t of ["timeline", "burst", "split"] as const) {
    if (fits(t)) return t;
  }
  return null;
}

// Fixes moments in code instead of discarding the section (#382): photos
// from another chapter (or unknown, or used twice) are dropped, a moment
// whose count no longer fits its type takes one that does (a 2-photo burst
// becomes a timeline), one under 2 photos goes, a chapter left with none
// gets a timeline over its photos, and Always picks without a moment join
// one of their chapter while there's room. Never invents a photo, never
// moves one out of its chapter, keeps time order.
function repairMoments(
  nn: Record<string, unknown>,
  context: NnCheckContext,
): void {
  const chapters = (nn.chapters as unknown[]).filter((c) =>
    typeof c === "object" && c !== null
  ) as Record<string, unknown>[];
  const ordered = [...context.photoOrder.entries()].sort((a, b) => a[1] - b[1])
    .map(([id]) => id);
  const starts = chapters.map((c) =>
    isString(c.first_photo_id)
      ? context.photoOrder.get(c.first_photo_id) ?? null
      : null
  );
  if (starts.some((s) => s === null)) return;
  const order = (id: string) => context.photoOrder.get(id)!;
  const used = new Set<string>();
  const notePhoto = (nn.note_moment as Record<string, unknown> | null)
    ?.photo_id;

  chapters.forEach((chapter, i) => {
    const start = starts[i]!;
    const end = starts[i + 1] ?? ordered.length;
    const own = (id: unknown): id is string =>
      isString(id) && context.photoOrder.has(id) &&
      !context.excludedIds.has(id) && order(id) >= start && order(id) < end;
    const moments: Record<string, unknown>[] = [];
    for (const m of Array.isArray(chapter.moments) ? chapter.moments : []) {
      if (typeof m !== "object" || m === null) continue;
      const moment = m as Record<string, unknown>;
      const ids = (Array.isArray(moment.photo_ids) ? moment.photo_ids : [])
        .filter((id) => own(id) && !used.has(id))
        .sort((a, b) => order(a) - order(b))
        .slice(0, NN_MOMENT_PHOTOS.timeline[1]);
      const type = typeFor(moment.type, ids.length);
      if (!type) continue;
      const max = NN_MOMENT_PHOTOS[type][1];
      const kept = ids.slice(0, max);
      for (const id of kept) used.add(id);
      moments.push({ ...moment, type, photo_ids: kept });
    }
    // A chapter keeps at most MAX_NN_MOMENTS (#422): a day chapter can
    // inherit the moments of every chapter the director made of that day.
    // The first stays; the others become one timeline of their photos.
    if (moments.length > MAX_NN_MOMENTS) {
      const rest = moments.splice(1).flatMap((m) => m.photo_ids as string[])
        .sort((a, b) => order(a) - order(b));
      for (const id of rest) used.delete(id);
      const ids = spreadEvenly(rest, NN_MOMENT_PHOTOS.timeline[1]);
      for (const id of ids) used.add(id);
      moments.push({ type: "timeline", photo_ids: ids });
    }
    const chapterPhotos = ordered.slice(start, end).filter((id) =>
      !context.excludedIds.has(id)
    );

    // Always picks of this chapter without a moment (or the Note scene).
    const missing = chapterPhotos.filter((id) =>
      context.mustIncludeIds.has(id) && !used.has(id) && id !== notePhoto
    );
    for (const moment of moments) {
      if (missing.length === 0) break;
      const ids = moment.photo_ids as string[];
      let type = moment.type as NnMomentType;
      while (missing.length > 0) {
        const grown = typeFor(type, ids.length + 1) ??
          typeFor("timeline", ids.length + 1);
        if (!grown) break;
        type = grown;
        ids.push(missing.shift()!);
      }
      ids.sort((a, b) => order(a) - order(b));
      moment.type = typeFor(type, ids.length) ?? type;
      for (const id of ids) used.add(id);
    }
    if (missing.length > 0 && moments.length < MAX_NN_MOMENTS) {
      // A new timeline: the missing picks, paired with an unused photo
      // when there's only one.
      const ids = missing.splice(0, NN_MOMENT_PHOTOS.timeline[1]);
      if (ids.length === 1) {
        const partner = chapterPhotos.find((id) =>
          !used.has(id) && id !== ids[0] && id !== notePhoto
        );
        if (partner) ids.push(partner);
      }
      if (ids.length >= 2) {
        ids.sort((a, b) => order(a) - order(b));
        for (const id of ids) used.add(id);
        moments.push({ type: "timeline", photo_ids: ids });
      }
    }
    if (moments.length === 0) {
      const free = chapterPhotos.filter((id) => !used.has(id));
      if (free.length >= 2) {
        const ids = spreadEvenly(free, NN_MOMENT_PHOTOS.timeline[1]);
        for (const id of ids) used.add(id);
        moments.push({ type: "timeline", photo_ids: ids });
      }
    }
    chapter.moments = moments;
  });
}

// --- The chosen film always plays (#433) --------------------------------

// A single night's chapters, when code plans it: parts split at the
// longest breaks of NN_PART_GAP_MS or more, each keeping at least this
// many photos, up to this many chapters.
const CODE_NN_PART_PHOTOS = 8; // MIN_NN_CHAPTER_PHOTOS
const CODE_NN_MAX_PARTS = 3;

// A chapter of at least this many photos gets two moments: a burst, then
// a timeline.
const CODE_NN_TWO_MOMENTS = 10;

const CODE_NN_TITLES: Record<WrapUpLanguage, { day: string; part: string }> = {
  en: { day: "Day", part: "Part" },
  ru: { day: "День", part: "Часть" },
};

// Where a single night's chapters start when code plans it.
function singleNightStarts(context: NnCheckContext, ordered: string[]) {
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
// sensitive, short enough to write out in neon. Null when none fits.
function codeNoteMoment(
  context: NnCheckContext,
): NeonNightPlan["note_moment"] {
  let best: { note_id: string; excerpt: string; score: number } | null = null;
  for (const [noteId, content] of context.notes) {
    for (const text of excerptCandidates(content)) {
      if (
        [...text].length > MAX_NN_NOTE_CHARS || isSensitive(text) ||
        !isExcerptOf(text, content)
      ) continue;
      const score = excerptScore(text, "night");
      if (score < SPECIFIC_SCORE) continue;
      if (!best || score > best.score) {
        best = { note_id: noteId, excerpt: text, score };
      }
    }
  }
  return best
    ? { note_id: best.note_id, excerpt: best.excerpt, photo_id: null }
    : null;
}

// A Neon Night plan built by code alone (#433), for when the director's
// can't be used: one chapter per part of the memory (each logical day or
// stretch of the night), titled by its place, else its first photo's
// time, else "Day N"; a burst and a timeline from its photos (one
// timeline for a small chapter); the note scene from the best line of the
// notes; no headline. The content picks the chapters' lines as it always
// does. Valid by construction for any memory with 2 or more photos.
export function codeNeonNight(
  context: NnCheckContext,
  language: WrapUpLanguage,
): NeonNightPlan {
  const ordered = [...context.photoOrder.entries()].sort((a, b) => a[1] - b[1])
    .map(([id]) => id).filter((id) => !context.excludedIds.has(id));
  const required = nnChapterStarts(context);
  const starts = required.length > 0
    ? required
    : singleNightStarts(context, ordered);
  const words = CODE_NN_TITLES[language];
  const usedTitles = new Set<string>();
  const chapters: NeonNightChapterPlan[] = starts.map((start, g) => {
    const end = starts[g + 1] ?? ordered.length;
    const photos = ordered.slice(start, end);
    let title = partTitle(photos, context, usedTitles);
    if (usedTitles.has(title) || isSensitive(title)) {
      title = wholeWords(`${title} ${g + 1}`, MAX_NN_TITLE_CHARS) ??
        `${words.part} ${g + 1}`;
    }
    usedTitles.add(title);
    const moments: NeonNightChapterPlan["moments"] = [];
    if (photos.length >= CODE_NN_TWO_MOMENTS) {
      const half = Math.floor(photos.length / 2);
      moments.push({
        type: "burst",
        photo_ids: spreadEvenly(
          photos.slice(0, half),
          NN_MOMENT_PHOTOS.burst[1],
        ),
      });
      moments.push({
        type: "timeline",
        photo_ids: spreadEvenly(
          photos.slice(half),
          NN_MOMENT_PHOTOS.timeline[1],
        ),
      });
    } else if (photos.length >= NN_MOMENT_PHOTOS.timeline[0]) {
      moments.push({
        type: "timeline",
        photo_ids: spreadEvenly(photos, NN_MOMENT_PHOTOS.timeline[1]),
      });
    }
    return {
      title,
      first_photo_id: ordered[start],
      note_id: null,
      note_excerpt: null,
      moments,
      excerpts: [],
    };
  });
  return { chapters, note_moment: codeNoteMoment(context), headline: null };
}

export interface EnsuredSection<T> {
  plan: T;
  // director: the director's section, repaired; code: built by code.
  source: "director" | "code";
  // What was wrong and put right, for the Plan inspector.
  repairs: string[];
}

// The Neon Night this memory plays (#433): the director's section with
// everything code can fix fixed — and when it still breaks a rule (or
// there's none), the code-built plan. Never null, never another film.
export function ensureNeonNight(
  raw: unknown,
  context: NnCheckContext,
  language: WrapUpLanguage,
): EnsuredSection<NeonNightPlan> {
  if (typeof raw === "object" && raw !== null && !Array.isArray(raw)) {
    let before: string[];
    let repaired: unknown;
    let after: string[];
    try {
      before = describeNeonNightProblems(raw, context);
      repaired = repairNeonNight(raw, context);
      after = describeNeonNightProblems(repaired, context);
    } catch (err) {
      // Repair never throws by design; if it ever does, the film still
      // plays — code's plan.
      before = [];
      after = [`repair failed: ${(err as Error).message}`];
    }
    if (after.length === 0) {
      return {
        plan: repaired as NeonNightPlan,
        source: "director",
        repairs: before.map((p) => `repaired: ${p}`),
      };
    }
    return {
      plan: codeNeonNight(context, language),
      source: "code",
      repairs: [
        ...after.map((p) => `couldn't repair: ${p}`),
        "code built the plan",
      ],
    };
  }
  return {
    plan: codeNeonNight(context, language),
    source: "code",
    repairs: ["no director section: code built the plan"],
  };
}

// --- Building content.neon_night -----------------------------------------

// 'HH:MM:SS' or 'HH:MM' → 'HH:MM'; anything else → null.
function clockOf(time: string | null | undefined): string | null {
  const m = /^(\d{2}):(\d{2})/.exec(time ?? "");
  return m ? `${m[1]}:${m[2]}` : null;
}

function planRows(tripData: TripData): NeonNightContent["plan"] {
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
function filmPhotos(photos: Photo[], named: ReadonlySet<string>): Photo[] {
  if (photos.length <= MAX_NN_PHOTOS) return photos;
  const kept = new Set([
    ...photos.filter((p) => named.has(p.id)),
    ...spreadEvenly(photos, MAX_NN_PHOTOS),
  ]);
  return photos.filter((p) => kept.has(p));
}

type ContentMoment = { type: NnMomentType; photo_ids: string[] };

interface ShapedChapter {
  title: string;
  note: string | null;
  photos: Photo[];
  card: string[];
  moments: ContentMoment[];
  // The director's excerpts (#398), for [pickExcerpts].
  excerpts: NeonNightExcerptPlan[];
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

function timeOf(p: Photo): number {
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
  chapter: ShapedChapter,
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

// The chapters as the film plays them (#386, #390):
// 1. neighbours merge while one has fewer than MIN_NN_CHAPTER_PHOTOS
//    (the earlier one's title, the first note line); a merged chapter
//    keeps its first moment plus one timeline of the others' photos;
// 2. each card gets its own photos — ones no moment or the note scene
//    shows, captioned first; else taken from a moment that keeps 2;
// 3. each timeline is filled to NN_TIMELINE_FILL with what's left (Always
//    picks first), then every moment settles its type (settledType).
// No photo is in two places; time order throughout.
function shapeChapters(
  chapterPhotos: Photo[][],
  plan: NeonNightPlan,
  // A several-day memory's chapters are its days (#398 R1): never merged
  // for being small — only past [maxChapters].
  byDays = false,
  // The most chapters the film's length holds (#434).
  maxChapters = MAX_NN_CHAPTERS,
  // Which photos a full moment keeps (#446).
  heroScores: Readonly<Record<string, number>> = {},
): ShapedChapter[] {
  const chapters: ShapedChapter[] = plan.chapters.map((chapter, i) => ({
    title: chapter.title,
    note: chapter.note_id && chapter.note_excerpt
      ? collapse(chapter.note_excerpt)
      : null,
    photos: chapterPhotos[i],
    card: [],
    moments: chapter.moments.map((m) => ({
      type: m.type,
      photo_ids: [...m.photo_ids],
    })),
    excerpts: [...(chapter.excerpts ?? [])],
  }));

  // 1. Merge: small chapters, and only past MAX_NN_CHAPTERS — never for
  // the film's length (#444: days and parts are the story).
  while (chapters.length > 1) {
    const tooMany = chapters.length > maxChapters;
    if (byDays && !tooMany) break;
    let small = -1;
    for (let i = 0; i < chapters.length; i++) {
      if (!tooMany && chapters[i].photos.length >= MIN_NN_CHAPTER_PHOTOS) {
        continue;
      }
      if (
        small === -1 ||
        chapters[i].photos.length < chapters[small].photos.length
      ) {
        small = i;
      }
    }
    if (small === -1) break;
    const left = small - 1;
    const right = small + 1;
    const other = left < 0
      ? right
      : right >= chapters.length
      ? left
      : chapters[left].photos.length <= chapters[right].photos.length
      ? left
      : right;
    const [a, b] = other < small ? [other, small] : [small, other];
    const first = chapters[a];
    const second = chapters[b];
    chapters.splice(a, 2, {
      title: first.title,
      note: first.note ?? second.note,
      photos: [...first.photos, ...second.photos],
      card: [],
      moments: [...first.moments, ...second.moments],
      excerpts: [...first.excerpts, ...second.excerpts],
    });
  }

  const notePhoto = plan.note_moment?.photo_id ?? null;
  for (const chapter of chapters) dealChapter(chapter, notePhoto, heroScores);
  return chapters;
}

// Brings each of [excerpts]' photos into a moment of [chapter] (#444):
// one on the card trades places with the moment photo nearest it in time;
// one in no scene takes that photo's place. Scenes stay in time order.
function bringLinePhotos(
  chapter: ShapedChapter,
  excerpts: NeonNightContentExcerpt[],
  heroScores: Readonly<Record<string, number>> = {},
): void {
  const at = new Map(chapter.photos.map((p, k) => [p.id, k]));
  const t = (id: string) =>
    timeOf(chapter.photos[at.get(id) ?? 0] ?? chapter.photos[0]);
  for (const e of excerpts) {
    const id = e.photo_id;
    if (id === null || !at.has(id)) continue;
    if (chapter.moments.some((m) => m.photo_ids.includes(id))) continue;
    // The moment photo nearest in time that no other line holds.
    const held = new Set(excerpts.map((x) => x.photo_id));
    let best: { m: ContentMoment; k: number } | null = null;
    for (const m of chapter.moments) {
      m.photo_ids.forEach((other, k) => {
        if (held.has(other)) return;
        if (
          best === null ||
          Math.abs(t(other) - t(id)) <
            Math.abs(t(best.m.photo_ids[best.k]) - t(id))
        ) best = { m, k };
      });
    }
    const c = chapter.card.indexOf(id);
    const first = chapter.moments[0];
    if (c >= 0) {
      // On the card: the card ends before it, and it and the card's later
      // photos open the first moment — still in time order. Not for the
      // card's first photo, or past a timeline's room.
      const moved = chapter.card.slice(c);
      if (
        c < MIN_NN_CARD_PHOTOS || !first ||
        first.photo_ids.length + moved.length > NN_TIMELINE_ROOM
      ) continue;
      chapter.card = chapter.card.slice(0, c);
      const ids = [...moved, ...first.photo_ids];
      chapter.moments[0] = momentFor(
        chapter.photos.filter((p) => ids.includes(p.id)),
        heroScores,
      );
      continue;
    }
    // In no scene (past a moment's room): it takes the place of the moment
    // photo nearest it in time.
    if (best === null) continue;
    const { m, k } = best as { m: ContentMoment; k: number };
    m.photo_ids[k] = id;
    m.photo_ids.sort((a, b) => (at.get(a) ?? 0) - (at.get(b) ?? 0));
  }
}

// The Note scene code picks when the director's is blocked (#444): the
// best-scoring specific line of any note that no chapter plays, short
// enough for the scene and nothing sensitive. Null when there is none.
// A line no other scene shows (#448: [isShown]); a specific one first,
// else any that isn't generic.
function fallbackNoteMoment(
  tripData: TripData,
  isShown: (text: string) => boolean,
  maxChars = MAX_NN_NOTE_CHARS,
): NeonNightPlan["note_moment"] {
  let best: { note_id: string; excerpt: string; score: number } | null = null;
  for (const n of tripData.notes) {
    if (!n.id || !n.content.trim()) continue;
    for (const text of excerptCandidates(n.content)) {
      if (isShown(text) || isSensitive(text) || isGeneric(text)) continue;
      if ([...text].length > maxChars) continue;
      const score = excerptScore(text, "night");
      if (best === null || score > best.score) {
        best = { note_id: n.id, excerpt: text, score };
      }
    }
  }
  if (best === null) return null;
  const note = tripData.notes.find((n) => n.id === best!.note_id);
  const shown = note?.photo_id &&
      tripData.photos.some((p) =>
        p.id === note.photo_id && p.use_in_wrap_up !== false
      )
    ? note.photo_id
    : null;
  return { note_id: best.note_id, excerpt: best.excerpt, photo_id: shown };
}

// At most this many photos of a moment show words (#448): lines and
// captions; the others play with no label.
export const MAX_NN_MOMENT_WORDS = 3;
// A moment's words fit this long a scene (#448).
export const MAX_NN_SCENE_SECONDS = 12;
// A film that runs long types only lines this short on its cards (#448),
// when the chapter has one.
export const MIN_NN_SHORT_CARD_CHARS = 30;

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

// The words each of [chapter]'s moments shows (#448): per photo its line
// (an excerpt placed on it, never the card's), else its caption; at most
// [maxWords] a moment, within MAX_NN_SCENE_SECONDS — lines first, then
// Always picks, captioned photos, the highest hero score; the rest play
// with no label.
export function momentWords(
  chapter: ShapedChapter,
  excerpts: readonly NeonNightContentExcerpt[],
  cardLine: string | null,
  byId: ReadonlyMap<string, Photo>,
  heroScores: Readonly<Record<string, number>>,
  maxWords = MAX_NN_MOMENT_WORDS,
  // The chapter's title: no line repeats it (#448).
  title: string | null = null,
  maxChars = Infinity,
  // The Note scene's line: never in a moment.
  reserved: string | null = null,
): { photo_id: string; text: string }[][] {
  const taken: string[] = [cardLine, title, reserved].filter((t): t is string =>
    !!t
  );
  return chapter.moments.map((m) => {
    const options = m.photo_ids.flatMap((id) => {
      // A line nothing else shows (#448: not the card's, nor one it types
      // a clause of); else the photo's caption.
      const line = excerpts.find((e) =>
        e.photo_id === id &&
        !taken.some((t) => overlaps(t, e.text)) &&
        !repeatsTitle(e.text, title) && !isDrugReference(e.text) &&
        [...e.text].length <= maxChars
      );
      const photo = byId.get(id);
      const raw = photo?.caption?.trim();
      const caption = raw && [...raw].length <= maxChars ? raw : undefined;
      const text = line?.text ?? caption;
      if (!text) return [];
      // A line, Always, captioned, hero score; then the more specific words.
      const rank = (line ? 1000 + line.score : 0) +
        (photo?.use_in_wrap_up === true ? 100 : 0) +
        (caption ? 10 : 0) + (heroScores[id] ?? 0) +
        Math.max(0, excerptScore(text, "night")) / 100 + [...text].length / 1e4;
      return [{ photo_id: id, text, rank }];
    }).sort((a, b) => b.rank - a.rank);
    const chosen: { photo_id: string; text: string }[] = [];
    for (const o of options) {
      if (chosen.length >= maxWords) break;
      if (taken.some((t) => overlaps(t, o.text))) continue;
      if (repeatsTitle(o.text, title)) continue;
      const lines = [...chosen.map((c) => c.text), o.text];
      const beats = nnMomentBeats({
        type: m.type as NnShapeMoment["type"],
        photos: m.photo_ids.length,
        lines,
      });
      if (beats > nnBeatsFor(MAX_NN_SCENE_SECONDS)) continue;
      chosen.push({ photo_id: o.photo_id, text: o.text });
      taken.push(o.text);
    }
    const at = new Map(m.photo_ids.map((id, k) => [id, k]));
    return chosen.sort((a, b) => at.get(a.photo_id)! - at.get(b.photo_id)!);
  });
}

interface PickedLines {
  excerpts: NeonNightContentExcerpt[];
  days: string[];
  rejected: { text: string; score: number }[];
}

// Each chapter's lines (#398 R3/R4). Its notes are the ones on its days
// (a single night: written between its first photo and the next chapter's)
// plus notes on its photos. The director's excerpts come first — minus a
// generic one while a specific line is left, and anything sensitive; then
// the best-scoring specific lines fill up to MIN_NN_EXCERPTS. Each line
// plays over its note's photo, else the chapter's photo nearest the note
// in time. Lines in time order; no note line in two chapters.
export function pickExcerpts(
  tripData: TripData,
  chapters: readonly { photos: Photo[]; excerpts: NeonNightExcerptPlan[] }[],
  days: ReadonlyMap<string, string | null>,
): PickedLines[] {
  const timeOf = (iso: string | null | undefined) =>
    iso ? Date.parse(iso) : NaN;
  const notes = tripData.notes.filter((n) => n.id && n.content.trim());
  const noteTime = (n: TripData["notes"][number]) =>
    n.legacy ? NaN : timeOf(n.taken_at ?? n.created_at);
  const chapterDays = chapters.map((c) =>
    [
      ...new Set(c.photos.map((p) => days.get(p.id)).filter(isString)),
    ].sort()
  );
  const multiDay = new Set(chapterDays.flat()).size > 1;
  const spans = chapters.map((c, i) => {
    const start = timeOf(c.photos[0]?.taken_at ?? c.photos[0]?.created_at);
    const next = chapters[i + 1]?.photos[0];
    return {
      start: i === 0 ? -Infinity : start,
      end: next ? timeOf(next.taken_at ?? next.created_at) : Infinity,
    };
  });
  const owner = new Map<string, number>();
  for (const n of notes) {
    const own = chapters.findIndex((c) =>
      c.photos.some((p) => p.id === n.photo_id)
    );
    if (own >= 0) {
      owner.set(n.id!, own);
      continue;
    }
    const day = days.get(`note:${n.id}`) ?? n.day_date;
    const t = noteTime(n);
    const byDay = chapterDays.findIndex((d) => d.includes(day));
    // Within its day, the part it was written in (#448: a day in parts
    // gave every note to its first part, so later parts had no line).
    const bySpan = Number.isNaN(t)
      ? -1
      : spans.findIndex((s) => t >= s.start && t < s.end);
    const i = !multiDay
      ? (Number.isNaN(t) ? byDay : bySpan)
      : bySpan >= 0 && chapterDays[bySpan].includes(day)
      ? bySpan
      : byDay;
    if (i >= 0) owner.set(n.id!, i);
  }
  const used = new Set<string>();

  const picked = chapters.map((chapter, i) => {
    const own = notes.filter((n) => owner.get(n.id!) === i);
    const nearest = (n: TripData["notes"][number]): string | null => {
      if (chapter.photos.some((p) => p.id === n.photo_id)) return n.photo_id!;
      const t = noteTime(n);
      if (Number.isNaN(t) || chapter.photos.length === 0) return null;
      let best = chapter.photos[0];
      for (const p of chapter.photos) {
        if (
          Math.abs(timeOf(p.taken_at ?? p.created_at) - t) <
            Math.abs(timeOf(best.taken_at ?? best.created_at) - t)
        ) best = p;
      }
      return best.id;
    };
    const candidates = own.flatMap((n) =>
      excerptCandidates(n.content).map((text, k) => ({
        note: n,
        text,
        k,
        score: excerptScore(text, "night"),
      }))
      // The user's own words show as written (#448): the sensitive-words
      // rule is for AI-written lines and the Note scene only.
    ).filter((c) => !used.has(c.text));
    const specificLeft = () =>
      candidates.filter((c) => !used.has(c.text) && c.score >= SPECIFIC_SCORE);

    const chosen: (NeonNightContentExcerpt & { at: number; k: number })[] = [];
    const take = (
      note: TripData["notes"][number],
      text: string,
      photo: string | null,
      source: "director" | "code",
      k: number,
    ) => {
      used.add(text);
      const photoOk = photo && chapter.photos.some((p) => p.id === photo);
      chosen.push({
        text,
        note_id: note.id!,
        photo_id: photoOk ? photo : nearest(note),
        source,
        score: excerptScore(text, "night"),
        at: noteTime(note),
        k,
      });
    };
    for (const e of chapter.excerpts) {
      const note = own.find((n) => n.id === e.note_id) ??
        notes.find((n) => n.id === e.note_id);
      if (!note || used.has(e.text)) continue;
      if (isGeneric(e.text) && specificLeft().length > 0) continue;
      take(note, e.text, e.photo_id, "director", note.content.indexOf(e.text));
    }
    const fill = specificLeft().filter((c) =>
      !chosen.some((x) => x.text.includes(c.text) || c.text.includes(x.text))
    ).sort((a, b) => b.score - a.score);
    for (const c of fill) {
      if (chosen.length >= MIN_NN_EXCERPTS) break;
      take(c.note, c.text, null, "code", c.k);
    }
    chosen.sort((a, b) =>
      (Number.isNaN(a.at) ? 0 : a.at) - (Number.isNaN(b.at) ? 0 : b.at) ||
      a.k - b.k
    );
    const rejected = candidates.filter((c) => !used.has(c.text))
      .sort((a, b) => b.score - a.score).slice(0, 5)
      .map((c) => ({ text: c.text, score: c.score }));
    return {
      excerpts: chosen.slice(0, MAX_NN_EXCERPTS).map((
        { at: _a, k: _k, ...e },
      ) => e),
      days: chapterDays[i],
      rejected,
    };
  });
  capLines(picked);
  return picked;
}

// At most WRAP_UP_LIMITS.maxNoteLines lines in the whole film (#433): the
// lowest-scoring go first, from the chapter with the most lines, so each
// chapter keeps its best.
function capLines(picked: PickedLines[]): void {
  const total = () => picked.reduce((n, p) => n + p.excerpts.length, 0);
  while (total() > WRAP_UP_LIMITS.maxNoteLines) {
    const most = picked.reduce((a, b) =>
      b.excerpts.length > a.excerpts.length ? b : a
    );
    let worst = 0;
    most.excerpts.forEach((e, k) => {
      if (e.score < most.excerpts[worst].score) worst = k;
    });
    const [gone] = most.excerpts.splice(worst, 1);
    most.rejected.unshift({ text: gone.text, score: gone.score });
  }
}

// content.neon_night from a valid, current [plan].
export function buildNeonNightContent(
  tripData: TripData,
  plan: NeonNightPlan,
  // The director's analysis (#446): the card zooms its best photos.
  heroScores: Readonly<Record<string, number>> = {},
): NeonNightContent {
  const all = nnPhotos(tripData);
  const order = new Map(all.map((p, i) => [p.id, i]));
  const named = new Set<string>([
    ...plan.chapters.flatMap((c) => [
      c.first_photo_id,
      ...c.moments.flatMap((m) => m.photo_ids),
    ]),
    ...(plan.note_moment?.photo_id ? [plan.note_moment.photo_id] : []),
  ]);
  const film = filmPhotos(all, named);
  const shown = new Set(film.map((p) => p.id));
  const byId = new Map(all.map((p) => [p.id, p]));
  const notes = [...tripData.notes].sort((a, b) =>
    a.day_date < b.day_date ? -1 : a.day_date > b.day_date ? 1 : 0
  );

  const starts = plan.chapters.map((c) => order.get(c.first_photo_id)!);
  const chapterPhotos = plan.chapters.map((_, i) =>
    all.slice(starts[i], starts[i + 1] ?? all.length).filter((p) =>
      shown.has(p.id)
    )
  );
  const days = nnLogicalDays(tripData);
  const byDays = dayChapterStarts({
    photoOrder: order,
    excludedIds: new Set(),
    mustIncludeIds: new Set(),
    notes: new Map(),
    photoDays: new Map(
      all.flatMap((p) => {
        const d = days.get(p.id);
        return d ? [[p.id, d] as [string, string]] : [];
      }),
    ),
  }).length > 0;
  // The film's length (#434): as many chapters as it holds, then, while
  // the film runs over, a chapter's second moment goes (the longest
  // first, from the last chapter), then the Plan scene, then the Note.
  const seconds = filmSecondsOf(tripData);
  const shaped = shapeChapters(
    chapterPhotos,
    plan,
    byDays,
    MAX_NN_CHAPTERS,
    heroScores,
  )
    // A chapter plays while it has photos to show (#444: a small one is
    // its card alone).
    .filter((c) => c.card.length > 0 || c.moments.length > 0);
  const plan_ = planRows(tripData);
  let showsPlan = plan_.length > 0;
  let noteMoment: NeonNightPlan["note_moment"] = null;
  let picked = pickExcerpts(tripData, shaped, days);
  const place = () =>
    shaped.forEach((c, i) =>
      bringLinePhotos(c, picked[i].excerpts, heroScores)
    );
  place();
  // How much each scene may show (#448): words per moment (lines and
  // captions), and the zooms per card.
  let maxWords = MAX_NN_MOMENT_WORDS;
  let cardZooms = 2;
  // The longest card line (#448: shorter when the film runs long).
  let cardChars = MAX_NN_CARD_NOTE_CHARS;
  // The Note scene (#448: no line twice): the director's pick, else code's
  // best line no card, moment or title shows.
  const noteFor = (): NeonNightPlan["note_moment"] => {
    const shownWords = shaped.flatMap((c, i) => [
      c.title,
      ...(cardLineOf(i) ? [cardLineOf(i)!] : []),
      ...wordsOf(i).flat().map((w) => w.text),
    ]);
    // A line that opens with a chapter's title repeats it too (#448).
    const isShown = (text: string) =>
      shownWords.some((w) => overlaps(w, text)) ||
      shaped.some((c) => repeatsTitle(text, c.title));
    if (plan.note_moment && !isShown(plan.note_moment.excerpt)) {
      return plan.note_moment;
    }
    return fallbackNoteMoment(tripData, isShown);
  };
  // The director's Note line is the Note's (#448): no card or moment
  // takes it.
  const reserved = plan.note_moment?.excerpt ?? null;
  // Whether a line belongs with chapter [i]'s photos (#450: "Приземлились
  // в Амстердаме" over the Tallinn departure): its note is on one of them,
  // or was written from 30 min before its first photo to 90 min after its
  // last. A note without a time belongs where code put it.
  const noteOf = (text: string) =>
    tripData.notes.find((n) => n.content.includes(text)) ??
      tripData.notes.find((n) => sameLine(n.content, text));
  const nearChapter = (i: number, text: string): boolean => {
    const note = noteOf(text);
    if (!note) return true;
    const ids = new Set(shaped[i].photos.map((p) => p.id));
    if (note.photo_id && ids.has(note.photo_id)) return true;
    const at = Date.parse(note.taken_at ?? note.created_at ?? "");
    const times = shaped[i].photos.map((p) =>
      Date.parse(p.taken_at ?? p.created_at)
    ).filter((t) => !Number.isNaN(t));
    if (Number.isNaN(at) || times.length === 0) return true;
    return at >= Math.min(...times) - 30 * 60_000 &&
      at <= Math.max(...times) + 90 * 60_000;
  };
  const onCard = (i: number, e: object) => {
    const id = (e as { photo_id?: string | null }).photo_id;
    return !!id && shaped[i].card.includes(id);
  };
  // The card types its chapter's best line (#448: the highest score that
  // fits a card; the director's when it scores as well).
  const cardLineOf = (i: number): string | null => {
    // Its lines, else one left out (#448: every chapter with notes shows
    // one — a line too long to show leaves the next best).
    // A line too long for a card offers its clauses too (#448: the
    // user's exact words, "нокаут во втором раунде и весь бар орал").
    const clauses = [...picked[i].excerpts, ...picked[i].rejected].flatMap(
      (e) =>
        [...e.text].length <= cardChars ? [] : e.text.split(/(?<=[,;:])\s+/u)
          .map((c) => c.replace(/[,;:]$/u, "").trim())
          .filter((c) => c.split(/\s+/u).length >= 3)
          .map((text) => ({ text, score: excerptScore(text, "night") - 1 })),
    );
    const fits = [
      ...picked[i].excerpts,
      ...picked[i].rejected,
      ...clauses,
    ].filter((e) =>
      [...e.text].length <= cardChars && !isGeneric(e.text) &&
      !isDrugReference(e.text) &&
      !(reserved && sameLine(e.text, reserved)) &&
      !repeatsTitle(e.text, shaped[i].title) && nearChapter(i, e.text)
    ).sort((a, b) =>
      // A specific line before any other (#450: never "Проснулись…" while
      // "Брюссель не меняется…" is unused), then the higher score.
      Number(b.score >= SPECIFIC_SCORE) - Number(a.score >= SPECIFIC_SCORE) ||
      b.score - a.score ||
      // A line whose photo is on the card plays there (#444: over its
      // own photo).
      Number(onCard(i, b)) - Number(onCard(i, a)) ||
      Number(!picked[i].excerpts.includes(a as never)) -
        Number(!picked[i].excerpts.includes(b as never))
    );
    const own = shaped[i].note &&
        !(reserved && sameLine(shaped[i].note!, reserved)) &&
        !repeatsTitle(shaped[i].note!, shaped[i].title) &&
        !isGeneric(shaped[i].note!) && !isDrugReference(shaped[i].note!) &&
        nearChapter(i, shaped[i].note!)
      ? shaped[i].note
      : null;
    const ownFits = own !== null && [...own].length <= cardChars;
    if (ownFits && (!fits[0] || excerptScore(own!, "night") >= fits[0].score)) {
      return own;
    }
    // Shortened for length: only a line as good as the full one (#450:
    // never "потом поехали в Брюссель" for "Брюссель не меняется…");
    // else the line as it was — never no line for length.
    if (cardChars < MAX_NN_CARD_NOTE_CHARS) {
      const short = cardChars;
      cardChars = MAX_NN_CARD_NOTE_CHARS;
      const full = cardLineOf(i);
      cardChars = short;
      const score = (t: string | null) =>
        t === null ? -Infinity : excerptScore(t, "night");
      if (!fits[0] || score(fits[0].text) < score(full)) return full;
      return fits[0].text;
    }
    if (fits[0]) return fits[0].text;
    return own;
  };
  const wordsOf = (i: number) =>
    momentWords(
      shaped[i],
      picked[i].excerpts.filter((e) => nearChapter(i, e.text)),
      cardLineOf(i),
      byId,
      heroScores,
      maxWords,
      shaped[i].title,
      Infinity,
      reserved,
    );
  const beats = () =>
    nnFilmBeats(
      shaped.map((c, i) => {
        const words = wordsOf(i);
        return {
          // The card zooms its own photos (NnReadingTime: cardPhotos).
          photos: c.card.length || c.photos.length,
          zooms: cardZooms,
          cardCaptions: (c.card.length ? c.card : c.photos.map((p) => p.id))
            .map((id) => byId.get(id)?.caption?.trim() || null),
          cardHeroScores: (c.card.length ? c.card : c.photos.map((p) => p.id))
            .map((id) => heroScores[id] ?? null),
          cardLine: cardLineOf(i),
          moments: c.moments.map((m, j) => ({
            type: m.type,
            photos: m.photo_ids.length,
            lines: words[j].map((w) => w.text),
          })),
        };
      }),
      showsPlan,
      noteFor()?.excerpt ?? true,
    );
  // A Neon film may run up to the longest film (#448: 75 s, a hard max)
  // whatever its target; only past that it trims, in order: words per
  // moment (3 → 2), a chapter's two moments into one (the last chapter
  // first), the Plan scene, long card lines, then card zooms (2 → 1, never
  // none). Never a chapter, the Note scene or a chapter's line.
  const limit = Math.max(seconds, WRAP_UP_LIMITS.longestFilmSeconds);
  while (!nnFitsWithin(beats(), limit)) {
    const two = shaped.map((c, i) => ({ c, i })).filter(({ c }) =>
      c.moments.length > 1
    ).pop();
    if (maxWords > 2) maxWords--;
    else if (two) {
      const ids = new Set(two.c.moments.flatMap((m) => m.photo_ids));
      two.c.moments = [
        momentFor(two.c.photos.filter((p) => ids.has(p.id)), heroScores),
      ];
      picked = pickExcerpts(tripData, shaped, days);
      place();
    } else if (showsPlan) showsPlan = false;
    else if (cardChars > MIN_NN_SHORT_CARD_CHARS) {
      cardChars = MIN_NN_SHORT_CARD_CHARS;
    } else if (cardZooms > 1) cardZooms--;
    else break;
  }
  noteMoment = noteFor();
  const chapters = shaped.map((chapter, i) => {
    const lines = picked[i];
    const words = wordsOf(i);
    return {
      title: chapter.title,
      photos: chapter.photos.map((p) => ({
        id: p.id,
        taken_at: p.taken_at ?? p.created_at,
        // The user's own words on the photo (#387): the zoom and timeline
        // labels show it instead of the time.
        caption: p.caption?.trim() || null,
        // How good a shot it is (#446, 1–5; null = not analysed): the
        // card zooms its best photos.
        hero_score: heroScores[p.id] ?? null,
      })),
      card_photo_ids: chapter.card,
      // The card's typed line: the director's, else the first line short
      // enough for a card (#398).
      note: tidyEnd(cardLineOf(i)),
      // How many photos the card zooms (#448): fewer when the film runs
      // long; absent in older content = 2.
      card_zooms: cardZooms,
      excerpts: lines.excerpts,
      days: lines.days,
      rejected_excerpts: lines.rejected,
      moments: chapter.moments.map((m, j) => ({
        type: m.type,
        photo_ids: m.photo_ids,
        // The words it shows (#448): at most MAX_NN_MOMENT_WORDS, each on
        // its photo — a line, Always, captioned, then hero score first.
        // The others play with no label. Absent in older content.
        words: words[j].map((w) => ({ ...w, text: tidyEnd(w.text)! })),
        place: m.type === "split"
          ? m.photo_ids.map((id) => byId.get(id)?.place_text?.trim())
            .find((place) => place) || null
          : null,
      })),
    };
  });

  const noteIndex = noteMoment
    ? notes.findIndex((n) => n.id === noteMoment.note_id)
    : -1;
  const { start_date } = tripData.trip;
  return {
    nn_version: NN_VERSION,
    title: tripData.trip.name,
    start_date,
    place: tripData.trip.destination?.trim() || null,
    plan: showsPlan ? plan_ : [],
    chapters,
    note: noteMoment && noteIndex >= 0
      ? {
        text: tidyEnd(noteMoment.excerpt)!,
        number: noteIndex + 1,
        written_at: notes[noteIndex].created_at ?? null,
        photo_id: noteMoment.photo_id,
      }
      : null,
    headline: plan.headline,
    first_name: firstNameOf(tripData.username),
    totals: {
      photos: all.length,
      notes: notes.filter((n) => n.content.trim()).length,
      ticks: plan_.filter((r) => r.done).length,
      moments: all.length,
    },
    // The heart is decoration: Always picks already have their moment, so
    // it's made from the other photos (#378).
    heart_photo_ids: decorativePhotos(
      film,
      new Set([
        ...shaped.flatMap((c) => [
          ...c.card,
          ...c.moments.flatMap((m) => m.photo_ids),
        ]),
        ...(noteMoment?.photo_id ? [noteMoment.photo_id] : []),
      ]),
      MAX_NN_PHOTOS,
    ).map((p) => p.id),
  };
}
