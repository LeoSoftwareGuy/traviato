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
import { bannedPhraseIn, cleanLine } from "./film_plan.ts";

export const SKY_VERSION = 1;
export const MAX_SKY_PAGES = 5;
export const MAX_SKY_EXTRAS = 4;
export const MAX_SKY_MOSAIC_PHOTOS = 60;
// One line at the headline's 88 px, two at its 64 px minimum.
export const MAX_SKY_HEADLINE_CHARS = 32;
export const MAX_SKY_LINE_CHARS = 70;

type Photo = TripData["photos"][number];

// The director's choices for one page.
export interface SkyStoryPagePlan {
  // First and last day number (1 = the memory's first day); equal for a
  // single day.
  days: [number, number];
  headline: string;
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
  sky_line: string | null;
}

export interface SkyContent {
  sky_version: typeof SKY_VERSION;
  source: "director" | "code";
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
  `- 1–${MAX_SKY_PAGES} pages, in day order, their days never overlapping. `,
  `Up to ${MAX_SKY_PAGES} days with photos: one page per day. More: group `,
  "neighbouring days into pages (days [4, 7]) or pick the best days.\n",
  "- Every day with a must_include photo is on a page, and that page ",
  "shows its must_include photos (hero or extras) as far as its 5 slots ",
  "allow.\n",
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
  };
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
  if (pages.length > MAX_SKY_PAGES) {
    problems.push(
      `sky_story.pages: ${pages.length}, at most ${MAX_SKY_PAGES}`,
    );
  }
  const used = new Set<string>();
  const covered: [number, number][] = [];
  let lastDay = 0;

  pages.forEach((raw, i) => {
    const where = `sky_story.pages[${i}]`;
    if (typeof raw !== "object" || raw === null) {
      problems.push(`${where}: expected an object`);
      return;
    }
    const page = raw as Record<string, unknown>;
    checkLine(
      problems,
      `${where}.headline`,
      page.headline,
      MAX_SKY_HEADLINE_CHARS,
    );

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
      } else if (first <= lastDay) {
        problems.push(
          `${where}.days: [${first}, ${last}] overlaps or comes before the previous page`,
        );
      } else {
        range = [first, last];
        covered.push(range);
        lastDay = last;
      }
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

    // Always picks of the page's days, as far as its slots allow.
    if (range) {
      const always = [...context.mustIncludeIds].filter(inRange);
      const shown = [
        page.hero_photo_id,
        ...(Array.isArray(extras) ? extras : []),
      ];
      const missing = always.filter((id) => !shown.includes(id));
      const slots = 1 + MAX_SKY_EXTRAS;
      if (missing.length > 0 && always.length - missing.length < slots) {
        problems.push(
          `${where}: photo "${
            missing[0]
          }" is marked Always but not on its page`,
        );
      }
    }
  });

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
    if (isString(page.headline)) page.headline = cleanLine(page.headline);
    if (isString(page.sky_line)) {
      page.sky_line = cleanLine(page.sky_line) || null;
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
  return sky;
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

// Code-built pages: one per day with photos, or five groups of neighbouring
// days on a longer memory.
export function codeSkyPages(
  tripData: TripData,
  heroScores: Readonly<Record<string, number>> = {},
): SkyPageContent[] {
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
  return groupsOf(photos, start, groupDays(days, MAX_SKY_PAGES)).map(
    (group) => {
      const hero = pickHero(group.photos, heroScores);
      return pageContent(start, group, {
        headline: null,
        hero_photo_id: hero.id,
        extra_photo_ids: pickExtras(group.photos, hero).map((p) => p.id),
        note_id: noteFor(tripData, group, start),
        sky_line: null,
      });
    },
  );
}

// The director's pages as stored content. [plan] must already be valid.
export function directorSkyPages(
  tripData: TripData,
  plan: SkyStoryPlan,
): SkyPageContent[] {
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
  const pages = plan
    ? directorSkyPages(tripData, plan)
    : codeSkyPages(tripData, heroScores);
  if (pages.length === 0) return null;
  const mosaic = sortPhotosChronologically(
    tripData.photos.filter((p) => p.use_in_wrap_up !== false),
  );
  return {
    sky_version: SKY_VERSION,
    source: plan ? "director" : "code",
    first_name: firstNameOf(tripData.username),
    moment_count: tripData.photos.length,
    mosaic_photo_ids: spreadEvenly(mosaic, MAX_SKY_MOSAIC_PHOTOS).map((p) =>
      p.id
    ),
    pages,
  };
}
