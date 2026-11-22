// Neon Night's words, picked from code's candidates (#454).
//
// 1. Skeleton (code, no AI): chapters by logical day and part of a day
//    (nnChapterStarts, a single night by its long breaks), each
//    chapter's photos dealt to its card and 1–2 moments (dealChapter),
//    trimmed to the film's length by neon_film.ts.
// 2. Slots and candidates (code): each chapter's title, card line and
//    moment words, the Note scene and the headline, each with up to
//    MAX_NN_CANDIDATES candidates — the user's own words, already
//    filtered (no explicit drug words, length-fit, a generic line only
//    when the chapter has nothing specific), each with a stable id.
// 3. The director picks ids (pick_neon_lines). A title may be written
//    free when no candidate fits.
// 4. Validation is "is this id in this slot's list" (and no text twice in
//    the film); anything else takes the slot's top-scored free candidate.
//
// Nothing here rewrites, snaps or moves the director's words: a pick is
// taken as it is or replaced by code's.

import type { TripData } from "./gather.ts";
import type { ToolDefinition } from "./anthropic_tool.ts";
import type { WrapUpLanguage } from "./language.ts";
import { tripLogicalDays } from "./logical_day.ts";
import {
  excerptScore,
  isDrugReference,
  isGeneric,
  isSensitive,
  MAX_EXCERPT_CHARS,
  sentencesOf,
} from "./excerpts.ts";
import {
  nnBeatsFor,
  nnFitsZoom,
  nnMomentBeats,
  nnZoomHold,
} from "./film_length.ts";
import {
  type ContentMoment,
  dealChapter,
  filmPhotos,
  MAX_NN_CARD_NOTE_CHARS,
  MAX_NN_HEADLINE_CHARS,
  MAX_NN_MOMENT_WORDS,
  MAX_NN_NOTE_CHARS,
  MAX_NN_SCENE_SECONDS,
  MAX_NN_TITLE_CHARS,
  momentFor,
  nnChapterStarts,
  nnCheckContext,
  nnPhotos,
  overlaps,
  repeatsTitle,
  sameLine,
  singleNightStarts,
} from "./neon_night.ts";

import {
  CAPTION_BONUS,
  choose,
  FIRST_NAMES,
  freeTextProblem,
  hash,
  hasVerb,
  inOtherLanguage,
  isNegative,
  type Line,
  linesOf as linesOfTheme,
  MAX_SLOT_CANDIDATES,
  namePhrases,
  namesOf,
  nearestPhoto,
  norm,
  noteChapters,
  noteLineId,
  noteScene,
  noteTime,
  parsePicks,
  placeOf,
  scopedId,
  shortClauses as shortClausesOfTheme,
  type SlotCandidate,
  type SlotChosen,
  type SlotPick,
  type SlotPicks,
  TIER_BONUS,
  titleText as titleTextOfTheme,
  top,
  writtenLanguage,
} from "./film_slots.ts";

export { hasVerb, inOtherLanguage, isNegative, namePhrases, namesOf };
export { noteChapters, writtenLanguage };
export { scopedId };

type Photo = TripData["photos"][number];
type Note = TripData["notes"][number];

// Candidates a slot lists at most: the top-scored.
export const MAX_NN_CANDIDATES = MAX_SLOT_CANDIDATES;

// The theme Neon Night's lines are scored for.
const THEME = "night" as const;

// The shared helpers in Neon's theme.
const linesOf = (note: Note) => linesOfTheme(note, THEME);
function titleText(
  text: string,
  max: number,
  language: "ru" | "en" | null,
  names: ReadonlySet<string>,
  needsSpace: boolean,
  scored = true,
): string | null {
  return titleTextOfTheme(
    text,
    max,
    language,
    names,
    needsSpace,
    scored,
    THEME,
  );
}
const shortClauses = (
  lines: Parameters<typeof shortClausesOfTheme>[0],
  max: number,
  language: "ru" | "en" | null,
  names: ReadonlySet<string>,
) => shortClausesOfTheme(lines, max, language, names, THEME);

// --- The skeleton ---------------------------------------------------------

// How much the film shows (neon_film.ts trims it to the film's length).
export interface NnShape {
  // Words a moment shows at most.
  maxWords: number;
  // Zooms per card.
  cardZooms: number;
  showsPlan: boolean;
  // Chapters, from the last, whose two moments play as one.
  merged: number;
  // The last resort for a film still over its length (#454): a card
  // types a line of at most MIN_NN_SHORT_CARD_CHARS from its list when
  // that line is as good as its own (#450: never "едем в аэропорт" for
  // "Брюссель не меняется…") — a card never loses its line.
  shortCards: boolean;
  // Past that (#456): how many moments, the last chapter's first, show
  // no note line — only their best caption, if they have one.
  quietMoments: number;
}

export const MIN_NN_SHORT_CARD_CHARS = 30;

// A name or highlight's score as a headline: above an ordinary piece of
// a line, below the most specific ones.
const HIGHLIGHT_SCORE = 6;

export function fullShape(showsPlan: boolean): NnShape {
  return {
    maxWords: MAX_NN_MOMENT_WORDS,
    cardZooms: 2,
    showsPlan,
    merged: 0,
    shortCards: false,
    quietMoments: 0,
  };
}

export interface NnSkeletonChapter {
  // Its shown photos, in time order.
  photos: Photo[];
  card: string[];
  moments: ContentMoment[];
  // Its logical days, 'YYYY-MM-DD'.
  days: string[];
}

// The film's chapters with every scene's photos (#454 step 1): one per
// logical day and part of a day (a single night: its long breaks), each
// dealt in time order — its card, then 1–2 moments.
export function buildNeonSkeleton(
  tripData: TripData,
  heroScores: Readonly<Record<string, number>>,
  shape: NnShape,
): NnSkeletonChapter[] {
  const all = nnPhotos(tripData);
  const film = filmPhotos(
    all,
    new Set(all.filter((p) => p.use_in_wrap_up === true).map((p) => p.id)),
  );
  const shown = new Set(film.map((p) => p.id));
  const context = nnCheckContext(tripData);
  const required = nnChapterStarts(context);
  const starts = required.length > 0
    ? required
    : singleNightStarts(context, all.map((p) => p.id));
  const days = tripLogicalDays(tripData);
  const chapters: NnSkeletonChapter[] = [];
  starts.forEach((start, i) => {
    const photos = all.slice(start, starts[i + 1] ?? all.length).filter((p) =>
      shown.has(p.id)
    );
    if (photos.length === 0) return;
    const chapter: NnSkeletonChapter = {
      photos,
      card: [],
      moments: [],
      days: [
        ...new Set(
          photos.map((p) => days.get(p.id) ?? p.day_date).filter((
            d,
          ): d is string => !!d),
        ),
      ].sort(),
    };
    dealChapter(chapter, null, heroScores);
    chapters.push(chapter);
  });
  // For the film's length: a chapter's two moments play as one, the last
  // chapter first.
  let merges = shape.merged;
  for (let i = chapters.length - 1; i >= 0 && merges > 0; i--) {
    const c = chapters[i];
    if (c.moments.length < 2) continue;
    const ids = new Set(c.moments.flatMap((m) => m.photo_ids));
    c.moments = [momentFor(c.photos.filter((p) => ids.has(p.id)), heroScores)];
    merges--;
  }
  return chapters;
}

// The card photos whose captions its zooms show (#446), as the app picks
// them (NeonZoomPicks.best, film_length.ts nnZoomCardBeats): captions a
// zoom can show first, then hero score, then the longer hold.
export function zoomedCaptions(
  card: readonly string[],
  byId: ReadonlyMap<string, Photo>,
  heroScores: Readonly<Record<string, number>>,
  zooms: number,
): string[] {
  return card.slice(0, 6).map((id) => {
    const caption = byId.get(id)?.caption?.trim() || null;
    return {
      caption,
      fits: !!caption && nnFitsZoom(caption),
      hero: heroScores[id] ?? 0,
      hold: nnZoomHold(caption),
    };
  }).sort((a, b) =>
    Number(b.fits) - Number(a.fits) || b.hero - a.hero || b.hold - a.hold
  ).slice(0, zooms).filter((z) => z.fits).map((z) => z.caption!);
}

// --- Slots and their candidates -------------------------------------------

export type NnSlotKind = "note" | "card" | "moment" | "title" | "headline";

export type NnCandidate = SlotCandidate;

export interface NnSlot {
  // "note", "headline", "ch1.title", "ch1.card", "ch1.m1", …
  slot: string;
  kind: NnSlotKind;
  // 0-based; null for the Note scene and the headline.
  chapter: number | null;
  moment: number | null;
  // How many ids the director may pick: a moment's words, else 1.
  max_picks: number;
  candidates: NnCandidate[];
}

// Every slot of the film with its candidates (#454 step 2).
export function buildNeonSlots(
  tripData: TripData,
  chapters: readonly NnSkeletonChapter[],
  shape: NnShape,
): NnSlot[] {
  const language = writtenLanguage(tripData);
  const names = namesOf(tripData);
  const owners = noteChapters(tripData, chapters);
  const notes = tripData.notes.filter((n) => n.id && n.content.trim());
  const filmIds = new Set(chapters.flatMap((c) => c.photos.map((p) => p.id)));
  const slots: NnSlot[] = [];

  // The Note scene: the film's most heartfelt line, nothing sensitive.
  const allLines = notes.flatMap(linesOf);
  const noteLines = allLines.filter((l) =>
    [...l.text].length <= MAX_NN_NOTE_CHARS && !isSensitive(l.text)
  );
  const anyOther = noteLines.some((l) => l.tier !== "generic");
  slots.push({
    slot: "note",
    kind: "note",
    chapter: null,
    moment: null,
    max_picks: 1,
    candidates: top(
      noteLines.filter((l) => !anyOther || l.tier !== "generic").map((
        l,
      ) => ({
        id: noteLineId(l.note.id!, l.text),
        text: l.text,
        note_id: l.note.id!,
        photo_id: l.note.photo_id && filmIds.has(l.note.photo_id)
          ? l.note.photo_id
          : null,
        score: l.score + TIER_BONUS[l.tier],
      })),
    ),
  });

  chapters.forEach((chapter, i) => {
    const ch = `ch${i + 1}`;
    const own = notes.filter((n) => owners.get(n.id!)?.includes(i));
    const lines = own.flatMap(linesOf);
    // A generic line only when the chapter has nothing else.
    const other = lines.some((l) => l.tier !== "generic");
    const usable = lines.filter((l) => !other || l.tier !== "generic");
    // Which scene each note belongs to (#456, a hard filter): its photo's
    // scene, else the one whose photos it was written among — the largest
    // share of the scene's photos within SCENE_NEAR_MINUTES of it, then
    // the nearest photo; the card on a tie or without a time. A scene
    // lists only its own notes' lines, so "Приземлились в Амстердаме…"
    // (12:00) plays over the Amsterdam photos (12:19–14:33), never over
    // the airport card (08:40–12:10). A scene left without one shows none.
    const scenes = [
      chapter.photos.filter((p) => chapter.card.includes(p.id)),
      ...chapter.moments.map((m) =>
        chapter.photos.filter((p) => m.photo_ids.includes(p.id))
      ),
    ];
    const sceneOf = (n: Note): number => noteScene(scenes, n) - 1;
    const sceneNotes = new Map(own.map((n) => [n.id!, sceneOf(n)]));

    // The card line: a sentence or piece short enough for a card, of the
    // card's own notes.
    const cardNotes = own.filter((n) => sceneNotes.get(n.id!) === -1);
    const cardOf = (l: Line): NnCandidate => ({
      id: noteLineId(l.note.id!, l.text),
      text: l.text,
      note_id: l.note.id!,
      photo_id: chapter.card.includes(l.note.photo_id ?? "")
        ? l.note.photo_id!
        : nearestPhoto(scenes[0], noteTime(l.note))?.id ?? null,
      score: Math.round(l.score + TIER_BONUS[l.tier]),
    });
    const fitsCard = (l: Line) => [...l.text].length <= MAX_NN_CARD_NOTE_CHARS;
    const card = usable.filter((l) =>
      sceneNotes.get(l.note.id!) === -1 && fitsCard(l)
    ).map(cardOf);
    // Every note of the card on its list (#454): its best line that fits
    // — a generic one only when it has nothing else.
    const kept = cardNotes.flatMap((n) => {
      const fit = lines.filter((l) => l.note === n && fitsCard(l))
        .map(cardOf).sort((a, b) => b.score - a.score);
      return fit.length > 0 ? [fit[0]] : [];
    });
    slots.push({
      slot: `${ch}.card`,
      kind: "card",
      chapter: i,
      moment: null,
      max_picks: 1,
      candidates: top(card, kept),
    });

    // Each moment's words: its own notes' lines, each over its note's
    // photo, else the moment photo nearest in time — and its photos'
    // captions.
    const momentPhotos = scenes.slice(1);
    const words: NnCandidate[][] = chapter.moments.map(() => []);
    for (const l of usable) {
      const j = sceneNotes.get(l.note.id!) ?? -1;
      if (j < 0) continue;
      const photo = momentPhotos[j].find((p) => p.id === l.note.photo_id) ??
        nearestPhoto(momentPhotos[j], noteTime(l.note));
      if (!photo) continue;
      if ([...l.text].length > MAX_EXCERPT_CHARS) continue;
      const m = chapter.moments[j];
      const beats = nnMomentBeats({
        type: m.type,
        photos: m.photo_ids.length,
        lines: [l.text],
      });
      if (beats > nnBeatsFor(MAX_NN_SCENE_SECONDS)) continue;
      words[j].push({
        id: noteLineId(l.note.id!, l.text),
        text: l.text,
        note_id: l.note.id!,
        photo_id: photo.id,
        score: l.score + TIER_BONUS[l.tier],
      });
    }
    chapter.moments.forEach((_m, j) => {
      for (const p of momentPhotos[j]) {
        const caption = p.caption?.trim();
        if (!caption) continue;
        words[j].push({
          id: `c:${p.id}`,
          text: caption,
          note_id: null,
          photo_id: p.id,
          score: CAPTION_BONUS + Math.max(0, excerptScore(caption, THEME)) +
            (p.use_in_wrap_up === true ? 10 : 0),
        });
      }
      slots.push({
        slot: `${ch}.m${j + 1}`,
        kind: "moment",
        chapter: i,
        moment: j,
        max_picks: shape.maxWords,
        candidates: top(words[j]),
      });
    });

    // The title names the chapter (#454): its place (in the user's
    // language), the names in its notes — places, events, people — and
    // its short captions that name something. Never a piece of a
    // sentence ("сразу пошли завтракать").
    const titles: NnCandidate[] = [];
    const place = placeOf(chapter.photos);
    // In the notes' script only: over Russian notes "amsterdam" isn't a
    // title, even though the memory's name says it.
    const placeTitle = place &&
      !(language === "ru" && !/\p{Script=Cyrillic}/u.test(place)) &&
      titleText(place, MAX_NN_TITLE_CHARS, language, names, false);
    if (placeTitle) {
      titles.push({
        id: `p:${hash(placeTitle)}`,
        text: placeTitle,
        note_id: null,
        photo_id: null,
        score: 30,
      });
    }
    const named = new Map<string, { note: Note; count: number }>();
    for (const n of own) {
      if (isDrugReference(n.content)) continue;
      for (const phrase of namePhrases(n.content)) {
        const t = titleText(phrase, MAX_NN_TITLE_CHARS, language, names, false);
        if (!t) continue;
        const seen = named.get(norm(t));
        if (seen) seen.count++;
        else named.set(norm(t), { note: n, count: 1 });
      }
    }
    for (const [key, { note, count }] of named) {
      const text = namePhrases(note.content).map((x) =>
        titleText(x, MAX_NN_TITLE_CHARS, language, names, false)
      ).find((x) => x && norm(x) === key)!;
      titles.push({
        id: noteLineId(note.id!, text),
        text,
        note_id: note.id!,
        photo_id: null,
        score: 25 + 5 * (count - 1),
      });
    }
    for (const p of chapter.photos) {
      const t = p.caption &&
        titleText(p.caption, MAX_NN_TITLE_CHARS, language, names, false);
      if (!t || hasVerb(t)) continue;
      titles.push({
        id: `c:${p.id}`,
        text: t,
        note_id: null,
        photo_id: p.id,
        score: 10 + excerptScore(t, THEME),
      });
    }
    slots.push({
      slot: `${ch}.title`,
      kind: "title",
      chapter: i,
      moment: null,
      max_picks: 1,
      candidates: top(titles),
    });
  });

  // The headline: a few upbeat words for the film's peak (#454) — the
  // names and highlights of the memory (its events, places: "Куко
  // Unreal", "AMF", "ADE"), the short pieces of its lines, its short
  // captions — listed on their own (h: ids), never a title's or a line's
  // id; never a complaint ("диджеи не очень").
  const highlightOf = (text: string) =>
    titleText(text, MAX_NN_HEADLINE_CHARS, language, names, false);
  // The memory's name is the user's own words too ("ADE-Amsterdam 2026":
  // "ADE", "Amsterdam").
  const tripWords = tripData.trip.name.split(/[-–—/]+/u);
  const highlights = [
    ...tripWords,
    ...notes.filter((n) => !isDrugReference(n.content)).map((n) => n.content),
  ].flatMap((t) => namePhrases(t, true)).flatMap((t) => {
    const h = titleText(
      t,
      MAX_NN_HEADLINE_CHARS,
      language,
      names,
      false,
      false,
    );
    // Over Russian notes a Latin word alone only as an acronym ("ADE",
    // "AMF"), never "Amsterdam".
    const latinWord = language === "ru" &&
      /^\p{Script=Latin}+$/u.test(h ?? "");
    return h && !hasVerb(h) && !/^\d+$/u.test(h) &&
        (!latinWord || /^\p{Lu}{2,5}$/u.test(h)) &&
        // A first name alone is no headline ("Петр").
        !FIRST_NAMES.has(norm(h))
      ? [{ text: h, score: HIGHLIGHT_SCORE }]
      : [];
  }).filter((x, _i, all) =>
    // "Куко" inside "Куко Unreal": the fuller name.
    !all.some((y) =>
      y.text !== x.text && ` ${norm(y.text)} `.includes(` ${norm(x.text)} `)
    )
  );
  const headline = [
    ...highlights,
    ...shortClauses(allLines, MAX_NN_HEADLINE_CHARS, language, names),
    ...chapters.flatMap((c) => c.photos).flatMap((p) => {
      const t = p.caption && highlightOf(p.caption);
      return t && !isGeneric(t)
        ? [{ text: t, score: excerptScore(t, THEME) }]
        : [];
    }),
  ].filter((c) => !isNegative(c.text)).map((c) => ({
    id: `h:${hash(norm(c.text))}`,
    text: c.text,
    note_id: null,
    photo_id: null,
    score: c.score,
  }));
  slots.push({
    slot: "headline",
    kind: "headline",
    chapter: null,
    moment: null,
    max_picks: 1,
    candidates: top(headline),
  });
  return slots;
}

// The notes on no slot's list, and why (#454): every note without an
// explicit drug word should be on one.
export function unlistedNotes(
  tripData: TripData,
  chapters: readonly NnSkeletonChapter[],
  slots: readonly NnSlot[],
): { note_id: string; text: string; reason: string }[] {
  const listed = new Set(
    slots.flatMap((s) => s.candidates.map((c) => c.note_id)),
  );
  const owners = noteChapters(tripData, chapters);
  return tripData.notes.filter((n) =>
    n.id && n.content.trim() && !listed.has(n.id)
  ).map((n) => {
    const sentences = sentencesOf(n.content);
    const reason = sentences.every(isDrugReference)
      ? "explicit drug words in every sentence"
      : !owners.has(n.id!)
      ? "on no chapter (no photos on its day)"
      : linesOf(n).length === 0
      ? "no line left after the drug filter"
      : `no line fits a slot (card ≤ ${MAX_NN_CARD_NOTE_CHARS}, Note ≤ ${MAX_NN_NOTE_CHARS} chars)`;
    return { note_id: n.id!, text: n.content, reason };
  });
}

// --- The director's picks and their validation ----------------------------

export type NnPick = SlotPick;
export type NnPicks = SlotPicks;

// What the director record stores (#454): its picks by slot.
export interface NeonNightPicksRecord {
  picks_version: 2;
  picks: NnPicks;
}

export function isPicksRecord(value: unknown): value is NeonNightPicksRecord {
  return typeof value === "object" && value !== null &&
    (value as Record<string, unknown>).picks_version === 2 &&
    typeof (value as Record<string, unknown>).picks === "object";
}

export type NnChosen = SlotChosen;

export interface NnSlotResult {
  slot: string;
  kind: NnSlotKind;
  chosen: NnChosen[];
  // director: the director's pick; code: the top free candidate (or, for
  // a title, "Day N"); none: nothing to show.
  source: "director" | "code" | "none";
  reason: string;
}

// Picks in the order slots are resolved: the Note scene and the lines
// first, then the titles, then the headline — so a title never takes a
// line's words, and the headline never a title's.
const ORDER: NnSlotKind[] = ["note", "card", "moment", "title", "headline"];

export interface ResolveOptions {
  // Captions the film already shows (card zooms): no line repeats one.
  shownCaptions: readonly string[];
  language: "ru" | "en" | null;
  names: ReadonlySet<string>;
  // The moments' scenes, for the words' reading time.
  moments: ReadonlyMap<string, ContentMoment>;
  // A chapter's title when nothing fits: "Day N" in the user's language.
  dayTitle: (chapter: number) => string;
  // A film still over its length: short card lines as good as the pick,
  // and a moment's line gives way to a shorter one of its note.
  shortCards?: boolean;
  // Still over (#456): the moments (slot names) that show no note line.
  quietMoments?: ReadonlySet<string>;
  // How good a photo's caption is to keep (#456): Always picks, then the
  // hero score. Higher is better.
  captionRank?: (photoId: string) => number;
}

// Each slot's words (#454 step 4): the director's picks that are in the
// slot's list and show nothing the film already shows, else the
// top-scored candidates that don't.
export function resolveNeonSlots(
  slots: readonly NnSlot[],
  picks: NnPicks | null,
  options: ResolveOptions,
): Map<string, NnSlotResult> {
  // Lines (the Note scene, cards, moments' note lines) and the captions
  // shown; titles and the headline.
  const lines: string[] = [];
  const captions: string[] = [...options.shownCaptions];
  const titles: string[] = [];
  const lineFree = (text: string) =>
    !lines.some((l) => overlaps(l, text)) &&
    !captions.some((c) => overlaps(c, text));
  // A title never repeats a line or a caption the film shows (#454).
  // A title never repeats another title, a line or a caption. The
  // headline may share a name with a title ("Куко Unreal" under "На Куко
  // Unreal"); only the same whole words twice are a repeat.
  const sameWords = (a: string, b: string) => norm(a) === norm(b);
  const titleFree = (text: string, headline = false) =>
    !titles.some((t) => headline ? sameWords(t, text) : sameLine(t, text)) &&
    ![...lines, ...captions].some((l) =>
      sameLine(l, text) || repeatsTitle(l, text)
    );

  const results = new Map<string, NnSlotResult>();
  const ordered = [...slots].sort((a, b) =>
    ORDER.indexOf(a.kind) - ORDER.indexOf(b.kind)
  );
  for (const slot of ordered) {
    const isTitle = slot.kind === "title" || slot.kind === "headline";
    const free = (text: string) =>
      isTitle ? titleFree(text, slot.kind === "headline") : lineFree(text);
    const moment = options.moments.get(slot.slot);
    const fits = (
      chosen: readonly NnChosen[],
      c: NnCandidate,
    ): string | null => {
      if (!free(c.text)) return "shows words the film already shows";
      if (chosen.some((x) => overlaps(x.text, c.text))) {
        return "repeats another pick";
      }
      if (moment) {
        if (chosen.some((x) => x.photo_id === c.photo_id)) {
          return "a second word on the same photo";
        }
        const beats = nnMomentBeats({
          type: moment.type,
          photos: moment.photo_ids.length,
          lines: [...chosen.map((x) => x.text), c.text],
        });
        if (beats > nnBeatsFor(MAX_NN_SCENE_SECONDS)) {
          return "too long to read in the scene";
        }
      }
      return null;
    };
    const take = (c: NnCandidate): NnChosen => ({
      id: c.id,
      text: c.text,
      note_id: c.note_id,
      photo_id: c.photo_id,
      score: c.score,
    });

    const pick = picks?.[slot.slot];
    // A title: the director's own, when it wrote one that holds — it
    // writes one whenever it names the chapter better (#454).
    const picked = choose(slot, pick, {
      freeText: isTitle
        ? (text) =>
          freeTitleProblem(
            text,
            options,
            slot.kind === "headline" ? "headline" : "title",
          ) ?? (titleFree(text) ? null : "repeats words the film shows")
        : null,
      fits,
    });
    const chosen: NnChosen[] = picked.chosen;
    const problems = picked.problems;
    let source: NnSlotResult["source"] = picked.source;
    // Short for length (#454): only a line as good as the one picked.
    let shortened = false;
    if (
      options.shortCards && slot.kind === "card" && chosen.length === 1 &&
      [...chosen[0].text].length > MIN_NN_SHORT_CARD_CHARS
    ) {
      const picked = chosen[0];
      const shorter = slot.candidates.find((c) =>
        c.id !== picked.id &&
        [...c.text].length <= MIN_NN_SHORT_CARD_CHARS &&
        c.score >= picked.score && fits([], c) === null
      );
      if (shorter) {
        chosen[0] = take(shorter);
        source = "code";
        shortened = true;
      }
    }
    // A moment with captioned photos shows one of them (#456: the best —
    // Always, then hero score), on top of its words; its line gives way
    // to a shorter line of its note, else goes, before the caption does.
    let captioned = false;
    if (moment && options.quietMoments?.has(slot.slot)) {
      // For the film's length: no note line here (#456).
      const kept = chosen.filter((c) => c.id.startsWith("c:"));
      chosen.splice(0, chosen.length, ...kept);
    }
    if (moment) {
      const isCaption = (c: { id: string }) => c.id.startsWith("c:");
      const rank = (c: NnCandidate) =>
        options.captionRank?.(c.photo_id ?? "") ?? c.score;
      const lineOnly = chosen.filter((c) => !isCaption(c));
      const best = chosen.some(isCaption) ? null : slot.candidates
        .filter(isCaption)
        .sort((a, b) => rank(b) - rank(a))
        .find((c) =>
          free(c.text) &&
          !lineOnly.some((x) =>
            x.photo_id === c.photo_id || overlaps(x.text, c.text)
          )
        );
      const readable = (ws: { text: string }[]) =>
        nnMomentBeats({
          type: moment.type,
          photos: moment.photo_ids.length,
          lines: ws.map((w) => w.text),
        }) <= nnBeatsFor(MAX_NN_SCENE_SECONDS);
      const shorter = (line: NnChosen, cap: number) =>
        slot.candidates.filter((c) =>
          !isCaption(c) && c.note_id === line.note_id && c.id !== line.id &&
          [...c.text].length < Math.min([...line.text].length, cap + 1) &&
          (!best ||
            (c.photo_id !== best.photo_id && !overlaps(c.text, best.text))) &&
          !chosen.some((x) => x.id !== line.id && overlaps(x.text, c.text)) &&
          free(c.text)
        ).sort((a, b) => b.score - a.score)[0];
      if (best) {
        const words: NnChosen[] = [...chosen];
        while (words.length > 0 && !readable([...words, best])) {
          const last = words.pop()!;
          const short = shorter(last, Infinity);
          if (short && readable([...words, short, best])) {
            words.push(take(short));
            break;
          }
        }
        chosen.splice(0, chosen.length, ...words, take(best));
        captioned = true;
      } else if (options.shortCards && chosen.length > 0) {
        // No caption to keep: a long line takes a short one of its note.
        const last = chosen[chosen.length - 1];
        const short = !isCaption(last) &&
            [...last.text].length > MIN_NN_SHORT_CARD_CHARS
          ? shorter(last, MIN_NN_SHORT_CARD_CHARS)
          : undefined;
        if (short) chosen[chosen.length - 1] = take(short);
      }
      if (options.shortCards && best && chosen.length > 1) {
        const k = chosen.length - 2;
        const line = chosen[k];
        const short = !isCaption(line) &&
            [...line.text].length > MIN_NN_SHORT_CARD_CHARS
          ? shorter(line, MIN_NN_SHORT_CARD_CHARS)
          : undefined;
        if (short) chosen[k] = take(short);
      }
      if (chosen.length > 0 && source === "none") source = "code";
    }
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
    for (const c of chosen) {
      if (isTitle) titles.push(c.text);
      else if (c.id.startsWith("c:")) captions.push(c.text);
      else lines.push(c.text);
    }
    // Nothing plays: an empty list, or every candidate already shown.
    const empty = slot.candidates.length === 0
      ? "no candidates"
      : "every candidate shows words the film already shows";
    const reason = shortened
      ? "a shorter line as good as the pick, for the film's length"
      : captioned && source === "director" && problems.length === 0
      ? "director's pick; and its best caption (#456)"
      : source === "director"
      ? problems.length > 0
        ? `director's pick; dropped ${problems.join("; ")}`
        : "director's pick"
      : !picks
      ? source === "none" ? empty : "no director picks: top candidate"
      : !pick
      ? source === "none" ? empty : "director left it: top candidate"
      : problems.length > 0
      ? `${problems.join("; ")} → ${
        source === "none" ? "nothing left" : "top candidate"
      }`
      : source === "none"
      ? empty
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

// Why the director's own title can't be used, or null (#454): at most
// MAX_NN_TITLE_CHARS, in the user's language, nothing sensitive or
// banned, never a clock time or "Day N".
export function freeTitleProblem(
  title: string,
  options: Pick<ResolveOptions, "language" | "names">,
  kind: "title" | "headline" = "title",
): string | null {
  const max = kind === "headline" ? MAX_NN_HEADLINE_CHARS : MAX_NN_TITLE_CHARS;
  return freeTextProblem(title, options, max, kind === "headline");
}

// The director's tool input as picks, or null when it isn't that shape.
export const parseNeonPicks = parsePicks;

// --- The director's call ----------------------------------------------------

export const pickNeonLinesTool: ToolDefinition = {
  name: "pick_neon_lines",
  description:
    "Pick the words of this memory's Neon Night film: for every slot, candidate ids from that slot's list.",
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
                "Candidate ids from this slot's own list, exactly as listed (each begins with this slot's name), best first: at most max_picks. Empty for a title you write as free_title, or when no candidate fits.",
              items: { type: "string" },
            },
            free_title: {
              type: ["string", "null"],
              description:
                `Title and headline slots only: your own words, whenever they are better than the candidates — a title at most ${MAX_NN_TITLE_CHARS} characters, the headline at most ${MAX_NN_HEADLINE_CHARS}, in the notes' language. Otherwise null.`,
            },
          },
          required: ["slot", "ids", "free_title"],
        },
      },
    },
    required: ["picks"],
  },
};

export function buildNeonPickSystemPrompt(language: WrapUpLanguage): string {
  return [
    "You choose the words of a Neon Night film — a loud, beat-synced neon ",
    "party film — made from one person's memory. The film is already cut: ",
    "its chapters, every scene's photos and its length are fixed. Each ",
    "slot lists candidate lines, the person's own words, with ids. Emit ",
    "your choice with the pick_neon_lines tool, one entry per slot.\n\n",
    "Rules:\n",
    '- Every id begins with its slot\'s name ("ch2.card/n:…") and is ',
    "valid only in that slot: pick for a slot only ids from its own list, ",
    "exactly as listed — never an id from another slot's list, even for ",
    "the same words. Never invent an id or change a line.\n",
    "- Choose what best tells this person's night, in this order: ",
    "feelings and emotions; the music, the crowd, the night; specific ",
    "details (numbers, names, places, food, firsts, funny moments). A ",
    'generic summary ("it was fun", "было весело", "все устали") only ',
    "when nothing else is there.\n",
    "- Each id is used once in the whole film: an id picked for one slot ",
    "is never picked for another, even when it is listed there too. Never ",
    "the same words twice: a title never repeats the headline or a line, ",
    "and no line repeats another or a caption.\n",
    "- note: the single most heartfelt line of the whole film.\n",
    "- chN.card: the line typed on chapter N's card — its best line.\n",
    "- chN.mK: up to max_picks words shown on that moment's photos, each ",
    "on its own photo; lines over captions when both are good.\n",
    "- chN.title: a title names the chapter: a place, event or key ",
    'moment (e.g. "Амстердам", "Куко Unreal", "AMF под ливнем", ',
    '"Брюссель") — never half a sentence ("сразу пошли завтракать"). ',
    "Write free_title whenever it's better than the candidates (then ",
    `ids may be empty): at most ${MAX_NN_TITLE_CHARS} characters, in the `,
    "notes' language (a place in the notes' language, e.g. \"Брюссель\" ",
    "for Brussels over Russian notes), from the memory's facts only; ",
    'never a clock time or "Day N"; no drug words or swearing. Prefer ',
    "free_title when a candidate starts with a preposition, has a typo, ",
    "or misses the chapter's main event.\n",
    "- headline: a few loud, upbeat words for the film's peak, built on a ",
    'real detail (e.g. "Самый крутой сет", "Куко до утра") — never a ',
    "complaint or a low. Pick from the headline slot's own list, or write ",
    `free_title for it: at most ${MAX_NN_HEADLINE_CHARS} characters, in `,
    "the notes' language, from the memory's facts only.\n",
    `- The notes' language: ${
      language === "ru" ? "Russian" : "English"
    } unless the notes say otherwise.`,
  ].join("");
}

// What the director sees (#454): the memory's facts, the cut film and
// every slot with its candidates.
export function buildNeonPickInput(
  tripData: TripData,
  chapters: readonly NnSkeletonChapter[],
  slots: readonly NnSlot[],
  analyses: ReadonlyMap<string, { summary: string; hero_score: number }>,
  clock: (iso: string | null) => string | null,
) {
  const { trip } = tripData;
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
      written_at: clock(n.legacy ? null : n.taken_at ?? n.created_at ?? null),
      photo_id: n.photo_id ?? null,
      text: n.content,
    })),
    chapters: chapters.map((c, i) => ({
      chapter: i + 1,
      days: c.days,
      from: clock(c.photos[0]?.taken_at ?? c.photos[0]?.created_at ?? null),
      to: clock(
        c.photos[c.photos.length - 1]?.taken_at ??
          c.photos[c.photos.length - 1]?.created_at ?? null,
      ),
      places: [
        ...new Set(c.photos.map((p) => p.place_text?.trim()).filter(Boolean)),
      ],
      card_photo_ids: c.card,
      moments: c.moments.map((m, j) => ({
        slot: `ch${i + 1}.m${j + 1}`,
        type: m.type,
        photo_ids: m.photo_ids,
      })),
    })),
    photos: chapters.flatMap((c, i) =>
      c.photos.map((p) => ({
        photo_id: p.id,
        chapter: i + 1,
        time: clock(p.taken_at ?? p.created_at),
        summary: analyses.get(p.id)?.summary ?? null,
        caption: p.caption?.trim() || null,
        place: p.place_text ?? null,
      }))
    ),
    slots: slots.map((s) => ({
      slot: s.slot,
      max_picks: s.max_picks,
      // Every id carries its slot ("ch2.card/n:…"): valid there only.
      candidates: s.candidates.map((c) => ({
        id: scopedId(s.slot, c.id),
        text: c.text,
        ...(c.photo_id ? { photo_id: c.photo_id } : {}),
      })),
    })),
  };
}
