// Golden Vows' words, picked from code's candidates (#458, Neon's #454).
//
// The album is cut by code (gv_skeleton.ts). Each place that shows words
// is a slot with up to MAX_SLOT_CANDIDATES candidates — the user's own
// words first (their notes' lines, names and places, their captions),
// neutral romantic lines last — each with a stable id. The director only
// picks ids (pick_golden_vows_lines); it may write its own words for the
// title page, a main page's label, a chapter's or the carousel's title and
// the finale. Anything else takes the slot's top candidate; nothing is
// rewritten.
//
// Slots:
// - occasion: the title page's line (≤ 32), wedding words only when the
//   occasion is a wedding's (#433);
// - mainK.label: what main page K shows (≤ 18);
// - mainK.note: its taped note — a captioned photo's caption, fixed (the
//   user's own words, as written); else a line of a note of its chapter
//   whose time or photo is nearest that page's photo (#458);
// - chN.title: chapter N's title (≤ 28), naming it: its place, the names
//   in its notes, its captions that name something; "День N" last;
// - carousel.title (≤ 28), only with a carousel;
// - finale: the line under the heart (≤ 40).
// A chapter's eyebrow ("Глава первая · Утро") is code's, not a slot.

import type { TripData } from "./gather.ts";
import type { ToolDefinition } from "./anthropic_tool.ts";
import type { WrapUpLanguage } from "./language.ts";
import { excerptScore, isGeneric } from "./excerpts.ts";
import {
  choose,
  dayTitleFor,
  freeTextProblem,
  hash,
  hasVerb,
  isNegative,
  linesOf,
  MAX_SLOT_CANDIDATES,
  namePhrases,
  namesOf,
  nearestPhoto,
  noteChapters,
  noteLineId,
  noteTime,
  placeOf,
  scopedId,
  shortClauses,
  type SlotCandidate,
  type SlotChosen,
  type SlotPicks,
  TIER_BONUS,
  titleText,
  top,
  writtenLanguage,
} from "./film_slots.ts";
import { repeatsTitle, sameLine, timeOf } from "./neon_night.ts";
import {
  type GvOccasion,
  MAX_GV_END_CHARS,
  MAX_GV_HERO_LINE_CHARS,
  MAX_GV_LABEL_CHARS,
  MAX_GV_OCCASION_CHARS,
  MAX_GV_TITLE_CHARS,
} from "./golden_vows.ts";
import type { GvSkeleton } from "./gv_skeleton.ts";

type Photo = TripData["photos"][number];
type Note = TripData["notes"][number];

const THEME = "romance" as const;

export type GvSlotKind =
  | "note"
  | "label"
  | "title"
  | "occasion"
  | "carousel"
  | "finale";

export interface GvSlot {
  // "occasion", "main1.label", "main1.note", "ch1.title", "carousel.title",
  // "finale".
  slot: string;
  kind: GvSlotKind;
  // 0-based main page or chapter; null for the album's own slots.
  main: number | null;
  chapter: number | null;
  max_picks: number;
  // Whether the director may write its own words here.
  free: boolean;
  // A captioned main page's note: its caption plays whatever is picked.
  fixed: boolean;
  candidates: SlotCandidate[];
}

// The lines code offers in each language (#458), the neutral ones ranked
// below the user's own words. Wedding words only for a wedding (#433).
type Lines = Record<GvOccasion, string[]>;
const OCCASION_LINES: Record<"ru" | "en", Lines> = {
  en: {
    wedding: ["Our Wedding Day", "Just married", "The big day"],
    engagement: ["We're engaged", "She said yes", "Our engagement"],
    anniversary: ["Our anniversary", "Another year of us"],
    date_night: ["Date night", "Just the two of us"],
    romance: ["Just us", "The two of us", "Together"],
  },
  ru: {
    wedding: ["Наша свадьба", "День нашей свадьбы", "Мы поженились"],
    engagement: ["Наша помолвка", "Она сказала «да»"],
    anniversary: ["Наша годовщина", "Ещё один год вместе"],
    date_night: ["Наш вечер", "Свидание"],
    romance: ["Только мы", "Мы вдвоём", "Вместе"],
  },
};
const LABELS: Record<"ru" | "en", { wedding: string[]; other: string[] }> = {
  en: {
    wedding: ["The vows", "First dance", "The rings"],
    other: ["Just us", "Together", "Our moment", "Close", "Smiles"],
  },
  ru: {
    wedding: ["Клятвы", "Первый танец", "Кольца"],
    other: ["Только мы", "Вместе", "Наш момент", "Рядом", "Улыбки"],
  },
};
const CAROUSEL: Record<"ru" | "en", { wedding: string[]; other: string[] }> = {
  en: {
    wedding: ["And the night went on"],
    other: ["More of us", "Every little moment", "And the day went on"],
  },
  ru: {
    wedding: ["И праздник продолжался"],
    other: ["Ещё о нас", "Каждый момент", "И день продолжался"],
  },
};
const FINALE: Record<"ru" | "en", { wedding: string[]; other: string[] }> = {
  en: {
    wedding: ["Forever starts here", "Happily ever after"],
    other: ["Ours, always", "Until next time", "To be continued"],
  },
  ru: {
    wedding: ["Навсегда начинается здесь", "Долго и счастливо"],
    other: ["Наше, навсегда", "До новых встреч", "Продолжение следует"],
  },
};
const WEDDING_OCCASIONS: readonly GvOccasion[] = ["wedding", "engagement"];

// A neutral line's score: below every line of the user's.
const NEUTRAL_SCORE = 0;

// The chapters' eyebrows (#458): their number and part of the day.
const NUMBERS: Record<"ru" | "en", string[]> = {
  en: ["Chapter one", "Chapter two", "Chapter three", "Chapter four"],
  ru: ["Глава первая", "Глава вторая", "Глава третья", "Глава четвёртая"],
};
const PARTS: Record<"ru" | "en", [string, string, string, string]> = {
  en: ["Morning", "Afternoon", "Evening", "Night"],
  ru: ["Утро", "День", "Вечер", "Ночь"],
};

// The language of the film's words: the notes', else the app's.
export function gvLanguage(
  tripData: TripData,
  language: WrapUpLanguage,
): "ru" | "en" {
  return writtenLanguage(tripData) ?? language;
}

// The part of the day [photos] start in: 0 morning … 3 night, or null.
function partOf(
  photos: readonly Photo[],
  utcOffsetMinutes: number,
): number | null {
  const t = photos.map(timeOf).find((x) => x > 0);
  if (!t) return null;
  const hour = new Date(t + utcOffsetMinutes * 60_000).getUTCHours();
  return hour >= 5 && hour < 12
    ? 0
    : hour >= 12 && hour < 17
    ? 1
    : hour >= 17 && hour < 22
    ? 2
    : 3;
}

// Chapter [i]'s eyebrow: "Глава первая · Утро", by its first photo's
// local hour.
export function gvChapterLine(
  photos: readonly Photo[],
  i: number,
  language: "ru" | "en",
  utcOffsetMinutes: number,
): string {
  const number = NUMBERS[language][i] ?? NUMBERS[language][3];
  const part = partOf(photos, utcOffsetMinutes);
  return part === null ? number : `${number} · ${PARTS[language][part]}`;
}

// A chapter's last-resort title, as Neon Night's (#454): "День N", a
// later part of the same day "День 1 · вечер", the same stretch again
// "День 1 · вторая ночь" — never a clock time, never two alike.
export function gvDayTitle(
  tripData: TripData,
  skeleton: GvSkeleton,
  i: number,
  language: "ru" | "en",
): string {
  return dayTitleFor(tripData, skeleton.chapters, language)(i);
}

// [list] without lines that differ only in case, spacing or punctuation
// from a better one before them.
function distinct(list: SlotCandidate[]): SlotCandidate[] {
  const kept: SlotCandidate[] = [];
  for (const c of [...list].sort((a, b) => b.score - a.score)) {
    if (!kept.some((k) => sameLine(k.text, c.text))) kept.push(c);
  }
  return kept;
}

const topDistinct = (list: SlotCandidate[]) => top(distinct(list));

const neutral = (
  list: readonly string[],
  prefix: string,
): SlotCandidate[] =>
  list.map((text, k) => ({
    id: `${prefix}:${hash(text)}`,
    text,
    note_id: null,
    photo_id: null,
    score: NEUTRAL_SCORE - k,
  }));

// Every slot of the album with its candidates (#458).
export function buildGvSlots(
  tripData: TripData,
  skeleton: GvSkeleton,
  appLanguage: WrapUpLanguage,
): GvSlot[] {
  const language = gvLanguage(tripData, appLanguage);
  const names = namesOf(tripData);
  const wedding = WEDDING_OCCASIONS.includes(skeleton.occasion);
  const notes = tripData.notes.filter((n) => n.id && n.content.trim());
  const owners = noteChapters(tripData, skeleton.chapters);
  const byId = new Map(tripData.photos.map((p) => [p.id, p]));
  const slots: GvSlot[] = [];
  const title = (text: string, max: number, scored = true) =>
    titleText(text, max, language, names, false, scored, THEME);
  const named = (own: readonly Note[], max: number, base: number) => {
    const out = new Map<string, SlotCandidate>();
    for (const n of own) {
      for (const phrase of namePhrases(n.content)) {
        // Several words: a lone capitalised word is a sentence's opener or
        // an inflected name ("Утро", "Монмартру") more often than a title.
        const t = titleText(phrase, max, language, names, true, false, THEME);
        if (!t || hasVerb(t)) continue;
        const seen = out.get(t.toLowerCase());
        if (seen) seen.score += 5;
        else {
          out.set(t.toLowerCase(), {
            id: noteLineId(n.id!, t),
            text: t,
            note_id: n.id!,
            photo_id: null,
            score: base,
          });
        }
      }
    }
    return [...out.values()];
  };
  const placeCandidate = (photos: readonly Photo[], max: number) => {
    const place = placeOf(photos);
    const t = place &&
      !(language === "ru" && !/\p{Script=Cyrillic}/u.test(place)) &&
      title(place, max, false);
    return t
      ? [{
        id: `p:${hash(t)}`,
        text: t,
        note_id: null,
        photo_id: null,
        score: 30,
      }]
      : [];
  };

  // The title page.
  slots.push({
    slot: "occasion",
    kind: "occasion",
    main: null,
    chapter: null,
    max_picks: 1,
    free: true,
    fixed: false,
    candidates: topDistinct([
      // The page already shows the memory's name and place.
      ...neutral(OCCASION_LINES[language][skeleton.occasion], "o"),
    ]),
  });

  // Main pages: which notes each shows (#458). A note belongs to its
  // chapter; within it, to the uncaptioned main page of its own photo,
  // else the one whose photo is nearest when it was written. A main page
  // is a single photo, so the other photos of the chapter never compete:
  // only main pages show words (chapter pages are prints).
  const mainNotes = skeleton.mains.map(() => [] as Note[]);
  for (const n of notes) {
    const chapter = owners.get(n.id!)?.[0];
    if (chapter === undefined) continue;
    const pages = skeleton.mains.map((m, k) => ({ m, k })).filter(({ m }) =>
      m.chapter === chapter && !byId.get(m.photo_id)?.caption?.trim()
    );
    if (pages.length === 0) continue;
    const own = pages.find(({ m }) => m.photo_id === n.photo_id);
    const photos = pages.map(({ m }) => byId.get(m.photo_id)!);
    const near = own
      ? byId.get(own.m.photo_id)!
      : nearestPhoto(photos, noteTime(n)) ?? photos[0];
    mainNotes[pages.find(({ m }) => m.photo_id === near.id)!.k].push(n);
  }
  const weddingLabels = wedding ? LABELS[language].wedding : [];
  skeleton.mains.forEach((m, k) => {
    const photo = byId.get(m.photo_id)!;
    const caption = photo.caption?.trim();
    const slot = `main${k + 1}`;
    // Its label, a word or two over the photo: its place, else code's
    // neutral labels (the director may name the moment). A note's phrase
    // is too often half a name in Russian ("На Эйфелеву"), and a caption
    // already plays as the page's note.
    slots.push({
      slot: `${slot}.label`,
      kind: "label",
      main: k,
      chapter: m.chapter,
      max_picks: 1,
      free: true,
      fixed: false,
      candidates: topDistinct([
        ...placeCandidate([photo], MAX_GV_LABEL_CHARS),
        ...neutral([...weddingLabels, ...LABELS[language].other], "l"),
      ]),
    });
    // Its note: the caption as written, else its own notes' lines.
    let candidates: SlotCandidate[];
    if (caption) {
      candidates = [{
        id: `c:${photo.id}`,
        text: caption,
        note_id: null,
        photo_id: photo.id,
        score: 100,
      }];
    } else {
      const lines = mainNotes[k].flatMap((n) => linesOf(n, THEME))
        .filter((l) => [...l.text].length <= MAX_GV_HERO_LINE_CHARS);
      const other = lines.some((l) => l.tier !== "generic");
      candidates = topDistinct(
        lines.filter((l) => !other || l.tier !== "generic").map((l) => ({
          id: noteLineId(l.note.id!, l.text),
          text: l.text,
          note_id: l.note.id!,
          photo_id: photo.id,
          score: l.score + TIER_BONUS[l.tier],
        })),
      );
    }
    slots.push({
      slot: `${slot}.note`,
      kind: "note",
      main: k,
      chapter: m.chapter,
      max_picks: 1,
      free: false,
      fixed: !!caption,
      candidates,
    });
  });

  // Chapter titles: they name the chapter.
  skeleton.chapters.forEach((c, i) => {
    const own = notes.filter((n) => owners.get(n.id!)?.[0] === i);
    slots.push({
      slot: `ch${i + 1}.title`,
      kind: "title",
      main: null,
      chapter: i,
      max_picks: 1,
      free: true,
      fixed: false,
      candidates: topDistinct([
        ...placeCandidate(c.photos, MAX_GV_TITLE_CHARS),
        // Below the captions: a phrase of a note can stop mid-name
        // ("На Эйфелеву").
        ...named(own, MAX_GV_TITLE_CHARS, 15),
        ...c.photos.flatMap((p) => {
          const t = p.caption && title(p.caption, MAX_GV_TITLE_CHARS);
          return t && !hasVerb(t)
            ? [{
              id: `c:${p.id}`,
              text: t,
              note_id: null,
              photo_id: p.id,
              score: 20 + excerptScore(t, THEME),
            }]
            : [];
        }),
      ]),
    });
  });

  if (skeleton.carousel.length > 0) {
    slots.push({
      slot: "carousel.title",
      kind: "carousel",
      main: null,
      chapter: null,
      max_picks: 1,
      free: true,
      fixed: false,
      candidates: topDistinct([
        ...placeCandidate(
          skeleton.carousel.map((id) => byId.get(id)!),
          MAX_GV_TITLE_CHARS,
        ),
        ...neutral(
          [
            ...(wedding ? CAROUSEL[language].wedding : []),
            ...CAROUSEL[language].other,
          ],
          "k",
        ),
      ]),
    });
  }

  // The finale: the user's upbeat words for the end, else code's.
  const upbeat = shortClauses(
    notes.flatMap((n) => linesOf(n, THEME)),
    MAX_GV_END_CHARS,
    language,
    names,
    THEME,
  ).filter((c) => !isNegative(c.text) && !isGeneric(c.text));
  slots.push({
    slot: "finale",
    kind: "finale",
    main: null,
    chapter: null,
    max_picks: 1,
    free: true,
    fixed: false,
    candidates: topDistinct([
      ...upbeat.map((c) => ({ ...c, id: `f:${hash(c.text.toLowerCase())}` })),
      ...neutral(
        [
          ...(wedding ? FINALE[language].wedding : []),
          ...FINALE[language].other,
        ],
        "e",
      ),
    ]).slice(0, MAX_SLOT_CANDIDATES),
  });
  return slots;
}

export interface GvSlotResult {
  slot: string;
  kind: GvSlotKind;
  chosen: SlotChosen[];
  source: "director" | "code" | "none";
  reason: string;
}

export interface GvResolveOptions {
  language: "ru" | "en";
  names: ReadonlySet<string>;
  // Chapter [i]'s title when nothing fits: "День N".
  dayTitle: (chapter: number) => string;
  // Words the album shows anyway: the memory's name and place on the
  // title page.
  shown: readonly string[];
}

// Picks in the order slots are resolved: the notes (the user's lines)
// first, so a title never takes a line's words; then the title page and
// the chapters' titles, the labels, the carousel, the finale last.
const ORDER: GvSlotKind[] = [
  "note",
  "occasion",
  "title",
  "label",
  "carousel",
  "finale",
];

const MAX_FREE: Record<GvSlotKind, number> = {
  note: 0,
  label: MAX_GV_LABEL_CHARS,
  title: MAX_GV_TITLE_CHARS,
  carousel: MAX_GV_TITLE_CHARS,
  occasion: MAX_GV_OCCASION_CHARS,
  finale: MAX_GV_END_CHARS,
};

// Each slot's words (#458): the director's picks from the slot's own list
// that show nothing the album already shows, else the top candidate.
export function resolveGvSlots(
  slots: readonly GvSlot[],
  picks: SlotPicks | null,
  options: GvResolveOptions,
): Map<string, GvSlotResult> {
  const lines: string[] = [];
  const titles: string[] = options.shown.filter((t) => t.trim());
  const results = new Map<string, GvSlotResult>();
  // Captions first: they always play, so no other slot takes their words.
  const rank = (x: GvSlot) => ORDER.indexOf(x.kind) * 2 + (x.fixed ? 0 : 1);
  const ordered = [...slots].sort((a, b) => rank(a) - rank(b));
  for (const slot of ordered) {
    const isLine = slot.kind === "note";
    // The finale may name what a title names; only the same whole words
    // are a repeat.
    const free = (text: string) =>
      isLine
        ? !lines.some((l) => sameLine(l, text))
        : !titles.some((t) =>
          slot.kind === "finale"
            ? t.toLowerCase() === text.toLowerCase()
            : sameLine(t, text)
        ) && !lines.some((l) => sameLine(l, text) || repeatsTitle(l, text));
    const pick = slot.fixed ? undefined : picks?.[slot.slot];
    const picked = choose(slot, pick, {
      freeText: slot.free
        ? (text) =>
          freeTextProblem(
            text,
            options,
            MAX_FREE[slot.kind],
            slot.kind === "finale" || slot.kind === "occasion",
          ) ?? (free(text) ? null : "repeats words the album shows")
        : null,
      // A caption always plays, as written (#458): never trimmed.
      fits: (chosen, c) =>
        !slot.fixed && !free(c.text)
          ? "shows words the album already shows"
          : chosen.some((x) => sameLine(x.text, c.text))
          ? "repeats another pick"
          : null,
    });
    let { source } = picked;
    const { chosen, problems } = picked;
    if (chosen.length === 0 && slot.kind === "title") {
      chosen.push({
        id: "day",
        text: options.dayTitle(slot.chapter!),
        note_id: null,
        photo_id: null,
        score: 0,
      });
      source = "code";
    }
    for (const c of chosen) (isLine ? lines : titles).push(c.text);
    const reason = slot.fixed
      ? "the photo's caption, as written"
      : source === "director"
      ? problems.length > 0
        ? `director's pick; dropped ${problems.join("; ")}`
        : "director's pick"
      : source === "none"
      ? slot.candidates.length === 0
        ? "no candidates"
        : "every candidate shows words the album already shows"
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
      source: slot.fixed ? "code" : source,
      reason,
    });
  }
  return results;
}

// The notes on no main page's list, and why (#458).
export function gvUnlistedNotes(
  tripData: TripData,
  skeleton: GvSkeleton,
  slots: readonly GvSlot[],
): { note_id: string; text: string; reason: string }[] {
  const listed = new Set(
    slots.flatMap((s) => s.candidates.map((c) => c.note_id)),
  );
  const owners = noteChapters(tripData, skeleton.chapters);
  const byId = new Map(tripData.photos.map((p) => [p.id, p]));
  return tripData.notes.filter((n) =>
    n.id && n.content.trim() && !listed.has(n.id)
  ).map((n) => {
    const chapter = owners.get(n.id!)?.[0];
    const reason = chapter === undefined
      ? "on no chapter (no photos on its day)"
      : !skeleton.mains.some((m) =>
          m.chapter === chapter && !byId.get(m.photo_id)?.caption?.trim()
        )
      ? "its chapter's main pages all show their captions"
      : linesOf(n, THEME).length === 0
      ? "no line left after the drug filter"
      : linesOf(n, THEME).every((l) => l.tier === "generic")
      ? "only generic lines, and its page has a specific one"
      : `no line fits a main page (≤ ${MAX_GV_HERO_LINE_CHARS} chars)`;
    return { note_id: n.id!, text: n.content, reason };
  });
}

// --- The director's call ----------------------------------------------------

export const pickGoldenVowsLinesTool: ToolDefinition = {
  name: "pick_golden_vows_lines",
  description:
    "Pick the words of this memory's Golden Vows album: for every slot, candidate ids from that slot's list.",
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
                "Only for slots with free: true — your own words, whenever they are better than the candidates, at most the slot's max_chars, in the notes' language. Otherwise null.",
            },
          },
          required: ["slot", "ids", "free_title"],
        },
      },
    },
    required: ["picks"],
  },
};

export function buildGvPickSystemPrompt(
  language: "ru" | "en",
  occasion: GvOccasion,
): string {
  const wedding = WEDDING_OCCASIONS.includes(occasion);
  return [
    "You choose the words of a Golden Vows film — an elegant ivory-and-",
    "gold album — made from one couple's memory. The album is already ",
    "cut: its pages, their photos and its length are fixed. Each slot ",
    "lists candidate lines, mostly the person's own words, with ids. Emit ",
    "your choice with the pick_golden_vows_lines tool, one entry per ",
    "slot.\n\n",
    "Rules:\n",
    '- Every id begins with its slot\'s name ("main2.note/n:…") and is ',
    "valid only in that slot: pick only ids from the slot's own list, ",
    "exactly as listed. Never invent an id or change a line.\n",
    "- Choose what best tells this couple's story, in this order: ",
    "feelings; the two of them and their special moments; specific ",
    "details (places, food, firsts). A generic line only when nothing ",
    "else is there.\n",
    "- Never the same words twice in the album.\n",
    "- mainK.note: the note on main page K — the best of its own lines.\n",
    "- mainK.label: a few words naming what the photo shows.\n",
    "- chN.title: names the chapter — a place, event or moment — never ",
    "half a sentence.\n",
    "- occasion: the title page's line; finale: the line under the heart ",
    "as the album closes, warm and simple.\n",
    "- free_title (slots with free: true): write it whenever your words ",
    "are better than the candidates — at most the slot's max_chars, in ",
    "the notes' language, from the memory's facts only; never a clock ",
    'time or "Day N"; never invent facts.\n',
    wedding
      ? "- This memory is a wedding or engagement: wedding words are fine.\n"
      : "- This memory is romantic, not a wedding: never use vows, wedding, " +
        "marriage, bride or groom words (any language).\n",
    `- The notes' language: ${language === "ru" ? "Russian" : "English"}.`,
  ].join("");
}

// What the director sees (#458): the memory's facts, the cut album and
// every slot with its candidates.
export function buildGvPickInput(
  tripData: TripData,
  skeleton: GvSkeleton,
  slots: readonly GvSlot[],
  analyses: ReadonlyMap<string, { summary: string; hero_score: number }>,
  clock: (iso: string | null) => string | null,
) {
  const { trip } = tripData;
  const byId = new Map(tripData.photos.map((p) => [p.id, p]));
  return {
    memory: {
      name: trip.name,
      destination: trip.destination,
      start_date: trip.start_date,
      end_date: trip.end_date,
      vibes: trip.vibes,
      occasion: skeleton.occasion,
    },
    notes_language: writtenLanguage(tripData),
    notes: tripData.notes.filter((n) => n.id && n.content.trim()).map((n) => ({
      note_id: n.id,
      written_at: clock(n.legacy ? null : n.taken_at ?? n.created_at ?? null),
      photo_id: n.photo_id ?? null,
      text: n.content,
    })),
    main_pages: skeleton.mains.map((m, k) => {
      const p = byId.get(m.photo_id)!;
      return {
        page: `main${k + 1}`,
        chapter: m.chapter + 1,
        photo_id: p.id,
        time: clock(p.taken_at ?? p.created_at),
        summary: analyses.get(p.id)?.summary ?? null,
        caption: p.caption?.trim() || null,
      };
    }),
    chapters: skeleton.chapters.map((c, i) => ({
      chapter: i + 1,
      days: c.days,
      places: [
        ...new Set(c.photos.map((p) => p.place_text?.trim()).filter(Boolean)),
      ],
      prints: c.prints.map((id) => ({
        photo_id: id,
        summary: analyses.get(id)?.summary ?? null,
      })),
    })),
    slots: slots.filter((s) => !s.fixed).map((s) => ({
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
