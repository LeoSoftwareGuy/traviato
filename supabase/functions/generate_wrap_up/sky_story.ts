// Sky Story (#345, phase 6): what the film's pages show, stored as
// wrap_ups.content.sky next to everything the classic film reads.
//
// Since #463 the pages are cut by code (sky_skeleton.ts) and their words
// picked from code's candidates (sky_slots.ts, sky_film.ts) — as Neon Night
// (#454) and Golden Vows (#458). This module keeps the content's shape and
// the helpers the others share.
//
// Pages carry ids only: the app resolves photos through the memory's own
// photo list, so the film always shows the user's photos; the note text is
// stored with the page (the user's own words exactly).

import type { TripData } from "./gather.ts";
import { sortPhotosChronologically } from "./assemble.ts";
import { onLogicalDays } from "./logical_day.ts";

type Photo = TripData["photos"][number];

export const SKY_VERSION = 1;
export const MAX_SKY_PAGES = 5;
export const MAX_SKY_EXTRAS = 4;
// Photos one page shows: its hero and the extras.
export const SKY_PAGE_SLOTS = 1 + MAX_SKY_EXTRAS;
export const MAX_SKY_MOSAIC_PHOTOS = 60;
// One line at the headline's 88 px, two at its 64 px minimum.
export const MAX_SKY_HEADLINE_CHARS = 32;
export const MAX_SKY_LINE_CHARS = 70;

// One page as stored in content.sky.
export interface SkyPageContent {
  first_day: number;
  // Set when the page covers several days (`DAYS 4–7`).
  last_day: number | null;
  date: string;
  end_date: string | null;
  // Photos of the page's days (Leave-out picks not counted).
  photo_count: number;
  // null: the app shows the page's place, else "Day N".
  headline: string | null;
  hero_photo_id: string;
  extra_photo_ids: string[];
  note_id: string | null;
  // The note's text, the user's own words exactly (a shared or exported
  // film can't read the viewer's notes). Drafts rebuild on every open, so
  // it follows edits.
  note: string | null;
  // The lines picked for the page (#463: its slots' words — the notes
  // that belong to the page, #419/#422), in the order they were written.
  // Empty: the page shows its sky line, else its fallback. Older content
  // has none.
  excerpts: { note_id: string; text: string }[];
  sky_line: string | null;
}

export interface SkyContent {
  sky_version: typeof SKY_VERSION;
  source: "director" | "code";
  // The memory's name: the opening's big title.
  title: string;
  // Signs the notes and closes the title's subtitle; null = no signature.
  first_name: string | null;
  // Every photo of the memory: the closing "{N} moments".
  moment_count: number;
  mosaic_photo_ids: string[];
  pages: SkyPageContent[];
}

// Day number of [date] in a memory starting [start] (1 = first day).
export function dayNumberOf(start: string, date: string): number {
  const ms = Date.parse(`${date}T00:00:00Z`) -
    Date.parse(`${start}T00:00:00Z`);
  return Math.round(ms / 86_400_000) + 1;
}

function memoryDayCount(tripData: TripData): number {
  const { start_date, end_date } = tripData.trip;
  if (!start_date || !end_date) return 0;
  return Math.max(0, dayNumberOf(start_date, end_date));
}

// Photos a page may show, chronological: not left out, on a day of the
// memory.
export function skyPhotos(tripData: TripData): Photo[] {
  // Logical days, as the director sees them (#422).
  tripData = onLogicalDays(tripData);
  const start = tripData.trip.start_date;
  const dayCount = memoryDayCount(tripData);
  if (!start) return [];
  return sortPhotosChronologically(
    tripData.photos.filter((p) => {
      if (p.use_in_wrap_up === false || !p.day_date) return false;
      const day = dayNumberOf(start, p.day_date);
      return day >= 1 && day <= dayCount;
    }),
  );
}

// The first word of the user's name: signs the notes.
export function firstNameOf(
  username: string | null | undefined,
): string | null {
  const first = (username ?? "").trim().split(/\s+/)[0];
  return first ? first : null;
}

function shownOnPages(pages: SkyPageContent[]): Set<string> {
  return new Set(pages.flatMap((p) => [p.hero_photo_id, ...p.extra_photo_ids]));
}

// Always picks a Sky Story can't give a page: more than its
// MAX_SKY_PAGES pages hold. The film's known limit (#378) — they're in the
// mosaic instead, and the handler logs them.
export function alwaysWithoutPage(
  tripData: TripData,
  sky: SkyContent,
): string[] {
  const shown = shownOnPages(sky.pages);
  return skyPhotos(tripData)
    .filter((p) => p.use_in_wrap_up === true && !shown.has(p.id))
    .map((p) => p.id);
}
