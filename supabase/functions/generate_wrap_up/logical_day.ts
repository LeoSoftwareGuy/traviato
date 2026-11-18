// The journal's "logical day" rule (#397), the same as the app's
// lib/core/utils/logical_day.dart, for the film (#398 R1): an item (a
// photo or a note) from 00:00 to before 08:00 local time stays on the
// previous item's day while there has been no gap of 4 hours or more since
// that item — a night out keeps going. Otherwise, and at any time from
// 08:00, it belongs to its own calendar date.
//
// The app stamps day_date with this rule when an item is saved; rows saved
// before #401 carry their calendar date. The film recomputes it from the
// times so every memory follows the rule.

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
}

// Every item's logical day, items taken together in time order (photos and
// notes share the rule: a note written at 02:00 stays on the night's day).
// [utcOffsetMinutes] turns instants into the phone's wall-clock time.
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
    const localMs = ms + utcOffsetMinutes * 60_000;
    const day = logicalDayOf(localMs, previous);
    days.set(item.id, day);
    previous = { localMs, day };
  }
  return days;
}
