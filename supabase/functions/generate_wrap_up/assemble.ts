// Deterministic assembly of WrapUpContent (#125) from gathered trip data plus
// the small AI-generated slice. No randomness, no AI calls here — same input
// always produces the same output, which is what keeps this idempotent
// alongside handler.ts's existing "return existing content as-is" guard.

import type { TripData } from "./gather.ts";
import type { AiGeneratedFields } from "./ai_fields.ts";
import type {
  CollageLayout,
  FilmCut,
  Moment,
  PhotoRef,
  WrapUpContent,
} from "./content.ts";

// Photo-count thresholds for the film's cut (#151). Highlight = every
// moment a card flip, no Flurry; compact = collages capped at torn4, at
// most one Flurry; full = the whole collage ladder, up to two Flurries.
const HIGHLIGHT_MAX_PHOTOS = 11;
const COMPACT_MAX_PHOTOS = 23;
// A Flurry with fewer cards than this is cut entirely, never shown sparse.
const FLURRY_MIN = 6;
// Player shows up to 15 cards per Flurry (WRAP_UP_FILM_FLUTTER_SPEC.md §4).
const FLURRY_CAP = 15;
// Below this many photos shown nowhere, the "and N more" label is
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

export function selectCut(photoCount: number): FilmCut {
  if (photoCount <= HIGHLIGHT_MAX_PHOTOS) return "highlight";
  if (photoCount <= COMPACT_MAX_PHOTOS) return "compact";
  return "full";
}

const COLLAGE_TILE_COUNT: Record<CollageLayout, number> = {
  stack3: 3,
  torn4: 4,
  tilt6: 6,
  torn6: 6,
};

// Which moments may become collages (WRAP_UP_FILM_COLLAGE_SPEC.md §1), in
// allocation order. "core" slots are funded before the Flurry floor is held
// back, "late" slots only from what's left after it (#151, tiered plan).
const COLLAGE_SLOTS: Array<{
  index: number;
  layout: CollageLayout;
  tier: "core" | "late";
}> = [
  { index: 1, layout: "stack3", tier: "core" }, // M2
  { index: 4, layout: "torn4", tier: "core" }, // M5
  { index: 6, layout: "tilt6", tier: "late" }, // M7
  { index: 7, layout: "torn6", tier: "late" }, // M8
];

// Largest-first downgrade ladder for a slot's preferred layout, after the
// cut's cap (compact never goes above torn4, highlight has no collages).
function layoutLadder(
  preferred: CollageLayout,
  cut: FilmCut,
): CollageLayout[] {
  if (cut === "highlight") return [];
  const capped = cut === "compact" && COLLAGE_TILE_COUNT[preferred] > 4
    ? "torn4"
    : preferred;
  switch (capped) {
    case "tilt6":
    case "torn6":
      return [capped, "torn4", "stack3"];
    case "torn4":
      return ["torn4", "stack3"];
    case "stack3":
      return ["stack3"];
  }
}

interface QueueEntry {
  photo: TripData["photos"][number];
  badge: string | null;
}

interface PoolEntry {
  photo: TripData["photos"][number];
  // Position in the trip's chronological photo order.
  order: number;
}

interface PlannedMoment {
  entry: QueueEntry;
  order: number;
  layout: CollageLayout | null;
  extras: PoolEntry[];
}

function toPhotoRef(photo: TripData["photos"][number]): PhotoRef {
  return {
    photo_id: photo.id,
    storage_path: photo.storage_path,
    day_date: photo.day_date,
  };
}

// Removes and returns the [count] pool photos nearest in time to [anchor]
// (ties go to the earlier photo), so a collage reads as one stretch of the
// trip. Deterministic — same pool, same pick.
function takeNearest(
  pool: PoolEntry[],
  anchor: number,
  count: number,
): PoolEntry[] {
  const picked = [...pool]
    .sort((a, b) =>
      Math.abs(a.order - anchor) - Math.abs(b.order - anchor) ||
      a.order - b.order
    )
    .slice(0, count);
  const pickedOrders = new Set(picked.map((p) => p.order));
  const kept = pool.filter((p) => !pickedOrders.has(p.order));
  pool.splice(0, pool.length, ...kept);
  return picked.sort((a, b) => a.order - b.order);
}

interface FilmPlan {
  cut: FilmCut;
  moments: Moment[];
  unshownInMoments: PhotoRef[];
  flurry1: PhotoRef[];
  flurry2: PhotoRef[];
  totalRemainingLabel: string | null;
}

// Resolves the whole film (#151): which photo each moment shows, which
// moments become collages and with which extra tiles, and what each Flurry
// shows. Every photo is used at most once across all of it.
function planFilm(tripData: TripData): FilmPlan {
  const photosById = new Map(tripData.photos.map((p) => [p.id, p]));
  const orderById = new Map(tripData.photos.map((p, i) => [p.id, i]));
  const cut = selectCut(tripData.photos.length);

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

  // 1. One photo per moment slot.
  const planned: PlannedMoment[] = [];
  for (const slot of MOMENT_SLOT_PLAN) {
    const primary = slot === "bonus" ? bonusQueue : journalQueue;
    const fallback = slot === "bonus" ? journalQueue : bonusQueue;
    const entry = primary.shift() ?? fallback.shift();
    if (!entry) break; // both queues exhausted — end the array short of 8.
    planned.push({
      entry,
      order: orderById.get(entry.photo.id)!,
      layout: null,
      extras: [],
    });
  }

  const pool: PoolEntry[] = journalQueue.map((entry) => ({
    photo: entry.photo,
    order: orderById.get(entry.photo.id)!,
  }));

  const fundCollage = (
    slot: (typeof COLLAGE_SLOTS)[number],
    budget: number,
  ) => {
    const moment = planned[slot.index];
    // Bonus-task moments always stay card flips (collage spec §1).
    if (!moment || moment.entry.badge !== null) return;
    for (const layout of layoutLadder(slot.layout, cut)) {
      const needed = COLLAGE_TILE_COUNT[layout] - 1;
      if (needed <= budget) {
        moment.layout = layout;
        moment.extras = takeNearest(pool, moment.order, needed);
        return;
      }
    }
  };

  // 2. Core collages (M2, M5).
  for (const slot of COLLAGE_SLOTS.filter((s) => s.tier === "core")) {
    fundCollage(slot, pool.length);
  }
  // 3. Hold back one Flurry's worth, when a Flurry is possible at all.
  const flurryFloor = cut !== "highlight" && pool.length >= FLURRY_MIN
    ? FLURRY_MIN
    : 0;
  // 4. Late collages (M7, M8), never eating into the held-back floor.
  for (const slot of COLLAGE_SLOTS.filter((s) => s.tier === "late")) {
    fundCollage(slot, pool.length - flurryFloor);
  }

  // 5. Everything left, in chronological order, goes to the Flurries.
  const leftovers = pool.map((p) => toPhotoRef(p.photo));
  let flurry1: PhotoRef[] = [];
  let flurry2: PhotoRef[] = [];
  if (cut === "full" && leftovers.length >= FLURRY_MIN * 2) {
    const firstCount = Math.min(FLURRY_CAP, leftovers.length - FLURRY_MIN);
    flurry1 = leftovers.slice(0, firstCount);
    flurry2 = leftovers.slice(firstCount, firstCount + FLURRY_CAP);
  } else if (cut !== "highlight" && leftovers.length >= FLURRY_MIN) {
    flurry1 = leftovers.slice(0, FLURRY_CAP);
  }

  const unshown = leftovers.length - flurry1.length - flurry2.length;

  return {
    cut,
    moments: planned.map((m) => ({
      ...toPhotoRef(m.entry.photo),
      note: m.entry.photo.caption,
      badge: m.entry.badge,
      layout: m.layout,
      collage_extras: m.extras.map((e) => toPhotoRef(e.photo)),
    })),
    unshownInMoments: leftovers,
    flurry1,
    flurry2,
    totalRemainingLabel: unshown >= FLURRY_LABEL_MIN
      ? `And ${unshown} more.`
      : null,
  };
}

export function assembleWrapUpContent(
  tripData: TripData,
  aiFields: AiGeneratedFields,
): WrapUpContent {
  const { trip } = tripData;
  const plan = planFilm(tripData);

  return {
    cut: plan.cut,
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
    moments: plan.moments,
    flurry_leftovers: {
      photos: plan.unshownInMoments,
      flurry1: plan.flurry1,
      flurry2: plan.flurry2,
      total_remaining_label: plan.totalRemainingLabel,
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
