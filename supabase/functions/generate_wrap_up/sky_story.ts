// Sky Story (#345, phase 6): what the film's pages show, stored as
// wrap_ups.content.sky next to everything the classic film reads.
//
// Two sources:
// - the director's `sky_story` section of its plan (#328's emit_film_plan
//   tool), validated here against the memory as it is now;
// - code-built pages, the fallback whenever the director can't plan (off
//   switch, an error, a plan still invalid after its retry, too few
//   photos). Deterministic, no AI.
//
// Pages carry ids only: the app resolves photos through the memory's own
// photo list and note text through its own notes, so the film always shows
// the user's words exactly. Copy (eyebrows, captions, a missing headline)
// is composed in the app, in the film's language.

import type { TripData } from "./gather.ts";
import { sortPhotosChronologically, spreadEvenly } from "./assemble.ts";
import { decorativePhotos } from "./decorative.ts";
import { bannedPhraseIn, cleanAiLine } from "./film_plan.ts";
import { wholeWords } from "./text_fit.ts";
import { bestLines, lineThemeFor } from "./excerpts.ts";
import { chosenTemplate } from "./film_template.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
import {
  filmSecondsOf,
  isFilmLengthRuleOn,
  skyPagesFor,
} from "./film_length.ts";
import { onLogicalDays } from "./logical_day.ts";

export const SKY_VERSION = 1;
export const MAX_SKY_PAGES = 5;
export const MAX_SKY_EXTRAS = 4;
// Photos one page shows: its hero and the extras.
export const SKY_PAGE_SLOTS = 1 + MAX_SKY_EXTRAS;
export const MAX_SKY_MOSAIC_PHOTOS = 60;
// One line at the headline's 88 px, two at its 64 px minimum.
export const MAX_SKY_HEADLINE_CHARS = 32;
export const MAX_SKY_LINE_CHARS = 70;

type Photo = TripData["photos"][number];

// The director's choices for one page.
export interface SkyStoryPagePlan {
  // First and last day number (1 = the memory's first day); equal for a
  // single day. A page may repeat the previous page's days exactly: a
  // continuation page for a day with more Always picks than one page
  // shows (#378).
  days: [number, number];
  // Null only on a page code added for Always picks (#382):
  // the app shows the place or "Day N".
  headline: string | null;
  hero_photo_id: string;
  extra_photo_ids: string[];
  note_id: string | null;
  // Written on the sky when the page has no note.
  sky_line: string | null;
}

export interface SkyStoryPlan {
  pages: SkyStoryPagePlan[];
}

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
  // The best lines of the page's days' notes (#419), in note order: the
  // ones nearest this page's photos in time (#422). Empty = nothing
  // specific here: the page keeps its note or fallback. Older content has
  // none.
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

export const skyStoryToolProperty = {
  type: "object",
  description:
    `The Sky Story film: one page per chapter, ${MAX_SKY_PAGES} at most. Each page shows a day (or a run of days on a long memory) with one hero photo, a few photos around it, and that day's note.`,
  properties: {
    pages: {
      type: "array",
      minItems: 1,
      maxItems: MAX_SKY_PAGES,
      items: {
        type: "object",
        properties: {
          days: {
            type: "array",
            items: { type: "integer" },
            minItems: 2,
            maxItems: 2,
            description:
              "[first, last] day number of the page; [3, 3] for one day.",
          },
          headline: {
            type: "string",
            description:
              `The page's title, at most ${MAX_SKY_HEADLINE_CHARS} characters, e.g. "The quiet hour".`,
          },
          hero_photo_id: { type: "string" },
          extra_photo_ids: {
            type: "array",
            items: { type: "string" },
            maxItems: MAX_SKY_EXTRAS,
          },
          note_id: {
            type: ["string", "null"],
            description: "A note from the page's days, or null.",
          },
          sky_line: {
            type: ["string", "null"],
            description:
              `Only when note_id is null: one short line written on the sky (at most ${MAX_SKY_LINE_CHARS} characters). Otherwise null.`,
          },
        },
        required: [
          "days",
          "headline",
          "hero_photo_id",
          "extra_photo_ids",
          "note_id",
          "sky_line",
        ],
      },
    },
  },
  required: ["pages"],
} as const;

export const SKY_STORY_PROMPT_RULES = [
  "\n\nsky_story — a second film made from the same memory, one page per ",
  "chapter:\n",
  "- 1 to sky_max_pages pages (the film's length, from its photos), in ",
  "day order, their days never overlapping. Up to sky_max_pages days with ",
  "photos: one page per day. More: group ",
  "neighbouring days into pages (days [4, 7]) or pick the best days.\n",
  "- Every must_include photo is shown (hero or extras) on a page of its ",
  "day. A page shows 5 photos; when a day (or a run of days) has more ",
  "must_include photos than its page shows, add a continuation page with ",
  "exactly the same days right after it (days [1, 1], then [1, 1] again) ",
  "while there are fewer than sky_max_pages pages, and split them ",
  "between the pages in time order. A continuation page has its own ",
  "headline and usually no note. With fewer days than sky_max_pages, ",
  "the busiest days also get continuation pages (more than 5 photos a ",
  "page), up to sky_max_pages in all.\n",
  "- hero_photo_id: the page's best photo — sharp, hero_score ≥ 3, from the ",
  "page's days.\n",
  `- extra_photo_ids: up to ${MAX_SKY_EXTRAS} more photos from the page's `,
  "days showing different moments (one per dup_group). No photo twice ",
  "in sky_story.\n",
  "- note_id: the note that best fits the page, from its days, or null. ",
  "With no note, sky_line may carry one short, specific line; else null.\n",
  `- headline: ≤ ${MAX_SKY_HEADLINE_CHARS} characters, specific to that `,
  'day, like "Lost, on purpose" or "Salt in our hair". Never "Day 1".',
].join("");

// What a sky_story is checked against: the memory as it is now.
export interface SkyCheckContext {
  dayCount: number;
  // Day number of every photo the pages may use (not left out, with a day).
  photoDays: ReadonlyMap<string, number>;
  excludedIds: ReadonlySet<string>;
  // "Always" picks (#294) that must be shown.
  mustIncludeIds: ReadonlySet<string>;
  // Day number of every note.
  noteDays: ReadonlyMap<string, number>;
  // The most pages the film's length holds (#434), ≤ MAX_SKY_PAGES.
  maxPages: number;
}

// Day number of [date] in a memory starting [start] (1 = first day).
export function dayNumberOf(start: string, date: string): number {
  const ms = Date.parse(`${date}T00:00:00Z`) -
    Date.parse(`${start}T00:00:00Z`);
  return Math.round(ms / 86_400_000) + 1;
}

function dateOfDay(start: string, day: number): string {
  const ms = Date.parse(`${start}T00:00:00Z`) + (day - 1) * 86_400_000;
  return new Date(ms).toISOString().slice(0, 10);
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

export function skyCheckContext(
  tripData: TripData,
  notRequiredIds: ReadonlySet<string> = new Set(),
): SkyCheckContext {
  // Logical days, as the director sees them (#422).
  tripData = onLogicalDays(tripData);
  const start = tripData.trip.start_date ?? "1970-01-01";
  const photos = skyPhotos(tripData);
  return {
    dayCount: memoryDayCount(tripData),
    photoDays: new Map(
      photos.map((p) => [p.id, dayNumberOf(start, p.day_date!)]),
    ),
    excludedIds: new Set(
      tripData.photos.filter((p) => p.use_in_wrap_up === false).map((p) =>
        p.id
      ),
    ),
    mustIncludeIds: new Set(
      photos.filter((p) =>
        p.use_in_wrap_up === true && !notRequiredIds.has(p.id)
      )
        .map((p) => p.id),
    ),
    noteDays: new Map(
      tripData.notes.filter((n) => n.id).map((n) => [
        n.id!,
        dayNumberOf(start, n.day_date),
      ]),
    ),
    maxPages: skyMaxPages(tripData),
  };
}

// The most pages [tripData]'s film holds (#434): its length follows its
// photos.
export function skyMaxPages(tripData: TripData): number {
  return Math.min(
    MAX_SKY_PAGES,
    skyPagesFor(filmSecondsOf(tripData)),
  );
}

function isString(v: unknown): v is string {
  return typeof v === "string";
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

// Every way [data] breaks the sky_story rules, one readable line each —
// empty when it's valid. Fed back to the model on the plan's retry and
// shown in the Plan inspector.
export function describeSkyStoryProblems(
  data: unknown,
  context: SkyCheckContext,
): string[] {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return ["sky_story: expected an object"];
  }
  const pages = (data as Record<string, unknown>).pages;
  if (!Array.isArray(pages) || pages.length === 0) {
    return ["sky_story.pages: expected at least one page"];
  }
  const problems: string[] = [];
  if (pages.length > context.maxPages) {
    problems.push(
      `sky_story.pages: ${pages.length}, at most ${context.maxPages}`,
    );
  }
  const used = new Set<string>();
  const covered: [number, number][] = [];
  // Photos shown per range of days; continuation pages share their range.
  const shownByRange = new Map<string, { pages: number; shown: string[] }>();
  let lastDay = 0;
  let previous: [number, number] | null = null;

  pages.forEach((raw, i) => {
    const where = `sky_story.pages[${i}]`;
    if (typeof raw !== "object" || raw === null) {
      problems.push(`${where}: expected an object`);
      return;
    }
    const page = raw as Record<string, unknown>;
    const days = page.days;
    let range: [number, number] | null = null;
    if (
      !Array.isArray(days) || days.length !== 2 ||
      !days.every((d) => Number.isInteger(d))
    ) {
      problems.push(`${where}.days: expected [first, last] day numbers`);
    } else {
      const [first, last] = days as [number, number];
      if (first < 1 || last > context.dayCount || first > last) {
        problems.push(
          `${where}.days: [${first}, ${last}] is not within days 1–${context.dayCount}`,
        );
      } else if (
        previous !== null && first === previous[0] && last === previous[1]
      ) {
        // A continuation page of the previous page's days.
        range = [first, last];
      } else if (first <= lastDay) {
        problems.push(
          `${where}.days: [${first}, ${last}] overlaps or comes before the previous page`,
        );
      } else {
        range = [first, last];
        covered.push(range);
        lastDay = last;
      }
      previous = range ?? previous;
    }
    // A page code added for Always picks (#382) has none; the strict
    // schema makes the director's always a string.
    if (page.headline !== null) {
      checkLine(
        problems,
        `${where}.headline`,
        page.headline,
        MAX_SKY_HEADLINE_CHARS,
      );
    }

    const inRange = (id: string) => {
      const day = context.photoDays.get(id);
      return day !== undefined && range !== null && day >= range[0] &&
        day <= range[1];
    };
    const checkPhoto = (id: unknown, field: string) => {
      if (!isString(id)) {
        problems.push(`${where}.${field}: expected a photo id`);
        return;
      }
      if (context.excludedIds.has(id)) {
        problems.push(`${where}.${field}: "${id}" was left out by the user`);
      } else if (!context.photoDays.has(id)) {
        problems.push(
          `${where}.${field}: "${id}" is not a photo id from the input`,
        );
      } else if (range && !inRange(id)) {
        problems.push(`${where}.${field}: "${id}" is not from the page's days`);
      }
      if (used.has(id)) {
        problems.push(`${where}.${field}: "${id}" is used twice`);
      }
      used.add(id);
    };
    checkPhoto(page.hero_photo_id, "hero_photo_id");
    const extras = page.extra_photo_ids;
    if (!Array.isArray(extras)) {
      problems.push(`${where}.extra_photo_ids: expected an array of ids`);
    } else {
      if (extras.length > MAX_SKY_EXTRAS) {
        problems.push(
          `${where}.extra_photo_ids: ${extras.length}, at most ${MAX_SKY_EXTRAS}`,
        );
      }
      extras.forEach((id, k) => checkPhoto(id, `extra_photo_ids[${k}]`));
    }

    const noteId = page.note_id;
    if (noteId !== null && noteId !== undefined) {
      const day = isString(noteId) ? context.noteDays.get(noteId) : undefined;
      if (day === undefined) {
        problems.push(`${where}.note_id: not a note id from the input`);
      } else if (range && (day < range[0] || day > range[1])) {
        problems.push(`${where}.note_id: the note is not from the page's days`);
      }
      if (page.sky_line !== null && page.sky_line !== undefined) {
        problems.push(`${where}.sky_line: only a page without a note has one`);
      }
    } else if (page.sky_line !== null && page.sky_line !== undefined) {
      checkLine(
        problems,
        `${where}.sky_line`,
        page.sky_line,
        MAX_SKY_LINE_CHARS,
      );
    }

    if (range) {
      const key = `${range[0]}-${range[1]}`;
      const entry = shownByRange.get(key) ?? { pages: 0, shown: [] };
      entry.pages++;
      entry.shown.push(
        ...[page.hero_photo_id, ...(Array.isArray(extras) ? extras : [])]
          .filter(isString),
      );
      shownByRange.set(key, entry);
    }
  });

  // Every Always pick on a page of its days (#378). Only once all
  // MAX_SKY_PAGES pages are used and a range's slots all hold Always picks
  // may the rest go without a page.
  for (const [key, { pages: count, shown }] of shownByRange) {
    const [first, last] = key.split("-").map(Number);
    const always = [...context.mustIncludeIds].filter((id) => {
      const day = context.photoDays.get(id)!;
      return day >= first && day <= last;
    });
    const missing = always.filter((id) => !shown.includes(id));
    if (missing.length === 0) continue;
    const full = always.length - missing.length >= count * SKY_PAGE_SLOTS;
    if (full && pages.length >= context.maxPages) continue;
    const days = first === last ? `day ${first}` : `days ${first}–${last}`;
    problems.push(
      full
        ? `sky_story: ${days} has ${missing.length} more photos marked Always than its pages show (first: "${
          missing[0]
        }") — add a continuation page with the same days`
        : `sky_story: photo "${
          missing[0]
        }" is marked Always but not on a page of ${days}`,
    );
  }

  for (const id of context.mustIncludeIds) {
    const day = context.photoDays.get(id)!;
    if (!covered.some(([a, b]) => day >= a && day <= b)) {
      problems.push(
        `sky_story: day ${day} has a photo marked Always but no page`,
      );
    }
  }
  return problems;
}

// Fixes what code can put right without guessing: stray quotes on lines,
// more than MAX_SKY_EXTRAS extras, the hero repeated among its extras, a
// sky_line next to a note, an unknown note id (→ null). Never throws.
export function repairSkyStory(
  data: unknown,
  context: SkyCheckContext,
): unknown {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return data;
  }
  const sky = structuredClone(data) as Record<string, unknown>;
  if (!Array.isArray(sky.pages)) return sky;
  for (const raw of sky.pages) {
    if (typeof raw !== "object" || raw === null) continue;
    const page = raw as Record<string, unknown>;
    // AI lines (#433): banned phrases out, too long → whole words off the
    // end, else none (the app shows the place or "Day N").
    if (isString(page.headline)) {
      page.headline = wholeWords(
        cleanAiLine(page.headline),
        MAX_SKY_HEADLINE_CHARS,
      );
    }
    if (isString(page.sky_line)) {
      page.sky_line = wholeWords(
        cleanAiLine(page.sky_line),
        MAX_SKY_LINE_CHARS,
      );
    }
    if (Array.isArray(page.extra_photo_ids)) {
      page.extra_photo_ids = page.extra_photo_ids
        .filter((id) => id !== page.hero_photo_id)
        .slice(0, MAX_SKY_EXTRAS);
    }
    if (
      page.note_id !== null && page.note_id !== undefined &&
      !(isString(page.note_id) && context.noteDays.has(page.note_id))
    ) {
      page.note_id = null;
    }
    if (page.note_id === undefined) page.note_id = null;
    if (page.note_id !== null) page.sky_line = null;
    if (page.sky_line === undefined) page.sky_line = null;
  }
  placeAlwaysPhotos(sky.pages as unknown[], context);
  return sky;
}

// Puts Always picks the director left off its pages onto pages of their
// days (#382), instead of discarding the pages: first into free extra
// slots, then on continuation pages (no headline, note or sky line) while
// there are fewer than MAX_SKY_PAGES, then in place of Auto extras, then
// of Auto heroes. A day with Always picks and no page at all gets a page
// of its own when there's room. The director's text stays untouched.
function placeAlwaysPhotos(raw: unknown[], context: SkyCheckContext): void {
  type Page = Record<string, unknown> & {
    days: [number, number];
    hero_photo_id: string;
    extra_photo_ids: string[];
  };
  const valid = (p: unknown): p is Page => {
    if (typeof p !== "object" || p === null) return false;
    const page = p as Record<string, unknown>;
    const days = page.days;
    return Array.isArray(days) && days.length === 2 &&
      days.every((d) => Number.isInteger(d)) && isString(page.hero_photo_id) &&
      Array.isArray(page.extra_photo_ids);
  };
  if (!raw.every(valid)) return;
  const pages = raw as Page[];
  // Photos in time order (photoDays is built chronologically).
  const order = new Map([...context.photoDays.keys()].map((id, i) => [id, i]));
  const at = (id: string) => order.get(id) ?? Infinity;
  const always = [...context.mustIncludeIds].sort((a, b) => at(a) - at(b));
  const dayOf = (id: string) => context.photoDays.get(id)!;
  const continuationOf = (days: [number, number], ids: string[]): Page => ({
    days: [days[0], days[1]],
    headline: null,
    hero_photo_id: ids[0],
    extra_photo_ids: ids.slice(1, SKY_PAGE_SLOTS),
    note_id: null,
    sky_line: null,
  });

  // Days with Always picks and no page: a page of their own, in day order.
  const covers = (day: number) =>
    pages.some((p) => day >= p.days[0] && day <= p.days[1]);
  for (const day of [...new Set(always.map(dayOf))]) {
    if (covers(day) || pages.length >= context.maxPages) continue;
    const ids = always.filter((id) => dayOf(id) === day);
    const index = pages.findIndex((p) => p.days[0] > day);
    pages.splice(
      index === -1 ? pages.length : index,
      0,
      continuationOf([day, day], ids),
    );
  }

  // Each run of pages sharing a range of days.
  let i = 0;
  while (i < pages.length) {
    const [first, last] = pages[i].days;
    let end = i + 1;
    while (
      end < pages.length && pages[end].days[0] === first &&
      pages[end].days[1] === last
    ) end++;
    const group = () => pages.slice(i, end);
    const shown = new Set(
      group().flatMap((p) => [p.hero_photo_id, ...p.extra_photo_ids]),
    );
    const missing = always.filter((id) =>
      !shown.has(id) && dayOf(id) >= first && dayOf(id) <= last
    );
    const take = () => {
      const id = missing.shift()!;
      shown.add(id);
      return id;
    };
    // 1. Free extra slots.
    for (const page of group()) {
      while (
        missing.length > 0 && page.extra_photo_ids.length < MAX_SKY_EXTRAS
      ) {
        page.extra_photo_ids.push(take());
      }
    }
    // 2. Continuation pages.
    while (missing.length > 0 && pages.length < context.maxPages) {
      const ids = missing.splice(0, SKY_PAGE_SLOTS);
      pages.splice(end, 0, continuationOf([first, last], ids));
      end++;
    }
    // 3. In place of Auto extras, then 4. of Auto heroes.
    for (const page of group()) {
      page.extra_photo_ids = page.extra_photo_ids.map((id) =>
        missing.length > 0 && !context.mustIncludeIds.has(id) ? take() : id
      );
    }
    for (const page of group()) {
      if (
        missing.length > 0 && !context.mustIncludeIds.has(page.hero_photo_id)
      ) {
        page.hero_photo_id = take();
      }
    }
    i = end;
  }
  raw.splice(0, raw.length, ...pages);
}

// --- Building content.sky -------------------------------------------------

interface DayGroup {
  first: number;
  last: number;
  photos: Photo[];
}

// Splits [days] (in order) into [groups] contiguous runs whose biggest
// photo count is as small as possible; ties keep earlier splits. Days
// without photos are never in [days].
export function groupDays(
  days: { day: number; count: number }[],
  groups: number,
): [number, number][] {
  const n = days.length;
  const k = Math.min(groups, n);
  if (k === 0) return [];
  const prefix = [0];
  for (const d of days) prefix.push(prefix[prefix.length - 1] + d.count);
  const sum = (a: number, b: number) => prefix[b] - prefix[a];
  // best[g][i]: smallest max over the first i days in g groups.
  const best: number[][] = Array.from(
    { length: k + 1 },
    () => Array(n + 1).fill(Infinity),
  );
  const cut: number[][] = Array.from(
    { length: k + 1 },
    () => Array(n + 1).fill(0),
  );
  best[0][0] = 0;
  for (let g = 1; g <= k; g++) {
    for (let i = g; i <= n; i++) {
      for (let j = g - 1; j < i; j++) {
        const value = Math.max(best[g - 1][j], sum(j, i));
        if (value < best[g][i]) {
          best[g][i] = value;
          cut[g][i] = j;
        }
      }
    }
  }
  const ranges: [number, number][] = [];
  let i = n;
  for (let g = k; g >= 1; g--) {
    const j = cut[g][i];
    ranges.unshift([days[j].day, days[i - 1].day]);
    i = j;
  }
  return ranges;
}

// The page's hero: an Always pick, else the best analysed photo, else one
// the user captioned or placed, else the middle photo. Ties → earliest.
export function pickHero(
  photos: Photo[],
  heroScores: Readonly<Record<string, number>>,
): Photo {
  const score = (p: Photo) =>
    (p.use_in_wrap_up === true ? 100 : 0) + (heroScores[p.id] ?? 0) +
    (p.caption || p.place_text ? 0.5 : 0);
  let best = photos[Math.floor((photos.length - 1) / 2)];
  let bestScore = score(best);
  for (const p of photos) {
    if (score(p) > bestScore) {
      best = p;
      bestScore = score(p);
    }
  }
  return best;
}

// Up to MAX_SKY_EXTRAS more photos: Always picks first, the rest spread
// evenly through the page's days; chronological.
export function pickExtras(photos: Photo[], hero: Photo): Photo[] {
  const others = photos.filter((p) => p !== hero);
  const always = others.filter((p) => p.use_in_wrap_up === true)
    .slice(0, MAX_SKY_EXTRAS);
  const rest = others.filter((p) => p.use_in_wrap_up !== true);
  const picked = new Set([
    ...always,
    ...spreadEvenly(rest, MAX_SKY_EXTRAS - always.length),
  ]);
  return others.filter((p) => picked.has(p));
}

// How many pages each range of days gets: one each, then, while there are
// fewer than [maxPages], one more for the range whose Always picks most
// overflow its pages (earliest on a tie) — a busy day split across
// continuation pages (#378).
export function pagesPerRange(
  alwaysCounts: number[],
  maxPages = MAX_SKY_PAGES,
): number[] {
  const pages = alwaysCounts.map(() => 1);
  let total = pages.length;
  while (total < maxPages) {
    let best = -1;
    let bestShortfall = 0;
    alwaysCounts.forEach((count, i) => {
      const shortfall = count - pages[i] * SKY_PAGE_SLOTS;
      if (shortfall > bestShortfall) {
        best = i;
        bestShortfall = shortfall;
      }
    });
    if (best < 0) break;
    pages[best]++;
    total++;
  }
  return pages;
}

// Splits a range's photos (chronological) into [parts] runs, each starting
// at an Always pick, so every part holds an even share of them (15 → 5, 5,
// 5). Auto photos stay with the part they fall in. Needs at least [parts]
// Always picks.
export function splitAtAlways(photos: Photo[], parts: number): Photo[][] {
  if (parts <= 1) return [photos];
  const always = photos.flatMap((p, i) => p.use_in_wrap_up === true ? [i] : []);
  // Pages for a busy range rather than its Always picks (#434): even runs
  // of its photos, in time order.
  if (always.length <= (parts - 1) * SKY_PAGE_SLOTS) {
    return Array.from(
      { length: parts },
      (_, k) =>
        photos.slice(
          Math.round((k * photos.length) / parts),
          Math.round(((k + 1) * photos.length) / parts),
        ),
    ).filter((part) => part.length > 0);
  }
  const starts = [0];
  let taken = 0;
  for (let k = 1; k < parts; k++) {
    taken += Math.ceil((always.length - taken) / (parts - k + 1));
    starts.push(always[taken]);
  }
  return starts.map((start, k) =>
    photos.slice(start, starts[k + 1] ?? photos.length)
  );
}

function noteFor(
  tripData: TripData,
  group: DayGroup,
  start: string,
): string | null {
  // The note of the page's day with the most photos (earliest on a tie).
  let best: { id: string; count: number } | null = null;
  for (const note of tripData.notes) {
    if (!note.id || !note.content.trim()) continue;
    const day = dayNumberOf(start, note.day_date);
    if (day < group.first || day > group.last) continue;
    const count = group.photos.filter((p) => p.day_date === note.day_date)
      .length;
    if (!best || count > best.count) best = { id: note.id, count };
  }
  return best?.id ?? null;
}

function pageContent(
  start: string,
  group: DayGroup,
  fields: Pick<
    SkyPageContent,
    "headline" | "hero_photo_id" | "extra_photo_ids" | "note_id" | "sky_line"
  >,
): SkyPageContent {
  const multi = group.last > group.first;
  return {
    first_day: group.first,
    last_day: multi ? group.last : null,
    date: dateOfDay(start, group.first),
    end_date: multi ? dateOfDay(start, group.last) : null,
    photo_count: group.photos.length,
    note: null,
    excerpts: [],
    ...fields,
  };
}

function groupsOf(
  photos: Photo[],
  start: string,
  ranges: [number, number][],
): DayGroup[] {
  return ranges.map(([first, last]) => ({
    first,
    last,
    photos: photos.filter((p) => {
      const day = dayNumberOf(start, p.day_date!);
      return day >= first && day <= last;
    }),
  }));
}

// While a film's length holds more pages than its ranges have (#434), the
// range with the most photos a page gets one more — never past one page
// per SKY_PAGE_SLOTS photos.
export function morePagesForBusyRanges(
  pages: number[],
  photoCounts: number[],
  maxPages = MAX_SKY_PAGES,
): number[] {
  const result = [...pages];
  if (!isFilmLengthRuleOn()) return result;
  let total = result.reduce((a, b) => a + b, 0);
  while (total < maxPages) {
    let best = -1;
    photoCounts.forEach((count, i) => {
      if (count <= result[i] * SKY_PAGE_SLOTS) return;
      if (best < 0 || count / result[i] > photoCounts[best] / result[best]) {
        best = i;
      }
    });
    if (best < 0) break;
    result[best]++;
    total++;
  }
  return result;
}

// Code-built pages: one per day with photos, or five groups of neighbouring
// days on a longer memory; a range with more Always picks than one page
// shows gets continuation pages while there's room (#378).
export function codeSkyPages(
  tripData: TripData,
  heroScores: Readonly<Record<string, number>> = {},
): SkyPageContent[] {
  // As many pages as the film's length holds (#434).
  const maxPages = skyMaxPages(tripData);
  // Logical days, as the director sees them (#422).
  tripData = onLogicalDays(tripData);
  const start = tripData.trip.start_date;
  if (!start) return [];
  const photos = skyPhotos(tripData);
  const counts = new Map<number, number>();
  for (const p of photos) {
    const day = dayNumberOf(start, p.day_date!);
    counts.set(day, (counts.get(day) ?? 0) + 1);
  }
  const days = [...counts.entries()].sort((a, b) => a[0] - b[0])
    .map(([day, count]) => ({ day, count }));
  const groups = groupsOf(photos, start, groupDays(days, maxPages));
  const pageCounts = morePagesForBusyRanges(
    pagesPerRange(
      groups.map((g) =>
        g.photos.filter((p) => p.use_in_wrap_up === true).length
      ),
      maxPages,
    ),
    groups.map((g) => g.photos.length),
    maxPages,
  );
  return groups.flatMap((group, i) =>
    splitAtAlways(group.photos, pageCounts[i]).map((part, k) => {
      const hero = pickHero(part, heroScores);
      return pageContent(start, group, {
        headline: null,
        hero_photo_id: hero.id,
        extra_photo_ids: pickExtras(part, hero).map((p) => p.id),
        // One note per range: on its first page.
        note_id: k === 0 ? noteFor(tripData, group, start) : null,
        sky_line: null,
      });
    })
  );
}

// The director's pages as stored content. [plan] must already be valid.
export function directorSkyPages(
  tripData: TripData,
  plan: SkyStoryPlan,
): SkyPageContent[] {
  // Logical days, as the director sees them (#422).
  tripData = onLogicalDays(tripData);
  const start = tripData.trip.start_date!;
  const photos = skyPhotos(tripData);
  const groups = groupsOf(photos, start, plan.pages.map((p) => p.days));
  return plan.pages.map((page, i) =>
    pageContent(start, groups[i], {
      headline: page.headline,
      hero_photo_id: page.hero_photo_id,
      extra_photo_ids: page.extra_photo_ids,
      note_id: page.note_id,
      sky_line: page.note_id ? null : page.sky_line,
    })
  );
}

// The first word of the profile name: "Mari Tamm" → "Mari".
export function firstNameOf(
  username: string | null | undefined,
): string | null {
  const first = (username ?? "").trim().split(/\s+/)[0];
  return first ? first : null;
}

// content.sky for a draft: the director's pages when [plan] is a valid,
// current sky_story, else code-built pages. null when the memory has no
// photo on any of its days — the classic film plays.
export function buildSkyContent(
  tripData: TripData,
  plan: SkyStoryPlan | null,
  heroScores: Readonly<Record<string, number>> = {},
): SkyContent | null {
  // Logical days, as the director sees them (#422).
  tripData = onLogicalDays(tripData);
  const pages = plan
    ? directorSkyPages(tripData, plan)
    : codeSkyPages(tripData, heroScores);
  if (pages.length === 0) return null;
  const notes = new Map(
    tripData.notes.filter((n) => n.id).map((n) => [n.id!, n.content.trim()]),
  );
  for (const page of pages) {
    page.note = page.note_id ? notes.get(page.note_id) || null : null;
    if (!page.note) page.note_id = null;
  }
  addSkyExcerpts(tripData, pages);
  capSkyLines(pages);
  // The balloon is decoration: Always picks already have their page, so
  // it's made from the other photos (#378).
  const mosaic = decorativePhotos(
    tripData.photos,
    shownOnPages(pages),
    MAX_SKY_MOSAIC_PHOTOS,
  );
  return {
    sky_version: SKY_VERSION,
    source: plan ? "director" : "code",
    title: tripData.trip.name,
    first_name: firstNameOf(tripData.username),
    moment_count: tripData.photos.length,
    mosaic_photo_ids: mosaic.map((p) => p.id),
    pages,
  };
}

// Lines a Sky Story page can carry (#419): about two a note card.
export const SKY_LINES_PER_PAGE = 2;

// The best lines of a note page's days (#419), page by page (#422): a run
// of pages for the same days shares its days' notes, and each line goes on
// the page whose photos are nearest the note in time — a note on one of a
// page's photos on that page — so the rave note lands on the rave photos.
// Each page keeps its best SKY_LINES_PER_PAGE, in note order; a page with
// none keeps its fallback. Runs without a note page (the director wrote on
// the sky instead) get none.
function addSkyExcerpts(tripData: TripData, pages: SkyPageContent[]): void {
  // Lines that match the memory's vibe come right after feelings (#433).
  const theme = lineThemeFor(chosenTemplate(tripData.trip.vibes));
  const start = tripData.trip.start_date;
  const ms = (iso: string | null | undefined) => iso ? Date.parse(iso) : NaN;
  const noteTime = (n: TripData["notes"][number]) =>
    n.legacy ? NaN : ms(n.taken_at ?? n.created_at);
  const notes = tripData.notes
    .filter((n) => n.id && n.content.trim())
    .sort((a, b) =>
      a.day_date.localeCompare(b.day_date) ||
      (noteTime(a) || 0) - (noteTime(b) || 0)
    );
  const photoTimes = new Map(
    tripData.photos.map((p) => [p.id, ms(p.taken_at ?? p.created_at)]),
  );
  for (const page of pages) page.excerpts = [];
  if (!start) return;
  const lastOf = (p: SkyPageContent) => p.last_day ?? p.first_day;
  let i = 0;
  while (i < pages.length) {
    let end = i + 1;
    while (
      end < pages.length && pages[end].first_day === pages[i].first_day &&
      lastOf(pages[end]) === lastOf(pages[i])
    ) end++;
    const run = pages.slice(i, end);
    i = end;
    if (!run.some((p) => p.note)) continue;
    const ids = run.map((p) => [p.hero_photo_id, ...p.extra_photo_ids]);
    const own = notes.filter((n) => {
      const day = dayNumberOf(start, n.day_date);
      return day >= run[0].first_day && day <= lastOf(run[0]);
    });
    const pageOf = (n: TripData["notes"][number]): number => {
      const tagged = ids.findIndex((page) => page.includes(n.photo_id ?? ""));
      if (tagged >= 0) return tagged;
      const t = noteTime(n);
      if (Number.isNaN(t)) return 0;
      let best = 0;
      let gap = Infinity;
      ids.forEach((page, k) => {
        for (const id of page) {
          const d = Math.abs((photoTimes.get(id) ?? NaN) - t);
          if (d < gap) {
            gap = d;
            best = k;
          }
        }
      });
      return best;
    };
    const byPage = run.map(() => [] as typeof own);
    for (const n of own) byPage[pageOf(n)].push(n);
    const shown = new Set<string>();
    run.forEach((page, k) => {
      page.excerpts = bestLines(
        byPage[k].map((n) => ({ id: n.id!, content: n.content })),
        SKY_LINES_PER_PAGE,
        undefined,
        theme,
      ).filter((l) => !shown.has(l.text))
        .map(({ note_id, text }) => ({ note_id, text }));
      for (const l of page.excerpts) shown.add(l.text);
    });
  }
}

// At most WRAP_UP_LIMITS.maxNoteLines lines over all pages (#433): the
// last pages give theirs up first.
function capSkyLines(pages: SkyPageContent[]): void {
  let total = pages.reduce((n, p) => n + (p.excerpts?.length ?? 0), 0);
  for (
    let k = pages.length - 1;
    k >= 0 && total > WRAP_UP_LIMITS.maxNoteLines;
    k--
  ) {
    const page = pages[k];
    while (page.excerpts?.length && total > WRAP_UP_LIMITS.maxNoteLines) {
      page.excerpts.pop();
      total--;
    }
  }
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
