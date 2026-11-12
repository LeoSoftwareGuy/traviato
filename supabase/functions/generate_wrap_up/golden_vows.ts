// Golden Vows (#346, phase 7): the wedding-album film, stored as
// wrap_ups.content.golden_vows next to everything the other films read.
//
// Only the director makes one: its `golden_vows` section, emitted for a
// wedding, an engagement, an anniversary or a date night, validated here
// against the memory as it is now. There is no code-built Golden Vows —
// no section (another occasion, the director off or failed, a section
// still invalid after its retry, one that no longer fits) means Sky Story
// plays instead.
//
// What code fills in, never the AI: the packing card (the user's own
// checked checklist items, else their planned quests), every note (the
// photo's caption, else the director's excerpt — checked to be the user's
// exact words), the carousel, the heart and the chapter layouts.

import type { TripData } from "./gather.ts";
import {
  inclusiveDayCount,
  sortPhotosChronologically,
  spreadEvenly,
} from "./assemble.ts";
import { bannedPhraseIn, cleanLine } from "./film_plan.ts";

export const GV_VERSION = 1;

export const GV_OCCASIONS = [
  "wedding",
  "engagement",
  "anniversary",
  "date_night",
] as const;
export type GvOccasion = typeof GV_OCCASIONS[number];

export const MIN_GV_HEROES = 2;
export const MAX_GV_HEROES = 6;
export const MIN_GV_CHAPTERS = 1;
export const MAX_GV_CHAPTERS = 4;
export const GV_CHAPTER_PHOTOS = 3;
// The carousel page shows up to 12 photos used nowhere else; below 6 it's
// skipped.
export const MAX_GV_CAROUSEL = 12;
export const MIN_GV_CAROUSEL = 6;
export const MAX_GV_HEART = 200;
export const MAX_GV_PACKED = 5;

// Lengths the film's type fits at its sizes.
export const MAX_GV_OCCASION_CHARS = 32;
export const MAX_GV_LABEL_CHARS = 18;
export const MAX_GV_NOTE_CHARS = 60;
export const MAX_GV_TITLE_CHARS = 28;
export const MAX_GV_LINE_CHARS = 36;
export const MAX_GV_END_CHARS = 40;

type Photo = TripData["photos"][number];

export interface GoldenVowsHeroPlan {
  photo_id: string;
  // "The vows"; the app adds the photo's time.
  label: string;
  // A note from the photo's day and an exact excerpt of it, or both null.
  // A captioned photo's caption is its note whatever these say.
  note_id: string | null;
  note_excerpt: string | null;
}

export interface GoldenVowsChapterPlan {
  title: string;
  // The eyebrow: "Chapter one · Morning".
  line: string;
  photo_ids: string[];
}

export interface GoldenVowsPlan {
  occasion: GvOccasion;
  occasion_line: string;
  heroes: GoldenVowsHeroPlan[];
  chapters: GoldenVowsChapterPlan[];
  // The carousel page's title and line; null = no carousel page.
  carousel: { title: string; line: string } | null;
  end_line: string;
}

export type GvLayout = "A" | "B" | "C";

export interface GoldenVowsContent {
  gv_version: typeof GV_VERSION;
  occasion: GvOccasion;
  occasion_line: string;
  // The memory's name ("Anna & Marco"), dates, day count and "where".
  names: string;
  start_date: string | null;
  end_date: string | null;
  day_count: number;
  place: string | null;
  // The packing card; null = none (the film opens on the album).
  packing: {
    source: "checklist" | "quests";
    // The user's own words; a seeded checklist item also carries its code
    // so the app shows it in the film's language.
    items: { text: string; suggestion_code: string | null }[];
    // "X OF Y" (checklist only).
    checked: number | null;
    total: number | null;
  } | null;
  heroes: {
    photo_id: string;
    label: string;
    // For the label's time; null = unknown, no time shown.
    taken_at: string | null;
    // The user's own words, or null for no note card.
    note: string | null;
  }[];
  chapters: {
    title: string;
    line: string;
    photo_ids: string[];
    layout: GvLayout;
  }[];
  carousel: { title: string; line: string; photo_ids: string[] } | null;
  heart_photo_ids: string[];
  // Every photo the film could show: "{N} MOMENTS".
  moment_count: number;
  end_line: string;
}

function isString(v: unknown): v is string {
  return typeof v === "string";
}

// --- The director's tool section -----------------------------------------

const lineProperty = (description: string) => ({
  type: "string",
  description,
});

export const goldenVowsToolProperty = {
  type: ["object", "null"],
  description:
    "The Golden Vows film: an ivory-and-gold wedding album. Only for a wedding, an engagement, an anniversary or a date night; null for every other memory.",
  properties: {
    occasion: { type: "string", enum: [...GV_OCCASIONS] },
    occasion_line: lineProperty(
      `The title page's line, at most ${MAX_GV_OCCASION_CHARS} characters, e.g. "Our Wedding Day".`,
    ),
    heroes: {
      type: "array",
      description:
        `${MIN_GV_HEROES}–${MAX_GV_HEROES} standout photos, one full page each.`,
      items: {
        type: "object",
        properties: {
          photo_id: { type: "string" },
          label: lineProperty(
            `What the photo shows, at most ${MAX_GV_LABEL_CHARS} characters, e.g. "The vows".`,
          ),
          note_id: {
            type: ["string", "null"],
            description:
              "A note from the photo's day whose words fit the photo, or null. Null for a photo with a caption.",
          },
          note_excerpt: {
            type: ["string", "null"],
            description:
              `With note_id: a short phrase copied exactly from that note, at most ${MAX_GV_NOTE_CHARS} characters, never reworded. Otherwise null.`,
          },
        },
        required: ["photo_id", "label", "note_id", "note_excerpt"],
      },
    },
    chapters: {
      type: "array",
      description:
        `${MIN_GV_CHAPTERS}–${MAX_GV_CHAPTERS} chapters by time of day (or by day for a multi-day event), exactly ${GV_CHAPTER_PHOTOS} photos each.`,
      items: {
        type: "object",
        properties: {
          title: lineProperty(
            `At most ${MAX_GV_TITLE_CHARS} characters, e.g. "Getting ready".`,
          ),
          line: lineProperty(
            `At most ${MAX_GV_LINE_CHARS} characters, e.g. "Chapter one · Morning".`,
          ),
          photo_ids: { type: "array", items: { type: "string" } },
        },
        required: ["title", "line", "photo_ids"],
      },
    },
    carousel: {
      type: ["object", "null"],
      description:
        "The page of the photos used nowhere else (code picks them); null when there are few left.",
      properties: {
        title: lineProperty(
          `At most ${MAX_GV_TITLE_CHARS} characters, e.g. "And the night went on".`,
        ),
        line: lineProperty(
          `At most ${MAX_GV_LINE_CHARS} characters, e.g. "Chapter four · Evening".`,
        ),
      },
      required: ["title", "line"],
    },
    end_line: lineProperty(
      `Under the heart as it lifts off, at most ${MAX_GV_END_CHARS} characters, e.g. "Forever starts here".`,
    ),
  },
  required: [
    "occasion",
    "occasion_line",
    "heroes",
    "chapters",
    "carousel",
    "end_line",
  ],
} as const;

export const GOLDEN_VOWS_PROMPT_RULES = [
  "\n\ngolden_vows — a third film, an elegant wedding album. Fill it only ",
  "when the memory is a wedding, an engagement, an anniversary or a date ",
  "night (from its name, vibes, notes and photos); otherwise null. When ",
  "unsure, null.\n",
  `- heroes: ${MIN_GV_HEROES}–${MAX_GV_HEROES} of the most moving, sharp `,
  "photos (hero_score ≥ 3), in the order they best tell the day. label ",
  'names the moment ("The vows", "First dance").\n',
  "- A hero's note is the person's own words only: for a photo without a ",
  "caption, note_id may point at a note from the photo's day and ",
  "note_excerpt copy a short phrase from it exactly — same words, same ",
  "spelling, never reworded or shortened inside. Else both null.\n",
  `- chapters: ${MIN_GV_CHAPTERS}–${MAX_GV_CHAPTERS}, each exactly `,
  `${GV_CHAPTER_PHOTOS} photos, by time of day (by day for a multi-day `,
  "event), photos and chapters in order. title is the part of the day; ",
  'line numbers it ("Chapter one · Morning").\n',
  "- No photo twice across heroes and chapters. Photos used nowhere else ",
  "fill the carousel page; give it a title and line, or null if fewer ",
  `than ${MIN_GV_CAROUSEL} photos are left.\n`,
  "- occasion_line, titles, lines and end_line: warm and simple, in the ",
  "occasion's tone, in the film's language.",
].join("");

// --- Checking a section against the memory -------------------------------

export interface GvCheckContext {
  // Chronological index of every photo the section may use.
  photoOrder: ReadonlyMap<string, number>;
  photoDates: ReadonlyMap<string, string | null>;
  excludedIds: ReadonlySet<string>;
  notes: ReadonlyMap<string, { day_date: string; content: string }>;
}

// Photos the film may show, chronological: not left out.
export function gvPhotos(tripData: TripData): Photo[] {
  return sortPhotosChronologically(
    tripData.photos.filter((p) => p.use_in_wrap_up !== false),
  );
}

export function gvCheckContext(tripData: TripData): GvCheckContext {
  const photos = gvPhotos(tripData);
  return {
    photoOrder: new Map(photos.map((p, i) => [p.id, i])),
    photoDates: new Map(photos.map((p) => [p.id, p.day_date])),
    excludedIds: new Set(
      tripData.photos.filter((p) => p.use_in_wrap_up === false).map((p) =>
        p.id
      ),
    ),
    notes: new Map(
      tripData.notes.filter((n) => n.id).map((n) => [
        n.id!,
        { day_date: n.day_date, content: n.content },
      ]),
    ),
  };
}

function collapse(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

// Whether [excerpt] is the note's own words: a run of it, ignoring only
// spacing.
export function isExcerptOf(excerpt: string, note: string): boolean {
  const e = collapse(excerpt);
  return e.length > 0 && collapse(note).includes(e);
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

// Every way [data] breaks the golden_vows rules, one readable line each —
// empty when it's valid. Call it only for a non-null section.
export function describeGoldenVowsProblems(
  data: unknown,
  context: GvCheckContext,
): string[] {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return ["golden_vows: expected an object or null"];
  }
  const gv = data as Record<string, unknown>;
  const problems: string[] = [];
  if (!GV_OCCASIONS.includes(gv.occasion as GvOccasion)) {
    problems.push(
      `golden_vows.occasion: expected one of ${GV_OCCASIONS.join(", ")}`,
    );
  }
  checkLine(
    problems,
    "golden_vows.occasion_line",
    gv.occasion_line,
    MAX_GV_OCCASION_CHARS,
  );
  checkLine(problems, "golden_vows.end_line", gv.end_line, MAX_GV_END_CHARS);

  const used = new Set<string>();
  const checkPhoto = (id: unknown, where: string): boolean => {
    if (!isString(id)) {
      problems.push(`${where}: expected a photo id`);
      return false;
    }
    if (context.excludedIds.has(id)) {
      problems.push(`${where}: "${id}" was left out by the user`);
      return false;
    }
    if (!context.photoOrder.has(id)) {
      problems.push(`${where}: "${id}" is not a photo id from the input`);
      return false;
    }
    if (used.has(id)) problems.push(`${where}: "${id}" is used twice`);
    used.add(id);
    return true;
  };

  const heroes = gv.heroes;
  if (!Array.isArray(heroes)) {
    problems.push("golden_vows.heroes: expected an array");
  } else {
    if (heroes.length < MIN_GV_HEROES || heroes.length > MAX_GV_HEROES) {
      problems.push(
        `golden_vows.heroes: ${heroes.length}, expected ${MIN_GV_HEROES}–${MAX_GV_HEROES}`,
      );
    }
    heroes.forEach((raw, i) => {
      const where = `golden_vows.heroes[${i}]`;
      if (typeof raw !== "object" || raw === null) {
        problems.push(`${where}: expected an object`);
        return;
      }
      const hero = raw as Record<string, unknown>;
      const known = checkPhoto(hero.photo_id, `${where}.photo_id`);
      checkLine(problems, `${where}.label`, hero.label, MAX_GV_LABEL_CHARS);
      const noteId = hero.note_id ?? null;
      const excerpt = hero.note_excerpt ?? null;
      if (noteId === null) {
        if (excerpt !== null) {
          problems.push(`${where}.note_excerpt: only with a note_id`);
        }
        return;
      }
      const note = isString(noteId) ? context.notes.get(noteId) : undefined;
      if (!note) {
        problems.push(`${where}.note_id: not a note id from the input`);
        return;
      }
      if (
        known &&
        context.photoDates.get(hero.photo_id as string) !== note.day_date
      ) {
        problems.push(`${where}.note_id: the note is not from the photo's day`);
      }
      if (!isString(excerpt) || !isExcerptOf(excerpt, note.content)) {
        problems.push(
          `${where}.note_excerpt: must be copied exactly from the note`,
        );
      } else if ([...collapse(excerpt)].length > MAX_GV_NOTE_CHARS) {
        problems.push(
          `${where}.note_excerpt: ${
            [...collapse(excerpt)].length
          } characters, at most ${MAX_GV_NOTE_CHARS}`,
        );
      }
    });
  }

  const chapters = gv.chapters;
  if (!Array.isArray(chapters)) {
    problems.push("golden_vows.chapters: expected an array");
  } else {
    if (
      chapters.length < MIN_GV_CHAPTERS || chapters.length > MAX_GV_CHAPTERS
    ) {
      problems.push(
        `golden_vows.chapters: ${chapters.length}, expected ${MIN_GV_CHAPTERS}–${MAX_GV_CHAPTERS}`,
      );
    }
    let last = -1;
    chapters.forEach((raw, i) => {
      const where = `golden_vows.chapters[${i}]`;
      if (typeof raw !== "object" || raw === null) {
        problems.push(`${where}: expected an object`);
        return;
      }
      const chapter = raw as Record<string, unknown>;
      checkLine(problems, `${where}.title`, chapter.title, MAX_GV_TITLE_CHARS);
      checkLine(problems, `${where}.line`, chapter.line, MAX_GV_LINE_CHARS);
      const ids = chapter.photo_ids;
      if (!Array.isArray(ids)) {
        problems.push(`${where}.photo_ids: expected an array of ids`);
        return;
      }
      if (ids.length !== GV_CHAPTER_PHOTOS) {
        problems.push(
          `${where}.photo_ids: ${ids.length}, expected exactly ${GV_CHAPTER_PHOTOS}`,
        );
      }
      ids.forEach((id, k) => {
        if (!checkPhoto(id, `${where}.photo_ids[${k}]`)) return;
        const at = context.photoOrder.get(id as string)!;
        if (at < last) {
          problems.push(
            `${where}.photo_ids[${k}]: "${id}" is out of chronological order`,
          );
        }
        last = Math.max(last, at);
      });
    });
  }

  const carousel = gv.carousel;
  if (carousel !== null && carousel !== undefined) {
    if (typeof carousel !== "object" || Array.isArray(carousel)) {
      problems.push("golden_vows.carousel: expected an object or null");
    } else {
      const c = carousel as Record<string, unknown>;
      checkLine(
        problems,
        "golden_vows.carousel.title",
        c.title,
        MAX_GV_TITLE_CHARS,
      );
      checkLine(
        problems,
        "golden_vows.carousel.line",
        c.line,
        MAX_GV_LINE_CHARS,
      );
    }
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
// quotes or ellipses around an excerpt, an excerpt that isn't the note's
// words (→ no note card), too many heroes or chapters, chapter photos and
// chapters out of order. Never throws.
export function repairGoldenVows(
  data: unknown,
  context: GvCheckContext,
): unknown {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return data;
  }
  const gv = structuredClone(data) as Record<string, unknown>;
  for (const key of ["occasion_line", "end_line"]) {
    if (isString(gv[key])) gv[key] = cleanLine(gv[key] as string);
  }
  if (Array.isArray(gv.heroes)) {
    gv.heroes = gv.heroes.slice(0, MAX_GV_HEROES);
    for (const raw of gv.heroes as unknown[]) {
      if (typeof raw !== "object" || raw === null) continue;
      const hero = raw as Record<string, unknown>;
      if (isString(hero.label)) hero.label = cleanLine(hero.label);
      hero.note_id = hero.note_id ?? null;
      hero.note_excerpt = hero.note_excerpt ?? null;
      const note = isString(hero.note_id)
        ? context.notes.get(hero.note_id)
        : undefined;
      if (isString(hero.note_excerpt)) {
        hero.note_excerpt = cleanExcerpt(hero.note_excerpt);
      }
      const fits = note && isString(hero.note_excerpt) &&
        isExcerptOf(hero.note_excerpt, note.content) &&
        [...collapse(hero.note_excerpt)].length <= MAX_GV_NOTE_CHARS &&
        context.photoDates.get(hero.photo_id as string) === note.day_date;
      if (fits) {
        hero.note_excerpt = collapse(hero.note_excerpt as string);
      } else {
        hero.note_id = null;
        hero.note_excerpt = null;
      }
    }
  }
  if (Array.isArray(gv.chapters)) {
    const order = (id: unknown) =>
      isString(id) ? context.photoOrder.get(id) ?? Infinity : Infinity;
    const chapters = (gv.chapters as unknown[]).slice(0, MAX_GV_CHAPTERS);
    for (const raw of chapters) {
      if (typeof raw !== "object" || raw === null) continue;
      const chapter = raw as Record<string, unknown>;
      for (const key of ["title", "line"]) {
        if (isString(chapter[key])) {
          chapter[key] = cleanLine(chapter[key] as string);
        }
      }
      if (Array.isArray(chapter.photo_ids)) {
        chapter.photo_ids = [...chapter.photo_ids].sort((a, b) =>
          order(a) - order(b)
        );
      }
    }
    const first = (raw: unknown) => {
      const ids = (raw as Record<string, unknown> | null)?.photo_ids;
      return Array.isArray(ids) && ids.length > 0 ? order(ids[0]) : Infinity;
    };
    gv.chapters = [...chapters].sort((a, b) => first(a) - first(b));
  }
  if (typeof gv.carousel === "object" && gv.carousel !== null) {
    const c = gv.carousel as Record<string, unknown>;
    for (const key of ["title", "line"]) {
      if (isString(c[key])) c[key] = cleanLine(c[key] as string);
    }
  }
  if (gv.carousel === undefined) gv.carousel = null;
  return gv;
}

// --- Building content.golden_vows ----------------------------------------

// The chapter's layout from its photos' orientations: a landscape first →
// A (wide print on top), a landscape last → C (wide print below), else B
// (a tall print beside two). Unknown orientations cycle A, B, C.
export function chapterLayout(
  photoIds: string[],
  orientations: Readonly<Record<string, string>>,
  index: number,
): GvLayout {
  const shapes = photoIds.map((id) => orientations[id]);
  if (shapes.some((s) => s === undefined)) {
    return (["A", "B", "C"] as const)[index % 3];
  }
  if (shapes[0] === "landscape") return "A";
  if (shapes[shapes.length - 1] === "landscape") return "C";
  return "B";
}

function packingOf(tripData: TripData): GoldenVowsContent["packing"] {
  const checklist = tripData.checklist ?? [];
  const checked = checklist.filter((i) => i.is_checked && i.title.trim());
  if (checked.length > 0) {
    return {
      source: "checklist",
      items: checked.slice(0, MAX_GV_PACKED).map((i) => ({
        text: i.title.trim(),
        suggestion_code: i.suggestion_code ?? null,
      })),
      checked: checked.length,
      total: checklist.length,
    };
  }
  const quests = (tripData.quests ?? []).filter((q) => q.title.trim());
  if (quests.length === 0) return null;
  return {
    source: "quests",
    items: quests.slice(0, MAX_GV_PACKED).map((q) => ({
      text: q.title.trim(),
      suggestion_code: null,
    })),
    checked: null,
    total: null,
  };
}

// The carousel's photos: those used nowhere else, Always picks first, the
// rest spread evenly; chronological.
function carouselPhotos(photos: Photo[], used: ReadonlySet<string>): string[] {
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
  return left.filter((p) => picked.has(p)).map((p) => p.id);
}

// content.golden_vows from a valid, current [plan].
export function buildGoldenVowsContent(
  tripData: TripData,
  plan: GoldenVowsPlan,
  orientations: Readonly<Record<string, string>> = {},
): GoldenVowsContent {
  const photos = gvPhotos(tripData);
  const byId = new Map(photos.map((p) => [p.id, p]));
  const notes = new Map(
    tripData.notes.filter((n) => n.id).map((n) => [n.id!, n.content]),
  );
  const used = new Set<string>();
  const heroes = plan.heroes.map((hero) => {
    const photo = byId.get(hero.photo_id)!;
    used.add(photo.id);
    const caption = photo.caption?.trim();
    const note = caption ||
      (hero.note_id && hero.note_excerpt && notes.has(hero.note_id)
        ? collapse(hero.note_excerpt)
        : null);
    return {
      photo_id: photo.id,
      label: hero.label,
      taken_at: photo.taken_at,
      note: note || null,
    };
  });
  const chapters = plan.chapters.map((chapter, i) => {
    for (const id of chapter.photo_ids) used.add(id);
    return {
      title: chapter.title,
      line: chapter.line,
      photo_ids: [...chapter.photo_ids],
      layout: chapterLayout(chapter.photo_ids, orientations, i),
    };
  });
  const carouselIds = plan.carousel ? carouselPhotos(photos, used) : [];
  const { start_date, end_date } = tripData.trip;
  return {
    gv_version: GV_VERSION,
    occasion: plan.occasion,
    occasion_line: plan.occasion_line,
    names: tripData.trip.name,
    start_date,
    end_date,
    day_count: inclusiveDayCount(start_date, end_date) ?? 1,
    place: tripData.trip.destination?.trim() || null,
    packing: packingOf(tripData),
    heroes,
    chapters,
    carousel: plan.carousel && carouselIds.length >= MIN_GV_CAROUSEL
      ? { ...plan.carousel, photo_ids: carouselIds }
      : null,
    heart_photo_ids: spreadEvenly(photos, MAX_GV_HEART).map((p) => p.id),
    moment_count: photos.length,
    end_line: plan.end_line,
  };
}
