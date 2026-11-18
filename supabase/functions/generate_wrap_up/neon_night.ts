// Neon Night (#363, phase 9): the beat-synced party film, stored as
// wrap_ups.content.neon_night next to everything the other films read.
//
// Only the director makes one: its `neon_night` section, emitted for a
// party, a rave, a club night, a festival, a concert or any night out,
// validated here against the memory as it is now. There is no code-built
// Neon Night — no section (another occasion, the director off or failed, a
// section still invalid after its retry, one that no longer fits) means
// the next film plays instead.
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
import { bannedPhraseIn, cleanLine } from "./film_plan.ts";
import { isExcerptOf } from "./golden_vows.ts";
import { firstNameOf } from "./sky_story.ts";
import { logicalDays } from "./logical_day.ts";
import {
  excerptCandidates,
  excerptScore,
  isGeneric,
  isSensitive,
  MAX_EXCERPT_CHARS,
  SPECIFIC_SCORE,
} from "./excerpts.ts";

export const NN_VERSION = 1;

export const NN_MOMENT_TYPES = ["split", "burst", "timeline", "peak"] as const;
export type NnMomentType = typeof NN_MOMENT_TYPES[number];

// Photos per moment, as [min, max] (NEON_NIGHT_SPEC.md §7).
export const NN_MOMENT_PHOTOS: Record<NnMomentType, [number, number]> = {
  split: [2, 3],
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
export const MAX_NN_EXCERPTS = 4;

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
    photos: { id: string; taken_at: string; caption: string | null }[];
    // The card's own photos (#390): its grid and zooms, never a moment's.
    // Older content has none — the app then uses every chapter photo.
    card_photo_ids: string[];
    // The user's own words, or null for no typed line: the first excerpt.
    note: string | null;
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
    "The Neon Night film: a loud, beat-synced neon party film. Only for a party, a rave, a club night, a festival, a concert or another night out; null for every other memory.",
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
  "\n\nneon_night — a fourth film, a loud neon party film. Fill it only ",
  "when the memory is a party, a rave, a club night, a festival, a concert ",
  "or another night out (from its name, vibes, notes and photos); ",
  "otherwise null. When unsure, null. Never fill both golden_vows and ",
  "neon_night.\n",
  "- Strict chronology: everything plays in time order. Photos are listed ",
  "in time order; a moment's photos and a chapter's moments follow it, and ",
  "no scene shows a photo older than the scene before.\n",
  `- chapters: ${MIN_NN_CHAPTERS}–${MAX_NN_CHAPTERS}. Each photo's \`day\` is `,
  "its logical day (the night until about 08:00 belongs to the evening ",
  "before). Several days: exactly one chapter per day, starting at that ",
  "day's first photo — never two days in one chapter; a day in another ",
  `place always has its own. More than ${MAX_NN_CHAPTERS} days: group `,
  "neighbouring days. One day or night: split it by time into parts ",
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
}

// Every photo's and note's logical day (#398 R1), photos and notes taken
// together in time order, on the app's clock.
export function nnLogicalDays(tripData: TripData): Map<string, string | null> {
  return logicalDays(
    [
      ...tripData.photos.map((p) => ({
        id: p.id,
        at: p.taken_at ?? p.created_at,
        fallbackDay: p.day_date,
      })),
      ...tripData.notes.filter((n) => n.id).map((n) => ({
        id: `note:${n.id}`,
        // A legacy note's time is its last edit: its day is its own.
        at: n.legacy ? null : n.taken_at ?? null,
        fallbackDay: n.day_date,
      })),
    ],
    tripData.utc_offset_minutes ?? 0,
  );
}

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

// Where the chapters of a several-day memory must start (#398 R1): each
// day's first photo, neighbouring days grouped evenly when there are more
// than MAX_NN_CHAPTERS. Empty for a single day: the director splits it.
export function dayChapterStarts(context: NnCheckContext): number[] {
  const days = dayStarts(context.photoOrder, context.photoDays);
  if (days.length <= 1) return [];
  if (days.length <= MAX_NN_CHAPTERS) return days.map((d) => d.start);
  const starts: number[] = [];
  for (let g = 0; g < MAX_NN_CHAPTERS; g++) {
    starts.push(days[Math.floor(g * days.length / MAX_NN_CHAPTERS)].start);
  }
  return starts;
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
  };
}

// The photos a section gives a moment of their own: every moment's, and
// the Note scene's background.
function momentPhotoIds(nn: Record<string, unknown>): Set<string> {
  const ids = new Set<string>();
  if (Array.isArray(nn.chapters)) {
    for (const chapter of nn.chapters) {
      const moments = (chapter as Record<string, unknown> | null)?.moments;
      if (!Array.isArray(moments)) continue;
      for (const moment of moments) {
        const photos = (moment as Record<string, unknown> | null)?.photo_ids;
        if (Array.isArray(photos)) {
          for (const id of photos) if (isString(id)) ids.add(id);
        }
      }
    }
  }
  const note = nn.note_moment as Record<string, unknown> | null | undefined;
  if (note && isString(note.photo_id)) ids.add(note.photo_id);
  return ids;
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

    // One chapter per logical day (#398 R1).
    const required = dayChapterStarts(context);
    if (required.length > 0) {
      const actual = starts.filter((x): x is number => x !== null);
      if (
        actual.length !== required.length ||
        actual.some((x, k) => x !== required[k])
      ) {
        problems.push(
          `neon_night.chapters: the memory has ${required.length} days — one chapter per day, each starting at its first photo`,
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

  // Every Always pick in a moment (#378), unless the moments are full of
  // them.
  const inMoments = momentPhotoIds(nn);
  const always = [...context.mustIncludeIds];
  const missing = always.filter((id) => !inMoments.has(id));
  if (
    missing.length > 0 &&
    always.length - missing.length < MAX_NN_MOMENT_SLOTS
  ) {
    problems.push(
      `neon_night: photo "${
        missing[0]
      }" is marked Always but is in no moment — put it in a moment of its chapter`,
    );
  }
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
        chapter.note_excerpt = cleanExcerpt(chapter.note_excerpt);
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
    repairMoments(nn, context);
    fitExcerptPhotos(nn, context);
  }

  if (typeof nn.note_moment === "object" && nn.note_moment !== null) {
    const n = nn.note_moment as Record<string, unknown>;
    if (isString(n.excerpt)) n.excerpt = cleanExcerpt(n.excerpt);
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
    nn.headline = cleanLine(nn.headline) || null;
    if (isString(nn.headline) && isSensitive(nn.headline)) nn.headline = null;
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
    const text = collapse(cleanExcerpt(e.text));
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
  const required = dayChapterStarts(context);
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
    let title = (inside[0]?.title ?? null) as string | null;
    if (!title) {
      const fold = covering.title as string | null;
      title = fold && !usedTitles.has(fold) ? fold : null;
    }
    title ??= placeOf(ordered.slice(start, end), context) ??
      (covering.title as string | null) ?? "";
    usedTitles.add(title);
    const moments = old.flatMap((c) =>
      Array.isArray(c.moments) ? c.moments as Record<string, unknown>[] : []
    ).map((m) => ({
      ...m,
      photo_ids: (Array.isArray(m.photo_ids) ? m.photo_ids : []).filter((
        id,
      ) => {
        const at = isString(id) ? context.photoOrder.get(id) : undefined;
        return at !== undefined && at >= start && at < end;
      }),
    })).filter((m) => (m.photo_ids as unknown[]).length > 0);
    const excerpts = old.flatMap((c) =>
      (c.excerpts as NeonNightExcerptPlan[] ?? []).filter((e) => {
        const at = e.photo_id ? context.photoOrder.get(e.photo_id) : undefined;
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

// A peak as the moment the film plays instead (#386): 3 photos side by
// side, 4 as a burst, 5 as a timeline.
function withoutPeak(
  moment: { type: NnMomentType; photo_ids: string[] },
): { type: NnMomentType; photo_ids: string[] } {
  if (moment.type !== "peak") return moment;
  const n = moment.photo_ids.length;
  return {
    type: n <= NN_MOMENT_PHOTOS.split[1]
      ? "split"
      : n <= NN_MOMENT_PHOTOS.burst[1]
      ? "burst"
      : "timeline",
    photo_ids: moment.photo_ids,
  };
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

// The type a moment of [count] photos plays as once its photos are
// settled: a timeline needs MIN_NN_TIMELINE_PHOTOS (#390), else a split
// (2–3) or burst (4); never a peak (#386).
function settledType(type: NnMomentType, count: number): NnMomentType | null {
  if (count < 2) return null;
  if (type === "timeline" && count >= MIN_NN_TIMELINE_PHOTOS) return type;
  if (type !== "timeline" && type !== "peak") {
    const [, max] = NN_MOMENT_PHOTOS[type];
    if (count <= max) return type;
  }
  if (count <= NN_MOMENT_PHOTOS.split[1]) return "split";
  if (count <= NN_MOMENT_PHOTOS.burst[1]) return "burst";
  return "timeline";
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
  // A several-day memory's chapters are its days (#398 R1): never merged.
  byDays = false,
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

  // 1. Merge.
  while (!byDays && chapters.length > 1) {
    let small = -1;
    for (let i = 0; i < chapters.length; i++) {
      if (chapters[i].photos.length >= MIN_NN_CHAPTER_PHOTOS) continue;
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
  for (const chapter of chapters) {
    const at = new Map(chapter.photos.map((p, k) => [p.id, k]));
    const byTime = (a: string, b: string) =>
      (at.get(a) ?? 0) - (at.get(b) ?? 0);
    // A merged chapter keeps at most MAX_NN_MOMENTS: its first moment,
    // then one timeline of the others' photos (the rest are left free).
    if (chapter.moments.length > MAX_NN_MOMENTS) {
      const [first, ...rest] = chapter.moments;
      const ids = rest.flatMap((m) => m.photo_ids).sort(byTime);
      chapter.moments = [
        first,
        {
          type: "timeline",
          photo_ids: spreadEvenly(ids, NN_MOMENT_PHOTOS.timeline[1]),
        },
      ];
    }
    const inMoments = () =>
      new Set(chapter.moments.flatMap((m) => m.photo_ids));

    // 2. The card's own photos: the chapter's first ones in time that no
    // moment shows (#398 R0 — the card opens the chapter).
    let used = inMoments();
    const free = chapter.photos.filter((p) =>
      !used.has(p.id) && p.id !== notePhoto
    ).map((p) => p.id);
    const card = free.slice(0, MAX_NN_CARD_PHOTOS);
    const wanted = chapter.photos.length >= 6 ? 2 : 1;
    // Taken from the moments when the free photos don't make a card: a
    // moment's first photo, never below a moment's 2.
    for (
      const moment of [...chapter.moments].sort((x, y) =>
        y.photo_ids.length - x.photo_ids.length
      )
    ) {
      while (card.length < wanted && moment.photo_ids.length > 2) {
        const pick = [...moment.photo_ids].sort(byTime)[0];
        moment.photo_ids = moment.photo_ids.filter((id) => id !== pick);
        card.push(pick);
      }
    }
    chapter.card = card.sort(byTime);

    // 3. Timelines filled with what's left, then every type settled.
    used = new Set([...inMoments(), ...chapter.card]);
    for (const moment of chapter.moments) {
      if (withoutPeak(moment).type !== "timeline") continue;
      const room = NN_TIMELINE_FILL - moment.photo_ids.length;
      if (room <= 0) continue;
      const left = chapter.photos.filter((p) =>
        !used.has(p.id) && p.id !== notePhoto
      );
      const always = left.filter((p) => p.use_in_wrap_up === true)
        .slice(0, room);
      const added = [
        ...always,
        ...spreadEvenly(
          left.filter((p) => p.use_in_wrap_up !== true),
          room - always.length,
        ),
      ].map((p) => p.id);
      for (const id of added) used.add(id);
      moment.photo_ids = [...moment.photo_ids, ...added].sort(byTime);
    }
    chapter.moments = chapter.moments.flatMap((m) => {
      const type = settledType(withoutPeak(m).type, m.photo_ids.length);
      return type ? [{ type, photo_ids: m.photo_ids }] : [];
    });
    // Every chapter keeps a moment: from its card when it must.
    if (chapter.moments.length === 0 && chapter.card.length >= 3) {
      const ids = chapter.card.splice(1, NN_MOMENT_PHOTOS.split[1]);
      chapter.moments = [{
        type: settledType("split", ids.length)!,
        photo_ids: ids,
      }];
    }
    // Moments play in time order (#398 R0).
    chapter.moments.sort((x, y) =>
      byTime([...x.photo_ids].sort(byTime)[0], [...y.photo_ids].sort(byTime)[0])
    );
  }
  return chapters;
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
    const i = multiDay || Number.isNaN(t)
      ? chapterDays.findIndex((d) => d.includes(day))
      : spans.findIndex((s) => t >= s.start && t < s.end);
    if (i >= 0) owner.set(n.id!, i);
  }
  const used = new Set<string>();

  return chapters.map((chapter, i) => {
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
        score: excerptScore(text),
      }))
    ).filter((c) => !isSensitive(c.text) && !used.has(c.text));
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
        score: excerptScore(text),
        at: noteTime(note),
        k,
      });
    };
    for (const e of chapter.excerpts) {
      const note = own.find((n) => n.id === e.note_id) ??
        notes.find((n) => n.id === e.note_id);
      if (!note || used.has(e.text) || isSensitive(e.text)) continue;
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
}

// content.neon_night from a valid, current [plan].
export function buildNeonNightContent(
  tripData: TripData,
  plan: NeonNightPlan,
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
  const shaped = shapeChapters(chapterPhotos, plan, byDays)
    // A chapter with no moment left can't play (the app skips it too).
    .filter((c) => c.moments.length > 0);
  const picked = pickExcerpts(tripData, shaped, days);
  const chapters = shaped.map((chapter, i) => {
    const lines = picked[i];
    return {
      title: chapter.title,
      photos: chapter.photos.map((p) => ({
        id: p.id,
        taken_at: p.taken_at ?? p.created_at,
        // The user's own words on the photo (#387): the zoom and timeline
        // labels show it instead of the time.
        caption: p.caption?.trim() || null,
      })),
      card_photo_ids: chapter.card,
      // The card's typed line: the director's, else the first line short
      // enough for a card (#398).
      note: chapter.note ??
        lines.excerpts.find((e) => [...e.text].length <= MAX_NN_CARD_NOTE_CHARS)
          ?.text ??
        null,
      excerpts: lines.excerpts,
      days: lines.days,
      rejected_excerpts: lines.rejected,
      moments: chapter.moments.map((m) => ({
        type: m.type,
        photo_ids: m.photo_ids,
        place: m.type === "split"
          ? byId.get(m.photo_ids[0])?.place_text?.trim() || null
          : null,
      })),
    };
  });

  const noteMoment = plan.note_moment;
  const noteIndex = noteMoment
    ? notes.findIndex((n) => n.id === noteMoment.note_id)
    : -1;
  const plan_ = planRows(tripData);
  const { start_date } = tripData.trip;
  return {
    nn_version: NN_VERSION,
    title: tripData.trip.name,
    start_date,
    place: tripData.trip.destination?.trim() || null,
    plan: plan_,
    chapters,
    note: noteMoment && noteIndex >= 0
      ? {
        text: noteMoment.excerpt,
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
