// Sky Story's words, picked from code's candidates (#463, as Neon's #454
// and Golden Vows' #458).
//
// The pages are cut by code (sky_skeleton.ts). Each place on a page that
// shows words is a slot with up to MAX_SLOT_CANDIDATES candidates, each
// with a stable id; the director only picks ids (pick_sky_lines) and may
// write a headline of its own. Anything else takes the slot's top
// candidate; nothing is rewritten.
//
// Slots of page K:
// - pK.headline (≤ 32): names the page — its place, a caption that names
//   something, a name or phrase of its own notes, in the notes' language;
//   never the memory's name, a clock time or "Day N". Nothing fits: null,
//   and the app shows the place, else "Day N".
// - pK.lineN: a line of a note that belongs to the page — the note's own
//   photo's page, else the page whose photos it was written among (the
//   #456 rule, a hard filter). A page of one day has line1 and line2; a
//   page of several days a line of each of its days with notes (at most
//   SKY_GROUP_LINES). A note of a day without photos plays on the nearest
//   page only when that page's own days have no note.
// - pK.sky_line (≤ 70): only on a page without a note line — the user's
//   captions of the page's photos (the hero shows its own) and its other
//   places (its headline names the main one), or the director's words made
//   only of the user's (skyWordsProblem). Nothing to build it from: no
//   slot, no line — never filler.
// The opening and the outro show the memory's name exactly: no slot.

import type { TripData } from "./gather.ts";
import type { ToolDefinition } from "./anthropic_tool.ts";
import type { WrapUpLanguage } from "./language.ts";
import { excerptScore, isGeneric, lineThemeFor } from "./excerpts.ts";
import { chosenTemplate } from "./film_template.ts";
import {
  choose,
  dayBefore,
  freeTextProblem,
  hash,
  hasVerb,
  linesOf,
  namePhrases,
  namesOf,
  norm,
  noteLineId,
  notePhrases,
  noteScene,
  placeOf,
  scopedId,
  type SlotCandidate,
  type SlotChosen,
  type SlotPicks,
  TIER_BONUS,
  titleText,
  topDistinct,
  type WordGuard,
  wordGuard,
  wordsProblem,
  writtenLanguage,
  YESTERDAY,
} from "./film_slots.ts";
import { repeatsTitle, sameLine } from "./neon_night.ts";
import { tripLogicalDays } from "./logical_day.ts";
import { MAX_SKY_HEADLINE_CHARS, MAX_SKY_LINE_CHARS } from "./sky_story.ts";
import type { SkySkeleton } from "./sky_skeleton.ts";

type Photo = TripData["photos"][number];
type Note = TripData["notes"][number];

// Lines on a page of one day: about two fit a note card (#419).
export const SKY_LINES_PER_PAGE = 2;
// A page of several days: a line of each of its days, at most this many.
export const SKY_GROUP_LINES = 3;
// A note line's most characters (the app shows only what fits its card).
export const MAX_SKY_NOTE_LINE_CHARS = 90;

export type SkySlotKind = "line" | "sky_line" | "headline";

export interface SkySlot {
  // "p1.headline", "p1.line1", "p1.sky_line".
  slot: string;
  kind: SkySlotKind;
  // 0-based page.
  page: number;
  // A grouped page's line: the day its candidates come from.
  day?: string;
  max_picks: number;
  // Whether the director may write its own words here.
  free: boolean;
  candidates: SkySlotCandidate[];
}

export type SkySlotCandidate = SlotCandidate;

// The language of the film's words: the notes', else the app's.
export function skyLanguage(
  tripData: TripData,
  language: WrapUpLanguage,
): "ru" | "en" {
  return writtenLanguage(tripData) ?? language;
}

// A note's day (#463): its logical day while that's a day of the memory,
// else the day it was saved on (a note written after the trip, about a
// day of it); "вчера…" the day before.
export function skyNoteDay(
  tripData: TripData,
  days: ReadonlyMap<string, string | null>,
  n: Note,
): string {
  const { start_date, end_date } = tripData.trip;
  const logical = days.get(`note:${n.id}`) ?? n.day_date;
  const within = (d: string) =>
    (!start_date || d >= start_date) && (!end_date || d <= end_date);
  const day = within(logical) ? logical : n.day_date;
  const before = dayBefore(day);
  return YESTERDAY.test(n.content) && within(before) ? before : day;
}

// Where each note plays (#463, the #456 rule): the page of its own photo,
// else a page of its day — among a day's parts, the one whose photos it
// was written among — else, for a day without photos, the nearest page
// when that page's own days have no note; null: nowhere.
export function skyNoteHomes(
  tripData: TripData,
  skeleton: SkySkeleton,
): Map<string, number | null> {
  const days = tripLogicalDays(tripData);
  const notes = tripData.notes.filter((n) => n.id && n.content.trim());
  const pages = skeleton.pages;
  const homes = new Map<string, number | null>();
  const withOwn = new Set<number>();
  const later: Note[] = [];
  for (const n of notes) {
    const own = pages.findIndex((p) =>
      p.photos.some((x) => x.id === n.photo_id)
    );
    const day = skyNoteDay(tripData, days, n);
    const onDay = pages.flatMap((p, k) => p.days.includes(day) ? [k] : []);
    const page = own >= 0
      ? own
      : onDay.length === 0
      ? null
      : onDay.length === 1
      ? onDay[0]
      : onDay[noteScene(onDay.map((k) => pages[k].photos), n)];
    if (page === null) {
      later.push(n);
      continue;
    }
    homes.set(n.id!, page);
    withOwn.add(page);
  }
  // A day without photos: the nearest page by day, if it has no note.
  const start = tripData.trip.start_date;
  for (const n of later) {
    const day = skyNoteDay(tripData, days, n);
    let best: number | null = null;
    let gap = Infinity;
    pages.forEach((p, k) => {
      const d = Math.min(
        ...p.days.map((x) => Math.abs(Date.parse(x) - Date.parse(day))),
      );
      if (d < gap) {
        gap = d;
        best = k;
      }
    });
    homes.set(
      n.id!,
      start && best !== null && !withOwn.has(best) ? best : null,
    );
  }
  return homes;
}

// Every slot of the film with its candidates (#463).
export function buildSkySlots(
  tripData: TripData,
  skeleton: SkySkeleton,
  appLanguage: WrapUpLanguage,
): SkySlot[] {
  const language = skyLanguage(tripData, appLanguage);
  const names = namesOf(tripData);
  const theme = lineThemeFor(chosenTemplate(tripData.trip.vibes));
  const days = tripLogicalDays(tripData);
  const noteDay = (n: Note) => skyNoteDay(tripData, days, n);
  const notes = tripData.notes.filter((n) => n.id && n.content.trim());
  const homes = skyNoteHomes(tripData, skeleton);
  const memoryName = tripData.trip.name?.trim() ?? "";
  const title = (text: string, scored: boolean, needsSpace = false) => {
    const t = titleText(
      text,
      MAX_SKY_HEADLINE_CHARS,
      language,
      names,
      needsSpace,
      scored,
      theme,
    );
    // Never the memory's name: the opening shows it.
    return t && !sameLine(t, memoryName) && !hasVerb(t) ? t : null;
  };
  const lineCandidates = (own: readonly Note[]) => {
    const lines = own.flatMap((n) => linesOf(n, theme))
      .filter((l) => [...l.text].length <= MAX_SKY_NOTE_LINE_CHARS);
    const specific = lines.some((l) => l.tier !== "generic");
    return topDistinct(
      lines.filter((l) => !specific || l.tier !== "generic").map((l) => ({
        id: noteLineId(l.note.id!, l.text),
        text: l.text,
        note_id: l.note.id!,
        photo_id: l.note.photo_id ?? null,
        score: l.score + TIER_BONUS[l.tier],
      })),
    );
  };
  const slots: SkySlot[] = [];
  skeleton.pages.forEach((page, k) => {
    const slot = `p${k + 1}`;
    const own = notes.filter((n) => homes.get(n.id!) === k);

    // Its lines.
    let lineSlots: SkySlot[];
    if (page.days.length === 1) {
      const candidates = lineCandidates(own);
      lineSlots = candidates.length === 0 ? [] : Array.from(
        { length: Math.min(SKY_LINES_PER_PAGE, candidates.length) },
        (_, j) => ({
          slot: `${slot}.line${j + 1}`,
          kind: "line" as const,
          page: k,
          max_picks: 1,
          free: false,
          candidates,
        }),
      );
    } else {
      // A line of each of its days with notes (#463), the best days when
      // more have notes than fit; a note of a photoless day under its
      // nearest day.
      const byDay = page.days.map((day) => ({
        day,
        candidates: lineCandidates(
          own.filter((n) =>
            page.days.includes(noteDay(n))
              ? noteDay(n) === day
              : day === page.days[page.days.length - 1]
          ),
        ),
      })).filter((d) => d.candidates.length > 0);
      const best = [...byDay].sort((a, b) =>
        b.candidates[0].score - a.candidates[0].score
      ).slice(0, SKY_GROUP_LINES);
      lineSlots = byDay.filter((d) => best.includes(d)).map((d, j) => ({
        slot: `${slot}.line${j + 1}`,
        kind: "line" as const,
        page: k,
        day: d.day,
        max_picks: 1,
        free: false,
        candidates: d.candidates,
      }));
    }
    slots.push(...lineSlots);

    // Its sky line, only without a note line: the page's captions (the
    // hero's shows on the hero) and places; nothing → no slot.
    if (lineSlots.length === 0) {
      const captions = page.extras.flatMap((p) => {
        const c = p.caption?.trim();
        return c && [...c].length <= MAX_SKY_LINE_CHARS
          ? [{
            id: `c:${p.id}`,
            text: c,
            note_id: null,
            photo_id: p.id,
            score: 40 + excerptScore(c, theme),
          }]
          : [];
      });
      // Places other than the page's own (its headline names that one).
      const main = placeOf(page.photos);
      const others = [
        ...new Set(page.photos.map((p) => p.place_text?.trim() ?? "")),
      ].filter((t) => t && t !== main && [...t].length <= MAX_SKY_LINE_CHARS);
      const placeLine = others.map((t) => ({
        id: `p:${hash(t)}`,
        text: t,
        note_id: null,
        photo_id: null,
        score: 10,
      }));
      const candidates = topDistinct([...captions, ...placeLine]);
      if (candidates.length > 0) {
        slots.push({
          slot: `${slot}.sky_line`,
          kind: "sky_line",
          page: k,
          max_picks: 1,
          free: true,
          candidates,
        });
      }
    }

    // Its headline: names the page, from its own notes and photos.
    const headlines: SlotCandidate[] = [];
    if (place(page.photos)) {
      const t = title(place(page.photos)!, false);
      if (
        t && !(language === "ru" && !/\p{Script=Cyrillic}/u.test(t))
      ) {
        headlines.push({
          id: `p:${hash(t)}`,
          text: t,
          note_id: null,
          photo_id: null,
          score: 30,
        });
      }
    }
    for (const p of page.photos) {
      const t = p.caption && title(p.caption, true);
      if (t) {
        headlines.push({
          id: `c:${p.id}`,
          text: t,
          note_id: null,
          photo_id: p.id,
          score: 20 + excerptScore(t, theme),
        });
      }
    }
    for (const n of own) {
      for (const phrase of namePhrases(n.content)) {
        // Several words: a lone capitalised word opens a sentence more
        // often than it names one.
        const t = title(phrase, false, true);
        if (t) {
          headlines.push({
            id: noteLineId(n.id!, t),
            text: t,
            note_id: n.id!,
            photo_id: null,
            score: 15,
          });
        }
      }
      for (const phrase of notePhrases(n.content)) {
        const t = title(
          phrase.charAt(0).toUpperCase() + phrase.slice(1),
          false,
        );
        if (t) {
          headlines.push({
            id: noteLineId(n.id!, t),
            text: t,
            note_id: n.id!,
            photo_id: null,
            score: 12,
          });
        }
      }
    }
    slots.push({
      slot: `${slot}.headline`,
      kind: "headline",
      page: k,
      max_picks: 1,
      free: true,
      candidates: topDistinct(headlines),
    });
  });
  return slots;
}

const place = placeOf;

export interface SkySlotResult {
  slot: string;
  kind: SkySlotKind;
  chosen: SlotChosen[];
  source: "director" | "code" | "none";
  reason: string;
}

export interface SkyResolveOptions {
  language: "ru" | "en";
  names: ReadonlySet<string>;
  // What the director's own words may say; none: no check.
  guard?: WordGuard;
  // Words the film shows anyway: the memory's name, the heroes' captions.
  shown: readonly string[];
}

// Small words a headline or sky line may add to the user's (#463): the
// joints of a phrase, never its facts.
const JOINING_WORDS = new Set([
  "a",
  "an",
  "the",
  "and",
  "or",
  "of",
  "in",
  "on",
  "at",
  "to",
  "by",
  "for",
  "with",
  "from",
  "into",
  "over",
  "under",
  "after",
  "before",
  "our",
  "my",
  "your",
  "we",
  "you",
  "us",
  "is",
  "it",
  "its",
  "this",
  "that",
  "then",
  "all",
  "day",
  "night",
  "morning",
  "evening",
  "first",
  "last",
  "one",
  "two",
  "three",
  "и",
  "в",
  "во",
  "на",
  "с",
  "со",
  "к",
  "ко",
  "по",
  "за",
  "под",
  "над",
  "из",
  "у",
  "о",
  "об",
  "для",
  "до",
  "после",
  "а",
  "но",
  "наш",
  "наша",
  "наше",
  "наши",
  "мы",
  "день",
  "ночь",
  "утро",
  "вечер",
  "первый",
  "последний",
]);

// Why the director's own [text] can't play on a Sky page (#463: the
// user's rule — only from their captions, places and notes; names as
// written; nothing only the photo descriptions say), or null.
export function skyWordsProblem(
  text: string,
  guard: WordGuard,
): string | null {
  const shared = wordsProblem(text, guard);
  if (shared) return shared;
  for (const raw of text.split(/[^\p{L}\p{N}'’]+/u).filter(Boolean)) {
    const w = raw.replace(/['’]s?$/u, "").toLowerCase();
    if (/^\p{N}+$/u.test(w) || JOINING_WORDS.has(w)) continue;
    if (!guard.own.has(w)) return `«${raw}»: not in the user's words`;
  }
  return null;
}

// The guard for [tripData]: the user's words only (Sky has no lines of
// its own).
export function skyWordGuard(
  tripData: TripData,
  summaries: ReadonlyMap<string, string>,
): WordGuard {
  return wordGuard(tripData, summaries);
}

// Lines first (the user's words), then the sky lines, the headlines last
// — so a headline never takes a line's words.
const ORDER: SkySlotKind[] = ["line", "sky_line", "headline"];

const MAX_FREE: Record<SkySlotKind, number> = {
  line: 0,
  sky_line: MAX_SKY_LINE_CHARS,
  headline: MAX_SKY_HEADLINE_CHARS,
};

// Each slot's words (#463): the director's pick from the slot's own list
// that shows nothing the film already shows, else the top candidate.
export function resolveSkySlots(
  slots: readonly SkySlot[],
  picks: SlotPicks | null,
  options: SkyResolveOptions,
): Map<string, SkySlotResult> {
  const lines: string[] = [];
  const titles: string[] = options.shown.filter((t) => t.trim());
  const results = new Map<string, SkySlotResult>();
  const ordered = [...slots].sort((a, b) =>
    ORDER.indexOf(a.kind) - ORDER.indexOf(b.kind)
  );
  for (const slot of ordered) {
    const isLine = slot.kind !== "headline";
    // A line never repeats another, nor a clause of it.
    const within = (a: string, b: string) =>
      norm(a).includes(norm(b)) || norm(b).includes(norm(a));
    const free = (text: string) =>
      isLine
        ? !lines.some((l) => sameLine(l, text) || within(l, text)) &&
          !titles.some((t) => sameLine(t, text))
        : !titles.some((t) => sameLine(t, text)) &&
          !lines.some((l) => sameLine(l, text) || repeatsTitle(l, text));
    const pick = picks?.[slot.slot];
    const picked = choose(slot, pick, {
      freeText: slot.free
        ? (text) =>
          freeTextProblem(text, options, MAX_FREE[slot.kind], false) ??
            (options.guard ? skyWordsProblem(text, options.guard) : null) ??
            (free(text) ? null : "repeats words the film shows")
        : null,
      fits: (chosen, c) =>
        !free(c.text)
          ? "shows words the film already shows"
          : chosen.some((x) => sameLine(x.text, c.text))
          ? "repeats another pick"
          : null,
    });
    const { chosen, problems, source } = picked;
    for (const c of chosen) (isLine ? lines : titles).push(c.text);
    const reason = source === "director"
      ? problems.length > 0
        ? `director's pick; dropped ${problems.join("; ")}`
        : "director's pick"
      : source === "none"
      ? slot.candidates.length === 0
        ? slot.kind === "headline"
          ? "nothing names it: the app shows the place, else the day"
          : "no candidates"
        : "every candidate shows words the film already shows"
      : !picks
      ? "no director picks: top candidate"
      : !pick
      ? "director left it: top candidate"
      : problems.length > 0
      ? `${problems.join("; ")} → top candidate`
      : "director picked none: top candidate";
    results.set(slot.slot, {
      slot: slot.slot,
      kind: slot.kind,
      chosen,
      source,
      reason,
    });
  }
  return results;
}

// The notes on no page's list, and why (#463).
export function skyUnlistedNotes(
  tripData: TripData,
  skeleton: SkySkeleton,
  slots: readonly SkySlot[],
): { note_id: string; text: string; reason: string }[] {
  const listed = new Set(
    slots.filter((s) => s.kind === "line").flatMap((s) =>
      s.candidates.map((c) => c.note_id)
    ),
  );
  const theme = lineThemeFor(chosenTemplate(tripData.trip.vibes));
  const homes = skyNoteHomes(tripData, skeleton);
  return tripData.notes.filter((n) =>
    n.id && n.content.trim() && !listed.has(n.id)
  ).map((n) => {
    const lines = linesOf(n, theme);
    const reason = homes.get(n.id!) === null || !homes.has(n.id!)
      ? "a day without photos, and the nearest page has a note of its own"
      : lines.length === 0
      ? "no line left after the drug filter"
      : lines.every((l) => isGeneric(l.text))
      ? "only generic lines, and its page has a specific one"
      : `no line fits a page (≤ ${MAX_SKY_NOTE_LINE_CHARS} chars)`;
    return { note_id: n.id!, text: n.content, reason };
  });
}

// --- The director's call ----------------------------------------------------

export const pickSkyLinesTool: ToolDefinition = {
  name: "pick_sky_lines",
  description:
    "Pick the words of this memory's Sky Story film: for every slot, candidate ids from that slot's list.",
  input_schema: {
    type: "object",
    properties: {
      picks: {
        type: "array",
        description: "One entry per slot of the input, in any order.",
        items: {
          type: "object",
          properties: {
            slot: { type: "string", description: "The slot's id." },
            ids: {
              type: "array",
              description:
                "Candidate ids from this slot's own list, exactly as listed (each begins with this slot's name): at most 1. Empty when you write free_title, or when no candidate fits.",
              items: { type: "string" },
            },
            free_title: {
              type: ["string", "null"],
              description:
                "Only for slots with free: true — your own words, whenever they are better than the candidates, at most the slot's max_chars, in the notes' language, made only of the person's own words. Otherwise null.",
            },
          },
          required: ["slot", "ids", "free_title"],
        },
      },
    },
    required: ["picks"],
  },
};

export function buildSkyPickSystemPrompt(language: "ru" | "en"): string {
  return [
    "You choose the words of a Sky Story film — a hot-air balloon rising ",
    "through a dusk-to-night sky, one page per day of a person's memory. ",
    "The film is already cut: its pages, their photos and its length are ",
    "fixed. Each slot lists candidate lines, the person's own words, with ",
    "ids. Emit your choice with the pick_sky_lines tool, one entry per ",
    "slot.\n\n",
    "Rules:\n",
    '- Every id begins with its slot\'s name ("p2.line1/n:…") and is ',
    "valid only in that slot: pick only ids from the slot's own list, ",
    "exactly as listed. Never invent an id or change a line.\n",
    "- Choose what best tells this memory, in this order: feelings first, ",
    "then specific details (places, food, names, firsts). A generic line ",
    "only when nothing else is there.\n",
    "- Never the same words twice in the film; a page's line1 and line2 ",
    "say different things.\n",
    "- pK.headline names page K — a place, event or moment, a few words, ",
    "never half a sentence, never the memory's name.\n",
    "- pK.sky_line: a short line on the sky of a page without a note.\n",
    "- free_title (slots with free: true): write it whenever your words ",
    "are better than the candidates — at most the slot's max_chars, in ",
    "the notes' language, built only from the person's notes, captions ",
    "and places: names exactly as written, nothing only the photo ",
    'descriptions say, never a clock time or "Day N", never invent facts. ',
    "Nothing to build it from: null.\n",
    `- The notes' language: ${language === "ru" ? "Russian" : "English"}.`,
  ].join("");
}

// What the director sees (#463): the memory's facts, the cut pages and
// every slot with its candidates.
export function buildSkyPickInput(
  tripData: TripData,
  skeleton: SkySkeleton,
  slots: readonly SkySlot[],
  analyses: ReadonlyMap<string, { summary: string; hero_score: number }>,
  clock: (
    iso: string | null,
    item?: { utc_offset_minutes?: number | null },
  ) => string | null,
) {
  const { trip } = tripData;
  const photo = (p: Photo) => ({
    photo_id: p.id,
    time: clock(p.taken_at ?? p.created_at, p),
    summary: analyses.get(p.id)?.summary ?? null,
    caption: p.caption?.trim() || null,
    place: p.place_text?.trim() || null,
  });
  return {
    memory: {
      name: trip.name,
      destination: trip.destination,
      start_date: trip.start_date,
      end_date: trip.end_date,
      vibes: trip.vibes,
    },
    notes_language: writtenLanguage(tripData),
    notes: tripData.notes.filter((n) => n.id && n.content.trim()).map((n) => ({
      note_id: n.id,
      written_at: clock(
        n.legacy ? null : n.taken_at ?? n.created_at ?? null,
        n,
      ),
      photo_id: n.photo_id ?? null,
      text: n.content,
    })),
    pages: skeleton.pages.map((p, k) => ({
      page: `p${k + 1}`,
      days: p.days,
      hero: photo(p.hero),
      extras: p.extras.map(photo),
    })),
    slots: slots.map((s) => ({
      slot: s.slot,
      free: s.free,
      max_chars: s.free ? MAX_FREE[s.kind] : null,
      candidates: s.candidates.map((c) => ({
        id: scopedId(s.slot, c.id),
        text: c.text,
      })),
    })),
  };
}
