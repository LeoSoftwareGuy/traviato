import type { TripData } from "./gather.ts";

// The journal's "logical day" rule (#397), the same as the app's
// lib/core/utils/logical_day.dart, for the film (#398 R1): an item (a
// photo or a note) from 00:00 to before 08:00 local time stays on the
// previous item's day while there has been no gap of 4 hours or more since
// that item — a night out keeps going. Otherwise, and at any time from
// 08:00, it belongs to its own calendar date.
//
// The app stamps day_date with this rule when an item is saved. Since
// #468 the film reads that day as it is (the Journal is the truth); the
// rule over the times only fills a row without one.

export const LOGICAL_DAY_CUTOFF_HOUR = 8;
export const NEW_DAY_GAP_MS = 4 * 60 * 60 * 1000;

const DAY_MS = 24 * 60 * 60 * 1000;

// 'YYYY-MM-DD' of [localMs] (a local wall-clock time as UTC millis).
function dateOf(localMs: number): string {
  return new Date(localMs).toISOString().slice(0, 10);
}

// The day of an item at [localMs], given the item before it (in time) and
// the day it was put on. Mirrors `logicalDayOf` in the app.
export function logicalDayOf(
  localMs: number,
  previous?: { localMs: number; day: string } | null,
): string {
  const calendar = dateOf(localMs);
  const hour = new Date(localMs).getUTCHours();
  if (hour >= LOGICAL_DAY_CUTOFF_HOUR || !previous) return calendar;
  const gap = localMs - previous.localMs;
  if (gap < 0 || gap >= NEW_DAY_GAP_MS) return calendar;
  // Only ever the same night: the previous calendar day, or this one.
  const yesterday = dateOf(localMs - DAY_MS);
  return previous.day === yesterday || previous.day === calendar
    ? previous.day
    : calendar;
}

export interface TimedItem {
  id: string;
  // An ISO instant; items without one keep [fallbackDay].
  at: string | null;
  fallbackDay: string | null;
  // Its own place's offset (#461); absent = [utcOffsetMinutes].
  offsetMinutes?: number | null;
}

// Every item's logical day, items taken together in time order (photos and
// notes share the rule: a note written at 02:00 stays on the night's day).
// Each item is read on its own place's clock (#461: offsetMinutes), else
// [utcOffsetMinutes]. Order is by the real instant.
export function logicalDays(
  items: readonly TimedItem[],
  utcOffsetMinutes = 0,
): Map<string, string | null> {
  const days = new Map<string, string | null>();
  const timed = items
    .map((item) => ({ item, ms: item.at ? Date.parse(item.at) : NaN }))
    .filter(({ item, ms }) => {
      if (Number.isNaN(ms)) {
        days.set(item.id, item.fallbackDay);
        return false;
      }
      return true;
    })
    .sort((a, b) => a.ms - b.ms);
  let previous: { localMs: number; day: string } | null = null;
  for (const { item, ms } of timed) {
    const localMs = ms + (item.offsetMinutes ?? utcOffsetMinutes) * 60_000;
    const day = logicalDayOf(localMs, previous);
    days.set(item.id, day);
    previous = { localMs, day };
  }
  return days;
}

// Every photo's and note's film day (#468): **the Journal day it shows
// under** (its day_date) — the Journal is the truth, for photos and notes,
// even when the user backfilled it onto another day than its capture or
// typing time. The app already stamps day_date with the logical-day rule
// when an item is saved, so a night out stays on the evening. Only a row
// without a day falls back to the rule over the times (#398 R1).
export function tripLogicalDays(
  tripData: TripData,
): Map<string, string | null> {
  const computed = logicalDays(
    [
      ...tripData.photos.map((p) => ({
        id: p.id,
        at: p.taken_at ?? (p.day_date ? null : p.created_at),
        fallbackDay: p.day_date,
        offsetMinutes: p.utc_offset_minutes,
      })),
      ...tripData.notes.filter((n) => n.id).map((n) => ({
        id: `note:${n.id}`,
        at: n.legacy ? null : n.taken_at ?? null,
        fallbackDay: n.day_date,
        offsetMinutes: n.utc_offset_minutes,
      })),
    ],
    tripData.utc_offset_minutes ?? 0,
  );
  const days = new Map<string, string | null>();
  for (const p of tripData.photos) {
    days.set(p.id, p.day_date ?? computed.get(p.id) ?? null);
  }
  for (const n of tripData.notes) {
    if (!n.id) continue;
    const id = `note:${n.id}`;
    days.set(id, n.day_date || (computed.get(id) ?? null));
  }
  return days;
}

// [tripData] with a day on every photo and note that has none (#468: a
// stored day is never moved — the Journal is the truth). Idempotent.
export function onLogicalDays(tripData: TripData): TripData {
  if (
    tripData.photos.every((p) => p.day_date) &&
    tripData.notes.every((n) => n.day_date)
  ) return tripData;
  const days = tripLogicalDays(tripData);
  return {
    ...tripData,
    photos: tripData.photos.map((p) =>
      p.day_date ? p : { ...p, day_date: days.get(p.id) ?? null }
    ),
    notes: tripData.notes.map((n) =>
      n.day_date || !n.id
        ? n
        : { ...n, day_date: days.get(`note:${n.id}`) ?? n.day_date }
    ),
  };
}
