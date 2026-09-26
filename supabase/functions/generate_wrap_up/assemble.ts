// Deterministic assembly of WrapUpContent (#125) from gathered trip data plus
// the small AI-generated slice. No randomness, no AI calls here — same input
// always produces the same output, which is what keeps this idempotent
// alongside handler.ts's existing "return existing content as-is" guard.

import type { TripData } from "./gather.ts";
import type { AiGeneratedFields } from "./ai_fields.ts";
import type { Moment, PhotoRef, WrapUpContent } from "./content.ts";

// Player shows up to 15 in Flurry1 + 15 in Flurry2 (WRAP_UP_FILM_FLUTTER_SPEC.md §4).
const FLURRY_DISPLAY_CAP = 30;
// Below this many true leftovers beyond the cap, the "and N more" label is
// suppressed rather than announcing a single-digit remainder.
const FLURRY_LABEL_MIN = 10;

const NUMBER_WORDS = [
  "Zero",
  "One",
  "Two",
  "Three",
  "Four",
  "Five",
  "Six",
  "Seven",
  "Eight",
  "Nine",
  "Ten",
  "Eleven",
  "Twelve",
  "Thirteen",
  "Fourteen",
  "Fifteen",
  "Sixteen",
  "Seventeen",
  "Eighteen",
  "Nineteen",
  "Twenty",
];

// Fixed slot plan for the 8 moment frames (WRAP_UP_FILM_FLUTTER_SPEC.md §4): bonus-task
// completion photos badge slots 1, 3 and 4; the rest are plain journal
// photos. A slot short of its preferred queue borrows from the other queue
// instead of being skipped — a badge slot degrades to a plain photo, and (the
// rarer direction) a journal slot with no journal photos left will still
// show a leftover bonus photo, badge intact, rather than truncate the film
// while real content remains.
const MOMENT_SLOT_PLAN: Array<"bonus" | "journal"> = [
  "bonus",
  "journal",
  "bonus",
  "bonus",
  "journal",
  "journal",
  "journal",
  "journal",
];

function parseDateParts(
  dateStr: string,
): { day: number; month: string; year: number } {
  const d = new Date(`${dateStr}T00:00:00Z`);
  return {
    day: d.getUTCDate(),
    month: d.toLocaleString("en-US", { month: "long", timeZone: "UTC" }),
    year: d.getUTCFullYear(),
  };
}

function formatDateRange(start: string | null, end: string | null): string {
  if (!start && !end) return "";
  if (start && !end) {
    const s = parseDateParts(start);
    return `${s.day} ${s.month} ${s.year}`;
  }
  if (!start && end) {
    const e = parseDateParts(end);
    return `${e.day} ${e.month} ${e.year}`;
  }
  const s = parseDateParts(start!);
  const e = parseDateParts(end!);
  if (s.year === e.year && s.month === e.month) {
    return `${s.day}–${e.day} ${s.month} ${s.year}`;
  }
  if (s.year === e.year) {
    return `${s.day} ${s.month} – ${e.day} ${e.month} ${s.year}`;
  }
  return `${s.day} ${s.month} ${s.year} – ${e.day} ${e.month} ${e.year}`;
}

export function inclusiveDayCount(
  start: string | null,
  end: string | null,
): number | null {
  if (!start || !end) return null;
  const startMs = new Date(`${start}T00:00:00Z`).getTime();
  const endMs = new Date(`${end}T00:00:00Z`).getTime();
  const days = Math.round((endMs - startMs) / 86_400_000) + 1;
  return days > 0 ? days : null;
}

export function invitationLine1(
  start: string | null,
  end: string | null,
): string {
  const count = inclusiveDayCount(start, end);
  if (count === null) return "Your trip.";
  if (count === 1) return "One day.";
  const word = count <= 20 ? NUMBER_WORDS[count] : String(count);
  return `${word} days.`;
}

export function splitKeepsakeTitle(
  name: string,
): { title_line1: string; title_line2: string } {
  const words = name.trim().split(/\s+/).filter(Boolean);
  if (words.length <= 1) {
    return { title_line1: name.trim(), title_line2: "" };
  }
  const mid = Math.ceil(words.length / 2);
  return {
    title_line1: words.slice(0, mid).join(" "),
    title_line2: words.slice(mid).join(" "),
  };
}

interface QueueEntry {
  photo: TripData["photos"][number];
  badge: string | null;
}

function buildMomentsAndLeftovers(
  tripData: TripData,
): { moments: Moment[]; leftovers: PhotoRef[] } {
  const photosById = new Map(tripData.photos.map((p) => [p.id, p]));

  // Only the first 3 completed bonus tasks (completion order) with a photo
  // get a badge slot — a fixed count regardless of how many were completed.
  const bonusQueue: QueueEntry[] = tripData.completedBonusTasks
    .filter((b) => b.photo_id !== null && photosById.has(b.photo_id))
    .slice(0, 3)
    .map((b) => ({
      photo: photosById.get(b.photo_id!)!,
      badge: `Dare · ${b.title} · ✦${b.points}`,
    }));

  const badgedIds = new Set(bonusQueue.map((entry) => entry.photo.id));
  const journalQueue: QueueEntry[] = tripData.photos
    .filter((p) => !badgedIds.has(p.id))
    .map((photo) => ({ photo, badge: null }));

  const moments: Moment[] = [];
  for (const slot of MOMENT_SLOT_PLAN) {
    const primary = slot === "bonus" ? bonusQueue : journalQueue;
    const fallback = slot === "bonus" ? journalQueue : bonusQueue;
    const entry = primary.shift() ?? fallback.shift();
    if (!entry) break; // both queues exhausted — end the array short of 8.

    moments.push({
      photo_id: entry.photo.id,
      storage_path: entry.photo.storage_path,
      day_date: entry.photo.day_date,
      note: entry.photo.caption,
      badge: entry.badge,
    });
  }

  return {
    moments,
    leftovers: journalQueue.map((entry) => ({
      photo_id: entry.photo.id,
      storage_path: entry.photo.storage_path,
      day_date: entry.photo.day_date,
    })),
  };
}

function flurryLabel(leftoverCount: number): string | null {
  const beyondDisplayCap = leftoverCount - FLURRY_DISPLAY_CAP;
  if (beyondDisplayCap < FLURRY_LABEL_MIN) return null;
  return `And ${beyondDisplayCap} more.`;
}

export function assembleWrapUpContent(
  tripData: TripData,
  aiFields: AiGeneratedFields,
): WrapUpContent {
  const { trip } = tripData;
  const { moments, leftovers } = buildMomentsAndLeftovers(tripData);

  return {
    dates: {
      start_date: trip.start_date,
      end_date: trip.end_date,
      formatted: formatDateRange(trip.start_date, trip.end_date),
    },
    cover_photo: { image_path: trip.cover_image_path },
    invitation: {
      line1: invitationLine1(trip.start_date, trip.end_date),
      line2: aiFields.invitation_line2,
    },
    bridges: aiFields.bridges,
    moments,
    flurry_leftovers: {
      photos: leftovers,
      total_remaining_label: flurryLabel(leftovers.length),
    },
    footnote: {
      photo_count: tripData.photos.length,
      bonus_completed_count: tripData.completedBonusTasks.length,
      stars: tripData.starsEarned,
    },
    unlock: tripData.latestAchievement
      ? {
        code: tripData.latestAchievement.code,
        name: tripData.latestAchievement.title,
        reason: aiFields.unlock_reason ??
          tripData.latestAchievement.description,
      }
      : null,
    keepsake: {
      ...splitKeepsakeTitle(trip.name),
      closing_quote: aiFields.keepsake_closing_quote,
    },
  };
}
