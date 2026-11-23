// Golden Vows (#346): the wedding-album film, stored as
// wrap_ups.content.golden_vows next to everything the other films read.
//
// A memory whose vibes choose Golden Vows (#433) always plays it. Since
// #458 code cuts the album (gv_skeleton.ts), the director only picks its
// words from code's lists (gv_slots.ts), and gv_film.ts builds this
// content. Here: the content's shape, its limits and the pieces the
// album shares — its photos, chapter layouts and the packing card.
//
// What code fills in, never the AI: the packing card (the user's own
// checked checklist items, else their planned quests), every note (the
// photo's caption, else the user's exact words), the carousel, the heart
// and the chapter layouts.

import type { TripData } from "./gather.ts";
import { sortPhotosChronologically } from "./assemble.ts";

export const GV_VERSION = 1;

export const GV_OCCASIONS = [
  "wedding",
  "engagement",
  "anniversary",
  "date_night",
  // A romantic memory that isn't a wedding (#433): no vows, no wedding
  // words.
  "romance",
] as const;
export type GvOccasion = typeof GV_OCCASIONS[number];

export const MIN_GV_HEROES = 2;
export const MAX_GV_HEROES = 6;
export const MIN_GV_CHAPTERS = 1;
export const MAX_GV_CHAPTERS = 4;
// A chapter page holds 3 prints, a short one 2 (layout B2, #460); a
// chapter shows up to 6 prints on two pages.
export const GV_CHAPTER_PHOTOS = 3;
export const MIN_GV_PAGE_PRINTS = 2;
export const MAX_GV_CHAPTER_PRINTS = 6;
// The carousel page shows up to 12 photos used nowhere else; below 6 it's
// skipped.
export const MAX_GV_CAROUSEL = 12;
export const MIN_GV_CAROUSEL = 6;
export const MAX_GV_HEART = 200;
export const MAX_GV_PACKED = 5;

// Lengths the film's type fits at its sizes.
export const MAX_GV_OCCASION_CHARS = 32;
export const MAX_GV_LABEL_CHARS = 18;
// A caption as the label (#460): no time beside it, so the line holds
// about this many at full size (712 px of 30 px spaced capitals).
export const MAX_GV_CAPTION_LABEL_CHARS = 24;
export const MAX_GV_NOTE_CHARS = 60;
// A page of prints' line (#460): one line under its title, shrunk to fit.
export const MAX_GV_PAGE_LINE_CHARS = 72;
export const MAX_GV_TITLE_CHARS = 28;
export const MAX_GV_LINE_CHARS = 36;
export const MAX_GV_END_CHARS = 40;

type Photo = TripData["photos"][number];

// B2 (#460): a page of 2 prints, a smaller variant of B.
export type GvLayout = "A" | "B" | "C" | "B2";

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
    // Its place in the album's play order (#460): with every chapter
    // page's, pages play by it. Absent in older content.
    order?: number;
  }[];
  chapters: {
    title: string;
    line: string;
    // Every print, in time order; layout is its first page's.
    photo_ids: string[];
    layout: GvLayout;
    // Its pages (#460): 1 or 2, each its prints, layout and place in the
    // play order. Absent in older content: one page of photo_ids.
    // note: the user's line in place of the eyebrow (#460), or null.
    pages?: {
      photo_ids: string[];
      layout: GvLayout;
      order: number;
      note?: string | null;
    }[];
  }[];
  carousel: { title: string; line: string; photo_ids: string[] } | null;
  heart_photo_ids: string[];
  // Every photo the film could show: "{N} MOMENTS".
  moment_count: number;
  end_line: string;
}

export function gvPhotos(tripData: TripData): Photo[] {
  return sortPhotosChronologically(
    tripData.photos.filter((p) => p.use_in_wrap_up !== false),
  );
}

// A page's layout from its photos' orientations: a landscape first → A
// (wide print on top), a landscape last → C (wide print below), else B
// (a tall print beside two). Unknown orientations cycle A, B, C. A page of
// 2 prints is B2 (#460).
export function chapterLayout(
  photoIds: string[],
  orientations: Readonly<Record<string, string>>,
  index: number,
): GvLayout {
  if (photoIds.length < GV_CHAPTER_PHOTOS) return "B2";
  const shapes = photoIds.map((id) => orientations[id]);
  if (shapes.some((s) => s === undefined)) {
    return (["A", "B", "C"] as const)[index % 3];
  }
  if (shapes[0] === "landscape") return "A";
  if (shapes[shapes.length - 1] === "landscape") return "C";
  return "B";
}

export function packingOf(tripData: TripData): GoldenVowsContent["packing"] {
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

// The longest line a hero's card shows whole: 3 lines at the smallest
// size (#399's fitGvNote); a longer one would only show its first sentence.
export const MAX_GV_HERO_LINE_CHARS = 90;
