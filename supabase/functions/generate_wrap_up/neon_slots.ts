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
import { bannedPhraseIn, cleanAiLine } from "./film_plan.ts";
import type { WrapUpLanguage } from "./language.ts";
import { tripLogicalDays } from "./logical_day.ts";
import {
  clausesOf,
  excerptScore,
  isDrugReference,
  isGeneric,
  isSensitive,
  MAX_EXCERPT_CHARS,
  sentencesOf,
  SPECIFIC_SCORE,
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
  timeOf,
} from "./neon_night.ts";

type Photo = TripData["photos"][number];
type Note = TripData["notes"][number];

// Candidates a slot lists at most: the top-scored.
export const MAX_NN_CANDIDATES = 8;

// The theme Neon Night's lines are scored for.
const THEME = "night" as const;

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

// A note belongs to the scene whose photos it was written among (#456):
// the share of the scene's photos taken within this many minutes of it.
const CARD_NEAR_MINUTES = 90;

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

export interface NnCandidate {
  id: string;
  text: string;
  note_id: string | null;
  // The photo it plays over (a moment's word), or null.
  photo_id: string | null;
  // Higher is better; the list is sorted by it.
  score: number;
}

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

// A short, stable id for a text (FNV-1a).
function hash(text: string): string {
  let h = 0x811c9dc5;
  for (const c of text) {
    h ^= c.codePointAt(0)!;
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h.toString(36);
}

function noteLineId(noteId: string, text: string): string {
  return `n:${noteId}:${hash(text)}`;
}

function norm(text: string): string {
  return text.toLowerCase().replace(/ё/g, "е").replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();
}

// When a note was written; NaN for an old one-a-day note (its time is its
// last edit) or none.
function noteTime(n: Note): number {
  if (n.legacy) return NaN;
  return Date.parse(n.taken_at ?? n.created_at ?? "");
}

// The language the user writes in: Russian when the notes' (else the
// captions') letters are ≥ 70 % Cyrillic, English when ≥ 70 % Latin; null
// when mixed or too few to tell.
export function writtenLanguage(tripData: TripData): "ru" | "en" | null {
  for (
    const texts of [
      tripData.notes.map((n) => n.content),
      tripData.photos.map((p) => p.caption ?? ""),
    ]
  ) {
    const text = texts.join(" ");
    const cyr = (text.match(/[Ѐ-ӿ]/g) ?? []).length;
    const lat = (text.match(/[A-Za-z]/g) ?? []).length;
    if (cyr + lat < 20) continue;
    if (cyr >= 0.7 * (cyr + lat)) return "ru";
    if (lat >= 0.7 * (cyr + lat)) return "en";
    return null;
  }
  return null;
}

// The words of the user's notes: a Latin word inside Russian notes is a
// name ("Kuko", "AMF", "ufc"), never another language — captions don't
// count (#454: English captions over Russian notes are another language).
// The memory's own name is the user's words too ("ADE-Amsterdam 2026").
export function namesOf(tripData: TripData): Set<string> {
  const words = new Set<string>(
    norm(tripData.trip.name ?? "").split(" ").filter(Boolean),
  );
  for (const n of tripData.notes) {
    for (const w of norm(n.content).split(" ")) if (w) words.add(w);
  }
  return words;
}

// Whether [text] is in another language than [language] (#454), word by
// word: a word counts as the user's when it's in their script or one they
// wrote in their notes (a name: "Kuko Unreal", "AMF"); the text passes
// when at least half its words are ("Rave до утра"), fails otherwise
// ("Tallinn airport", "coffee shop" over Russian notes).
export function inOtherLanguage(
  text: string,
  language: "ru" | "en" | null,
  names: ReadonlySet<string>,
): boolean {
  if (language === null) return false;
  const words = norm(text).split(" ").filter((w) => /\p{L}/u.test(w));
  if (words.length === 0) return false;
  const own = words.filter((w) =>
    names.has(w) ||
    (language === "ru" ? /[\u0400-\u04FF]/u.test(w) : /[a-z]/u.test(w))
  ).length;
  return own * 2 < words.length;
}

// "Yesterday …": a note about the day before (#454).
const YESTERDAY = /(^|[^\p{L}])(вчера|yesterday|last night)([^\p{L}]|$)/iu;

// The day before [day], 'YYYY-MM-DD'.
function dayBefore(day: string): string {
  const d = new Date(`${day}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() - 1);
  return d.toISOString().slice(0, 10);
}

// Which chapters a note's lines belong to (#454): the chapter with its
// photo; else its logical day's — a note about yesterday ("вчера…") the
// day before's last part — and within the day the part whose time range
// is nearest to when it was written (after the day's last photo: its last
// part). The user writes later — in the evening, the next morning — so
// there is no window. An old one-a-day note (no time) belongs to every
// part of its day; a note on no chapter's day to the nearest in time.
export function noteChapters(
  tripData: TripData,
  chapters: readonly NnSkeletonChapter[],
): Map<string, number[]> {
  const days = tripLogicalDays(tripData);
  const spans = chapters.map((c) => {
    const times = c.photos.map(timeOf).filter((t) => t > 0);
    return { from: Math.min(...times), to: Math.max(...times) };
  });
  const distance = (i: number, t: number) =>
    t < spans[i].from
      ? spans[i].from - t
      : t > spans[i].to
      ? t - spans[i].to
      : 0;
  const nearest = (among: number[], t: number) => {
    let best = among[0];
    for (const i of among) if (distance(i, t) < distance(best, t)) best = i;
    return best;
  };
  const owners = new Map<string, number[]>();
  for (const n of tripData.notes) {
    if (!n.id || !n.content.trim()) continue;
    const own = chapters.findIndex((c) =>
      c.photos.some((p) => p.id === n.photo_id)
    );
    if (own >= 0) {
      owners.set(n.id, [own]);
      continue;
    }
    const written = days.get(`note:${n.id}`) ?? n.day_date;
    const onDay = (day: string) =>
      chapters.flatMap((c, i) => c.days.includes(day) ? [i] : []);
    if (YESTERDAY.test(n.content)) {
      const before = onDay(dayBefore(written));
      if (before.length > 0) {
        owners.set(n.id, [before[before.length - 1]]);
        continue;
      }
    }
    const today = onDay(written);
    const t = noteTime(n);
    if (Number.isNaN(t)) {
      if (today.length > 0) owners.set(n.id, today);
      continue;
    }
    if (today.length > 0) {
      owners.set(n.id, [nearest(today, t)]);
    } else if (chapters.length > 0) {
      owners.set(n.id, [nearest(chapters.map((_, i) => i), t)]);
    }
  }
  return owners;
}

// How good a line is (#454): specific (details, feelings — scored),
// plain (the user's words, nothing to score: "Выезжаем на AMF тусовку…"),
// generic (a summary: "было весело"). Plain lines are candidates too —
// only generic ones wait until a chapter has nothing else.
type Tier = "specific" | "plain" | "generic";

interface Line {
  note: Note;
  text: string;
  score: number;
  tier: Tier;
  // Its place in the note: lines keep the note's order on ties.
  k: number;
}

function tierOf(text: string, score: number): Tier {
  if (isGeneric(text)) return "generic";
  return score >= SPECIFIC_SCORE ? "specific" : "plain";
}

// Where a clause breaks further (#454): at a slash, or before a
// conjunction that opens a clause of its own — so a long line without
// commas still gives a card a piece ("Выезжаем на AMF тусовку за окном
// ливень" | "но мы готовы дать еще один бой").
// (Never a bare "so": "I felt so happy" is one phrase.)
const BREAKS = /\s*\/\s*|\s+(?=(?:но|а|так что|потом|зато|but|then)\s)/iu;

// A sentence's pieces: its clauses, then each clause broken at BREAKS —
// pieces of 2 words or more, the user's exact words.
function piecesOf(sentence: string): string[] {
  const clauses = clausesOf(sentence);
  const out = [...clauses];
  for (const clause of clauses) {
    const parts = clause.split(BREAKS);
    if (parts.length < 2) continue;
    for (const part of parts) {
      const t = part.trim().replace(/\s*[,;:]$/u, "");
      if (t.split(/\s+/u).length >= 2 && !out.includes(t)) out.push(t);
    }
  }
  return out;
}

// [note]'s lines: each sentence and its pieces — a long sentence only as
// pieces — and never any of a sentence with an explicit drug word (#450,
// #454: "…курят косячки, очень необычно" gives no "очень необычно"
// either).
function linesOf(note: Note): Line[] {
  const out: Line[] = [];
  const seen = new Set<string>();
  for (const sentence of sentencesOf(note.content)) {
    if (isDrugReference(sentence)) continue;
    const pieces = [
      ...([...sentence].length <= MAX_EXCERPT_CHARS ? [sentence] : []),
      ...piecesOf(sentence),
    ];
    for (const text of pieces) {
      if (seen.has(text) || [...text].length > MAX_EXCERPT_CHARS) continue;
      seen.add(text);
      const score = excerptScore(text, THEME);
      out.push({ note, text, score, tier: tierOf(text, score), k: out.length });
    }
  }
  return out;
}

function nearestPhoto(photos: readonly Photo[], t: number): Photo | null {
  if (Number.isNaN(t) || photos.length === 0) return null;
  let best = photos[0];
  for (const p of photos) {
    if (Math.abs(timeOf(p) - t) < Math.abs(timeOf(best) - t)) best = p;
  }
  return best;
}

// The top MAX_NN_CANDIDATES of [candidates] by score — always keeping
// [kept] (one line of every note, #454), so the list can grow past the
// cap only for them.
function top(
  candidates: NnCandidate[],
  kept: readonly NnCandidate[] = [],
): NnCandidate[] {
  const seen = new Set<string>();
  const unique = (list: readonly NnCandidate[]) =>
    list.filter((c) => {
      if (seen.has(c.id)) return false;
      seen.add(c.id);
      return true;
    });
  const must = unique(kept);
  const rest = unique([...candidates].sort((a, b) => b.score - a.score))
    .slice(0, Math.max(0, MAX_NN_CANDIDATES - must.length));
  return [...must, ...rest].sort((a, b) => b.score - a.score);
}

// Specific lines first, then plain ones, captions, generic lines last.
const TIER_BONUS: Record<Tier, number> = {
  specific: 100,
  plain: 60,
  generic: 0,
};
const CAPTION_BONUS = 50;

// A title or headline from the user's words: short, nothing sensitive, no
// banned phrase, in their language.
function titleText(
  text: string,
  max: number,
  language: "ru" | "en" | null,
  names: ReadonlySet<string>,
  needsSpace: boolean,
  // A name is a fact, not a line: no score needed ("AMF").
  scored = true,
): string | null {
  const t = text.trim().replace(/[.!?…,;:]+$/u, "").trim();
  if (!t || [...t].length > max) return null;
  if (needsSpace && !t.includes(" ")) return null;
  if (isSensitive(t) || bannedPhraseIn(t)) return null;
  if (scored && excerptScore(t, THEME) < 0) return null;
  if (inOtherLanguage(t, language, names)) return null;
  return t;
}

// A word that reads as a verb (#454): titles name things, so a phrase
// with one is a fragment of a sentence ("сразу пошли завтракать").
// Russian by its endings (infinitive, past, reflexive, present 1st/3rd
// plural), English by -ed/-ing and the common irregular ones.
const RU_VERB =
  /(ть|ться|чь|[аяеиыоуё]л|ли|ла|ло|лся|лась|лись|ем|ём|ешь|ете|ют|ят|ся|сь)$/u;
const EN_VERB =
  /^(?:\p{L}+(?:ed|ing)|went|got|had|was|were|is|are|ate|came|took|saw|did|go|get|have|has|made|felt|left)$/u;
const RU_NOT_VERB = new Set(["пиво", "село", "тепло", "рубли", "шлем"]);

export function hasVerb(text: string): boolean {
  return (text.toLowerCase().match(/\p{L}+/gu) ?? []).some((w) =>
    /\p{Script=Cyrillic}/u.test(w)
      ? w.length >= 4 && RU_VERB.test(w) && !RU_NOT_VERB.has(w)
      : EN_VERB.test(w)
  );
}

// A complaint or a low (#454): never the headline, the film's peak
// ("диджеи не очень").
const NEGATIVE =
  /(^|[^\p{L}])(не очень|так себе|плох|отстой|ужас|скучн|устал|разочар|жаль|грустн|бесит|надоел|не понрав|хуже|отврат|болит|похмел|not great|bad|boring|tired|awful|terrible|disappoint|sucked|meh|hangover|worst)/iu;

export function isNegative(text: string): boolean {
  return NEGATIVE.test(text);
}

// First names, never a headline alone (#454: "Петр").
const FIRST_NAMES = new Set([
  "александр",
  "саша",
  "алексей",
  "леша",
  "андрей",
  "антон",
  "артем",
  "борис",
  "вадим",
  "василий",
  "вася",
  "виктор",
  "владимир",
  "вова",
  "дмитрий",
  "дима",
  "денис",
  "евгений",
  "женя",
  "иван",
  "ваня",
  "игорь",
  "илья",
  "кирилл",
  "максим",
  "макс",
  "михаил",
  "миша",
  "никита",
  "николай",
  "коля",
  "олег",
  "павел",
  "паша",
  "петр",
  "петя",
  "роман",
  "рома",
  "сергей",
  "сережа",
  "степан",
  "юрий",
  "юра",
  "ярослав",
  "анна",
  "аня",
  "анастасия",
  "настя",
  "дарья",
  "даша",
  "екатерина",
  "катя",
  "елена",
  "лена",
  "ирина",
  "ира",
  "мария",
  "маша",
  "наталья",
  "наташа",
  "ольга",
  "оля",
  "светлана",
  "света",
  "татьяна",
  "таня",
  "юлия",
  "юля",
  "alex",
  "anna",
  "ben",
  "dan",
  "david",
  "emma",
  "james",
  "john",
  "kate",
  "leo",
  "mark",
  "max",
  "mike",
  "nick",
  "paul",
  "peter",
  "sam",
  "sara",
  "sarah",
  "tom",
]);

// Words a sentence often opens with that name nothing.
const OPENERS = new Set([
  "мы",
  "я",
  "он",
  "она",
  "они",
  "ну",
  "это",
  "вот",
  "там",
  "тут",
  "все",
  "всё",
  "сегодня",
  "вчера",
  "завтра",
  "потом",
  "сначала",
  "сначало",
  "наконец",
  "конечно",
  "очень",
  "так",
  "уже",
  "ещё",
  "еще",
  "но",
  "а",
  "и",
  "пока",
  "когда",
  "где",
  "здесь",
  "теперь",
  "we",
  "i",
  "it",
  "the",
  "a",
  "so",
  "then",
  "today",
  "yesterday",
  "and",
  "but",
  "our",
  "my",
]);
const PREPOSITIONS = new Set([
  "в",
  "во",
  "на",
  "из",
  "до",
  "у",
  "к",
  "от",
  "по",
  "под",
  "над",
  "за",
  "через",
  "против",
  "с",
  "со",
  "in",
  "at",
  "to",
  "from",
  "on",
  "vs",
]);

// The names in [text] (#454): runs of capitalised words — the opening one
// too when it reads as a name, not a verb ("Брюссель не меняется…") — and,
// in Cyrillic notes, Latin words ("Куко Unreal", "AMF"). After a
// preposition the run keeps it, as the case needs it ("В Амстердаме"),
// unless [bare] (a headline: "Куко Unreal").
export function namePhrases(text: string, bare = false): string[] {
  const out: string[] = [];
  for (const sentence of sentencesOf(text)) {
    const words = sentence.split(/\s+/u).map((w) =>
      w.replace(/^[^\p{L}\p{N}]+|[^\p{L}\p{N}]+$/gu, "")
    );
    const cyrillic = /\p{Script=Cyrillic}/u.test(sentence);
    const isName = (w: string, k: number) => {
      if ([...w].length < 2 || hasVerb(w)) return false;
      if (OPENERS.has(w.toLowerCase())) return false;
      // A diary sentence often opens on a verb in the present ("Сидим…",
      // "Идем…"): an opening word ending like one names nothing.
      if (k === 0 && /(им|ем|ём|ут|ют|ит|ет|ат|ят)$/u.test(w.toLowerCase())) {
        return false;
      }
      // A Latin name in Cyrillic notes: capitalised or an acronym ("Unreal",
      // "AMF"), never a lowercase word ("ufc", "english").
      if (cyrillic && /^\p{Script=Latin}+$/u.test(w)) return /^\p{Lu}/u.test(w);
      return /^\p{Lu}/u.test(w) &&
        (k > 0 || !PREPOSITIONS.has(w.toLowerCase()));
    };
    for (let k = 0; k < words.length; k++) {
      if (!isName(words[k], k)) continue;
      let end = k;
      while (end + 1 < words.length && isName(words[end + 1], end + 1)) end++;
      const before = words[k - 1]?.toLowerCase();
      const run = words.slice(k, end + 1).join(" ");
      // Bare, a lone Russian word after a preposition is in its case
      // ("Амстердаме", "Мираба"): left out. A name with a Latin part
      // ("Куко Unreal") doesn't decline.
      if (
        bare && before && PREPOSITIONS.has(before) &&
        /^\p{Script=Cyrillic}+$/u.test(run)
      ) {
        k = end;
        continue;
      }
      out.push(
        !bare && before && PREPOSITIONS.has(before)
          ? `${before[0].toUpperCase()}${before.slice(1)} ${run}`
          : run,
      );
      k = end;
    }
  }
  return out;
}

// Where a title or headline phrase may break (#454): before these words
// as well as at BREAKS ("Мы на месте" | "это просто огромный…").
const PHRASE_BREAKS =
  /\s+(?=(?:и|это|чтобы|которые|потом|а|но|так что|and|but|then)\s)/iu;
// A phrase never opens with one of them: "но супер устали" is a fragment,
// "супер устали" the user's words.
const LEADING =
  /^(?:и|это|чтобы|которые|потом|а|но|так что|ну|and|but|so|then)\s+/iu;

// The short phrases of [lines] that can be a title or headline: their
// pieces, broken further at PHRASE_BREAKS, without a leading conjunction
// — always the user's exact words, never a generic one.
function shortClauses(
  lines: readonly Line[],
  max: number,
  language: "ru" | "en" | null,
  names: ReadonlySet<string>,
): NnCandidate[] {
  const out: NnCandidate[] = [];
  for (const l of lines) {
    if (l.tier === "generic") continue;
    const pieces = [l.text, ...piecesOf(l.text)];
    const phrases = [
      ...pieces,
      ...pieces.flatMap((p) => p.split(PHRASE_BREAKS)),
    ].map((p) => p.trim().replace(LEADING, ""));
    for (const phrase of phrases) {
      const t = titleText(phrase, max, language, names, true);
      if (!t || isGeneric(t)) continue;
      out.push({
        id: noteLineId(l.note.id!, t),
        text: t,
        note_id: l.note.id!,
        photo_id: null,
        score: excerptScore(t, THEME),
      });
    }
  }
  return out;
}

// The place most of [photos] share, if any.
function placeOf(photos: readonly Photo[]): string | null {
  const counts = new Map<string, number>();
  for (const p of photos) {
    const place = p.place_text?.trim();
    if (place) counts.set(place, (counts.get(place) ?? 0) + 1);
  }
  let best: string | null = null;
  for (const [place, n] of counts) {
    if (best === null || n > counts.get(best)!) best = place;
  }
  return best;
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
    // share of the scene's photos within CARD_NEAR_MINUTES of it, then
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
    const sceneOf = (n: Note): number => {
      const own = scenes.findIndex((ps) => ps.some((p) => p.id === n.photo_id));
      if (own >= 0) return own - 1;
      const t = noteTime(n);
      if (Number.isNaN(t)) return -1;
      let best = 0;
      let bestShare = -1;
      let bestNear = Infinity;
      scenes.forEach((ps, k) => {
        const times = ps.map(timeOf).filter((x) => x > 0);
        if (times.length === 0) return;
        const share = times.filter((x) =>
          Math.abs(x - t) <= CARD_NEAR_MINUTES * 60_000
        ).length / times.length;
        const near = Math.min(...times.map((x) => Math.abs(x - t)));
        if (share > bestShare || (share === bestShare && near < bestNear)) {
          best = k;
          bestShare = share;
          bestNear = near;
        }
      });
      return best - 1;
    };
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

export interface NnPick {
  ids: string[];
  // A title the director wrote, when no candidate fits.
  free_title?: string | null;
}

export type NnPicks = Record<string, NnPick>;

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

export interface NnChosen {
  id: string;
  text: string;
  note_id: string | null;
  photo_id: string | null;
  score: number;
}

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

const CLOCK = /^\d{1,2}[:.]\d{2}$/u;
const DAY_N = /^(day|день)\s*\d+/iu;

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
    const fits = (chosen: NnChosen[], c: NnCandidate): string | null => {
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
    const chosen: NnChosen[] = [];
    const problems: string[] = [];
    let source: NnSlotResult["source"] = "none";
    if (pick) {
      // A title: the director's own, when it wrote one that holds — it
      // writes one whenever it names the chapter better (#454).
      const freeTitle = isTitle && pick.free_title
        ? cleanAiLine(pick.free_title)
        : "";
      if (freeTitle) {
        const why = freeTitleProblem(
          freeTitle,
          options,
          slot.kind === "headline" ? "headline" : "title",
        ) ??
          (titleFree(freeTitle) ? null : "repeats words the film shows");
        if (why) problems.push(`free title "${freeTitle}": ${why}`);
        else {
          chosen.push({
            id: "free",
            text: freeTitle,
            note_id: null,
            photo_id: null,
            score: 0,
          });
        }
      }
      for (const picked of (pick.ids ?? []).slice(0, slot.max_picks)) {
        if (chosen.length >= slot.max_picks) break;
        const scoped = unscoped(slot.slot, picked);
        if ("problem" in scoped) {
          problems.push(scoped.problem);
          continue;
        }
        const id = scoped.id;
        const c = slot.candidates.find((x) => x.id === id);
        if (!c) {
          problems.push(`${id}: not in this slot's list`);
          continue;
        }
        const why = fits(chosen, c);
        if (why) problems.push(`${id}: ${why}`);
        else chosen.push(take(c));
      }
      if (chosen.length > 0) source = "director";
    }
    if (chosen.length === 0) {
      for (const c of slot.candidates) {
        if (chosen.length >= slot.max_picks) break;
        if (fits(chosen, c) === null) chosen.push(take(c));
      }
      if (chosen.length > 0) source = "code";
    }
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
  if ([...title].length > max) return `longer than ${max} characters`;
  if (isSensitive(title)) return "sensitive words";
  if (bannedPhraseIn(title)) return "a banned phrase";
  if (CLOCK.test(title) || DAY_N.test(title)) return "a clock time or day";
  if (kind === "headline" && isNegative(title)) return "not upbeat";
  if (inOtherLanguage(title, options.language, options.names)) {
    return "not in the notes' language";
  }
  return null;
}

// The director's tool input as picks, or null when it isn't that shape.
export function parseNeonPicks(raw: unknown): NnPicks | null {
  if (typeof raw !== "object" || raw === null) return null;
  const list = (raw as Record<string, unknown>).picks;
  if (!Array.isArray(list)) return null;
  const picks: NnPicks = {};
  for (const p of list) {
    if (typeof p !== "object" || p === null) continue;
    const { slot, ids, free_title } = p as Record<string, unknown>;
    if (typeof slot !== "string") continue;
    picks[slot] = {
      ids: Array.isArray(ids)
        ? ids.filter((id): id is string => typeof id === "string")
        : [],
      free_title: typeof free_title === "string" ? free_title : null,
    };
  }
  return picks;
}

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

// A candidate's id as the director sees it: its slot's name first, so an
// id is only ever valid in its own slot (#454).
export function scopedId(slot: string, id: string): string {
  return `${slot}/${id}`;
}

// The candidate id a picked [id] names in [slot], or why it names none.
function unscoped(slot: string, id: string): { id: string } | {
  problem: string;
} {
  const at = id.indexOf("/");
  if (at < 0) return { id };
  const from = id.slice(0, at);
  return from === slot
    ? { id: id.slice(at + 1) }
    : { problem: `${id}: from ${from}'s list, valid only there` };
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
