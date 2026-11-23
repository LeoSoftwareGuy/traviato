// The words of a film, picked from code's candidates (#454, shared since
// #458): what Neon Night and Golden Vows both list for their slots — the
// user's own lines, names and places, with stable ids — and the rules for
// which scene a note belongs to. Each film builds its own skeleton and
// slots from these; neon_slots.ts and gv_slots.ts.

import { localMs } from "./time_zones.ts";
import type { TripData } from "./gather.ts";
import { bannedPhraseIn, cleanAiLine } from "./banned_phrases.ts";
import { tripLogicalDays } from "./logical_day.ts";
import {
  clausesOf,
  excerptScore,
  isDrugReference,
  isGeneric,
  isSensitive,
  type LineTheme,
  MAX_EXCERPT_CHARS,
  sentencesOf,
  SPECIFIC_SCORE,
} from "./excerpts.ts";
import { sameLine, timeOf } from "./neon_night.ts";

type Photo = TripData["photos"][number];
type Note = TripData["notes"][number];

// Candidates a slot lists at most: the top-scored.
export const MAX_SLOT_CANDIDATES = 8;

export interface SlotCandidate {
  id: string;
  text: string;
  note_id: string | null;
  // The photo it plays over (a moment's word), or null.
  photo_id: string | null;
  // Higher is better; the list is sorted by it.
  score: number;
}

// What a film's chapter needs for its notes: its photos and logical days.
export interface SlotChapter {
  photos: readonly Photo[];
  days: readonly string[];
}

// A short, stable id for a text (FNV-1a).
export function hash(text: string): string {
  let h = 0x811c9dc5;
  for (const c of text) {
    h ^= c.codePointAt(0)!;
    h = Math.imul(h, 0x01000193) >>> 0;
  }
  return h.toString(36);
}

export function noteLineId(noteId: string, text: string): string {
  return `n:${noteId}:${hash(text)}`;
}

export function norm(text: string): string {
  return text.toLowerCase().replace(/ё/g, "е").replace(/[^\p{L}\p{N}]+/gu, " ")
    .trim();
}

// When a note was written; NaN for an old one-a-day note (its time is its
// last edit) or none.
export function noteTime(n: Note): number {
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
export const YESTERDAY =
  /(^|[^\p{L}])(вчера|yesterday|last night)([^\p{L}]|$)/iu;

// The day before [day], 'YYYY-MM-DD'.
export function dayBefore(day: string): string {
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
  chapters: readonly SlotChapter[],
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
export type Tier = "specific" | "plain" | "generic";

export interface Line {
  note: Note;
  text: string;
  score: number;
  tier: Tier;
  // Its place in the note: lines keep the note's order on ties.
  k: number;
}

export function tierOf(text: string, score: number): Tier {
  if (isGeneric(text)) return "generic";
  return score >= SPECIFIC_SCORE ? "specific" : "plain";
}

// Where a clause breaks further (#454): at a slash, or before a
// conjunction that opens a clause of its own — so a long line without
// commas still gives a card a piece ("Выезжаем на AMF тусовку за окном
// ливень" | "но мы готовы дать еще один бой").
// (Never a bare "so": "I felt so happy" is one phrase.)
export const BREAKS =
  /\s*\/\s*|\s+(?=(?:но|а|так что|потом|зато|but|then)\s)/iu;

// A sentence's pieces: its clauses, then each clause broken at BREAKS —
// pieces of 2 words or more, the user's exact words.
export function piecesOf(sentence: string): string[] {
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
export function linesOf(note: Note, theme: LineTheme | null): Line[] {
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
      const score = excerptScore(text, theme);
      out.push({ note, text, score, tier: tierOf(text, score), k: out.length });
    }
  }
  return out;
}

export function nearestPhoto(
  photos: readonly Photo[],
  t: number,
): Photo | null {
  if (Number.isNaN(t) || photos.length === 0) return null;
  let best = photos[0];
  for (const p of photos) {
    if (Math.abs(timeOf(p) - t) < Math.abs(timeOf(best) - t)) best = p;
  }
  return best;
}

// The top MAX_SLOT_CANDIDATES of [candidates] by score — always keeping
// [kept] (one line of every note, #454), so the list can grow past the
// cap only for them.
export function top(
  candidates: SlotCandidate[],
  kept: readonly SlotCandidate[] = [],
): SlotCandidate[] {
  const seen = new Set<string>();
  const unique = (list: readonly SlotCandidate[]) =>
    list.filter((c) => {
      if (seen.has(c.id)) return false;
      seen.add(c.id);
      return true;
    });
  const must = unique(kept);
  const rest = unique([...candidates].sort((a, b) => b.score - a.score))
    .slice(0, Math.max(0, MAX_SLOT_CANDIDATES - must.length));
  return [...must, ...rest].sort((a, b) => b.score - a.score);
}

// Specific lines first, then plain ones, captions, generic lines last.
export const TIER_BONUS: Record<Tier, number> = {
  specific: 100,
  plain: 60,
  generic: 0,
};
export const CAPTION_BONUS = 50;

// A title or headline from the user's words: short, nothing sensitive, no
// banned phrase, in their language.
export function titleText(
  text: string,
  max: number,
  language: "ru" | "en" | null,
  names: ReadonlySet<string>,
  needsSpace: boolean,
  // A name is a fact, not a line: no score needed ("AMF").
  scored: boolean,
  theme: LineTheme | null,
): string | null {
  const t = text.trim().replace(/[.!?…,;:]+$/u, "").trim();
  if (!t || [...t].length > max) return null;
  if (needsSpace && !t.includes(" ")) return null;
  if (isSensitive(t) || bannedPhraseIn(t)) return null;
  if (scored && excerptScore(t, theme) < 0) return null;
  if (inOtherLanguage(t, language, names)) return null;
  return t;
}

// A word that reads as a verb (#454): titles name things, so a phrase
// with one is a fragment of a sentence ("сразу пошли завтракать").
// Russian by its endings (infinitive, past, reflexive, present 1st/3rd
// plural), English by -ed/-ing and the common irregular ones.
export const RU_VERB =
  /(ть|ться|чь|[аяеиыоуё]л|ли|ла|ло|лся|лась|лись|ем|ём|ешь|ете|ют|ят|ся|сь)$/u;
export const EN_VERB =
  /^(?:\p{L}+(?:ed|ing)|went|got|had|was|were|is|are|ate|came|took|saw|did|go|get|have|has|made|felt|left)$/u;
export const RU_NOT_VERB = new Set(["пиво", "село", "тепло", "рубли", "шлем"]);

export function hasVerb(text: string): boolean {
  return (text.toLowerCase().match(/\p{L}+/gu) ?? []).some((w) =>
    /\p{Script=Cyrillic}/u.test(w)
      ? w.length >= 4 && RU_VERB.test(w) && !RU_NOT_VERB.has(w)
      : EN_VERB.test(w)
  );
}

// A complaint or a low (#454): never the headline, the film's peak
// ("диджеи не очень").
export const NEGATIVE =
  /(^|[^\p{L}])(не очень|так себе|плох|отстой|ужас|скучн|устал|разочар|жаль|грустн|бесит|надоел|не понрав|хуже|отврат|болит|похмел|not great|bad|boring|tired|awful|terrible|disappoint|sucked|meh|hangover|worst)/iu;

export function isNegative(text: string): boolean {
  return NEGATIVE.test(text);
}

// First names, never a headline alone (#454: "Петр").
export const FIRST_NAMES = new Set([
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
export const OPENERS = new Set([
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
export const PREPOSITIONS = new Set([
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
export const PHRASE_BREAKS =
  /\s+(?=(?:и|это|чтобы|которые|потом|а|но|так что|and|but|then)\s)/iu;
// A phrase never opens with one of them: "но супер устали" is a fragment,
// "супер устали" the user's words.
export const LEADING =
  /^(?:и|это|чтобы|которые|потом|а|но|так что|ну|and|but|so|then)\s+/iu;

// The short phrases of [lines] that can be a title or headline: their
// pieces, broken further at PHRASE_BREAKS, without a leading conjunction
// — always the user's exact words, never a generic one.
export function shortClauses(
  lines: readonly Line[],
  max: number,
  language: "ru" | "en" | null,
  names: ReadonlySet<string>,
  theme: LineTheme | null,
): SlotCandidate[] {
  const out: SlotCandidate[] = [];
  for (const l of lines) {
    if (l.tier === "generic") continue;
    const pieces = [l.text, ...piecesOf(l.text)];
    const phrases = [
      ...pieces,
      ...pieces.flatMap((p) => p.split(PHRASE_BREAKS)),
    ].map((p) => p.trim().replace(LEADING, ""));
    for (const phrase of phrases) {
      const t = titleText(phrase, max, language, names, true, true, theme);
      if (!t || isGeneric(t)) continue;
      out.push({
        id: noteLineId(l.note.id!, t),
        text: t,
        note_id: l.note.id!,
        photo_id: null,
        score: excerptScore(t, theme),
      });
    }
  }
  return out;
}

// The place most of [photos] share, if any.
export function placeOf(photos: readonly Photo[]): string | null {
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

// A note belongs to the scene whose photos it was written among (#456):
// the share of the scene's photos taken within this many minutes of it.
export const SCENE_NEAR_MINUTES = 90;

// Which of [scenes] (each its photos) note [n] belongs to (#456, a hard
// filter): the scene with its photo; else the largest share of a scene's
// photos taken within SCENE_NEAR_MINUTES of when it was written, then the
// nearest photo; the first scene on a tie or for a note without a time.
export function noteScene(
  scenes: readonly (readonly Photo[])[],
  n: Note,
): number {
  const own = scenes.findIndex((ps) => ps.some((p) => p.id === n.photo_id));
  if (own >= 0) return own;
  const t = noteTime(n);
  if (Number.isNaN(t)) return 0;
  let best = 0;
  let bestShare = -1;
  let bestNear = Infinity;
  scenes.forEach((ps, k) => {
    const times = ps.map(timeOf).filter((x) => x > 0);
    if (times.length === 0) return;
    const share = times.filter((x) =>
      Math.abs(x - t) <= SCENE_NEAR_MINUTES * 60_000
    ).length / times.length;
    const near = Math.min(...times.map((x) => Math.abs(x - t)));
    if (share > bestShare || (share === bestShare && near < bestNear)) {
      best = k;
      bestShare = share;
      bestNear = near;
    }
  });
  return best;
}

// --- The director's picks ---------------------------------------------------

export interface SlotPick {
  ids: string[];
  // Words the director wrote itself (a title, a headline, a finale),
  // checked before they play.
  free_title?: string | null;
}

export type SlotPicks = Record<string, SlotPick>;

// The director's tool input as picks, or null when it isn't that shape.
export function parsePicks(raw: unknown): SlotPicks | null {
  if (typeof raw !== "object" || raw === null) return null;
  const list = (raw as Record<string, unknown>).picks;
  if (!Array.isArray(list)) return null;
  const picks: SlotPicks = {};
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

// A candidate's id as the director sees it: its slot's name first, so an
// id is only ever valid in its own slot (#454).
export function scopedId(slot: string, id: string): string {
  return `${slot}/${id}`;
}

// The candidate id a picked [id] names in [slot], or why it names none.
export function unscoped(slot: string, id: string): { id: string } | {
  problem: string;
} {
  const at = id.indexOf("/");
  if (at < 0) return { id };
  const from = id.slice(0, at);
  return from === slot
    ? { id: id.slice(at + 1) }
    : { problem: `${id}: from ${from}'s list, valid only there` };
}

export const CLOCK = /^\d{1,2}[:.]\d{2}$/u;
export const DAY_N = /^(day|день)\s*\d+/iu;

// Why the director's own words can't be used, or null (#454): at most
// [max] characters, in the user's language, nothing sensitive or banned,
// never a clock time or "Day N" — and, [upbeat], never a complaint.
export function freeTextProblem(
  text: string,
  options: { language: "ru" | "en" | null; names: ReadonlySet<string> },
  max: number,
  upbeat: boolean,
): string | null {
  if ([...text].length > max) return `longer than ${max} characters`;
  if (isSensitive(text)) return "sensitive words";
  if (bannedPhraseIn(text)) return "a banned phrase";
  if (CLOCK.test(text) || DAY_N.test(text)) return "a clock time or day";
  if (upbeat && isNegative(text)) return "not upbeat";
  if (inOtherLanguage(text, options.language, options.names)) {
    return "not in the notes' language";
  }
  return null;
}

// What a slot plays (#454): its words, and who chose them.
export interface SlotChosen {
  id: string;
  text: string;
  note_id: string | null;
  photo_id: string | null;
  score: number;
}

export interface Chosen {
  chosen: SlotChosen[];
  // Why picks were dropped.
  problems: string[];
  // director: the director's pick; code: the top free candidate; none:
  // nothing to show.
  source: "director" | "code" | "none";
}

// A slot's words (#454): the director's own words when they hold
// ([freeText] says why not, or null — no free words in this slot), then
// its picked ids that are in the slot's own list and [fits] (null = it
// fits), up to max_picks; with none of them, the top candidates that fit.
// Nothing is rewritten: a pick is taken as it is or replaced by code's.
export function choose(
  slot: {
    slot: string;
    max_picks: number;
    candidates: readonly SlotCandidate[];
  },
  pick: SlotPick | undefined,
  rules: {
    freeText: ((text: string) => string | null) | null;
    fits: (chosen: readonly SlotChosen[], c: SlotCandidate) => string | null;
  },
): Chosen {
  const take = (c: SlotCandidate): SlotChosen => ({
    id: c.id,
    text: c.text,
    note_id: c.note_id,
    photo_id: c.photo_id,
    score: c.score,
  });
  const chosen: SlotChosen[] = [];
  const problems: string[] = [];
  let source: Chosen["source"] = "none";
  if (pick) {
    const free = rules.freeText && pick.free_title
      ? cleanAiLine(pick.free_title)
      : "";
    if (free) {
      const why = rules.freeText!(free);
      if (why) problems.push(`free title "${free}": ${why}`);
      else {
        chosen.push({
          id: "free",
          text: free,
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
      const why = rules.fits(chosen, c);
      if (why) problems.push(`${id}: ${why}`);
      else chosen.push(take(c));
    }
    if (chosen.length > 0) source = "director";
  }
  if (chosen.length === 0) {
    for (const c of slot.candidates) {
      if (chosen.length >= slot.max_picks) break;
      if (rules.fits(chosen, c) === null) chosen.push(take(c));
    }
    if (chosen.length > 0) source = "code";
  }
  return { chosen, problems, source };
}

// A chapter's last-resort title: "Day N" / "День N" in the user's
// language, N its day's place among the film's days (#454: never
// "День 1 · 3"). A later part of a day says when it is — "День 1 · вечер"
// by its first photo's local hour, never a clock time — so no two
// chapters share a title; the same stretch again takes an ordinal
// ("День 1 · вторая ночь").
export type Stretch = "morning" | "afternoon" | "evening" | "night";
const STRETCH: Record<"ru" | "en", Record<Stretch, string>> = {
  ru: { morning: "утро", afternoon: "день", evening: "вечер", night: "ночь" },
  en: {
    morning: "morning",
    afternoon: "afternoon",
    evening: "evening",
    night: "night",
  },
};
// Second to fifth, by the Russian word's gender (утро n, день/вечер m,
// ночь f) — short enough for a title of 22 ("День 12 · третий вечер").
const ORDINALS: Record<"ru" | "en", Record<Stretch, string[]>> = {
  ru: {
    morning: ["второе", "третье", "4-е", "5-е"],
    afternoon: ["второй", "третий", "4-й", "5-й"],
    evening: ["второй", "третий", "4-й", "5-й"],
    night: ["вторая", "третья", "4-я", "5-я"],
  },
  en: Object.fromEntries(
    (["morning", "afternoon", "evening", "night"] as const).map((
      k,
    ) => [k, ["2nd", "3rd", "4th", "5th"]]),
  ) as Record<Stretch, string[]>,
};

export function stretchOf(hour: number): Stretch {
  return hour >= 5 && hour < 12
    ? "morning"
    : hour >= 12 && hour < 17
    ? "afternoon"
    : hour >= 17 && hour < 23
    ? "evening"
    : "night";
}

export function dayTitleFor(
  tripData: TripData,
  chapters: readonly SlotChapter[],
  // Golden Vows (#458): the album's language when no note shows one.
  lang: "ru" | "en" = writtenLanguage(tripData) === "ru" ? "ru" : "en",
): (chapter: number) => string {
  const all = [...new Set(chapters.flatMap((c) => c.days))].sort();
  const word = lang === "ru" ? "День" : "Day";
  const count = new Map<string, number>();
  const titles = chapters.map((c, i) => {
    const day = `${word} ${Math.max(0, all.indexOf(c.days[0] ?? "")) + 1}`;
    if (chapters.findIndex((x) => x.days[0] === c.days[0]) === i) return day;
    const first = c.photos[0];
    const at = first?.taken_at ?? first?.created_at;
    const stretch = stretchOf(
      at ? new Date(localMs(tripData, first, at)).getUTCHours() : 20,
    );
    const key = `${day}|${stretch}`;
    const n = count.get(key) ?? 0;
    count.set(key, n + 1);
    const name = STRETCH[lang][stretch];
    return n === 0
      ? `${day} · ${name}`
      : `${day} · ${ORDINALS[lang][stretch][Math.min(n, 4) - 1]} ${name}`;
  });
  return (i) => titles[i];
}

// --- Shared with Golden Vows and Sky Story (#463) ---------------------------

// Words that open a short phrase of a note (#460): "for a golden
// coffee", "with famous spas", "to irish bar".
const PHRASE_OPENERS = new Set([
  "a",
  "an",
  "the",
  "some",
  "our",
  "my",
  "this",
  "these",
  "those",
  "with",
  "for",
  "to",
  "at",
  "in",
  "into",
  "of",
  "from",
  "out",
  "on",
]);
// Words a phrase stops before.
const PHRASE_STOPS = new Set([
  ...PHRASE_OPENERS,
  "and",
  "but",
  "or",
  "so",
  "is",
  "was",
  "are",
  "were",
  "it",
  "its",
  "that",
  "which",
  "who",
  "too",
  "very",
  "really",
  "just",
  "then",
  "there",
  "here",
  "we",
  "i",
  "you",
  "he",
  "she",
  "they",
  "me",
  "us",
  "be",
  "been",
  "had",
  "has",
  "have",
  "went",
  "go",
  "got",
  "by",
  "as",
  "after",
  "before",
  "about",
  "all",
  "not",
  "no",
  "also",
  "even",
  "full",
  "around",
  "like",
  "lots",
  "lot",
  "more",
  "most",
  "s",
  "t",
]);
// A phrase never opens on a verb ("make things", "walk around").
const PHRASE_VERBS = new Set([
  "make",
  "take",
  "walk",
  "check",
  "see",
  "start",
  "explore",
  "go",
  "come",
  "find",
  "get",
  "do",
  "eat",
  "drink",
  "try",
  "visit",
  "keep",
  "say",
  "feel",
  "look",
  "meet",
  "buy",
  "sleep",
  "stay",
]);
// What a birthday, a wedding, an anniversary names (#460): "Elmas
// birthday", kept exactly as written.
const OCCASION_NOUN = /^(birthday|wedding|anniversary|honeymoon|engagement)$/iu;

// The short phrases of [text] that name something (#460): 2–3 words after
// an article or preposition ("golden coffee", "famous spas"), and a name
// with its occasion ("Elmas birthday") — the user's words as written,
// English only (Russian has no articles to find them by).
export function notePhrases(text: string): string[] {
  const out: string[] = [];
  for (const sentence of text.split(/[.!?;,:()\n]+/u)) {
    const words = sentence.split(/\s+/u).filter(Boolean);
    const bare = words.map((w) => w.toLowerCase().replace(/[^\p{L}'’-]/gu, ""));
    for (let i = 0; i < words.length; i++) {
      // "Elmas birthday": a capitalised word before an occasion noun.
      if (
        i + 1 < words.length && /^\p{Lu}/u.test(words[i]) &&
        OCCASION_NOUN.test(bare[i + 1]) && !PHRASE_STOPS.has(bare[i])
      ) out.push(`${words[i]} ${bare[i + 1]}`);
      if (!PHRASE_OPENERS.has(bare[i])) continue;
      const run: string[] = [];
      for (let k = i + 1; k < words.length && run.length < 3; k++) {
        if (PHRASE_STOPS.has(bare[k]) || !bare[k]) break;
        run.push(words[k].replace(/[^\p{L}\p{N}'’-]/gu, ""));
      }
      if (
        run.length >= 2 && !PHRASE_VERBS.has(run[0].toLowerCase()) &&
        !hasVerb(run.join(" "))
      ) out.push(run.join(" "));
    }
  }
  return [...new Set(out)];
}

// [list] without lines that differ only in case, spacing or punctuation
// from a better one before them.
export function distinct(list: SlotCandidate[]): SlotCandidate[] {
  const kept: SlotCandidate[] = [];
  for (const c of [...list].sort((a, b) => b.score - a.score)) {
    if (!kept.some((k) => sameLine(k.text, c.text))) kept.push(c);
  }
  return kept;
}

export const topDistinct = (list: SlotCandidate[]) => top(distinct(list));

// The words the director's own text is checked against (#460).
export interface WordGuard {
  // The names the user wrote, as written, lowercased: the memory's name,
  // capitalised words inside their notes' and captions' sentences, the
  // place.
  names: ReadonlySet<string>;
  // Every word of the user's (notes, captions, memory name, place) and of
  // code's own lines, lowercased.
  own: ReadonlySet<string>;
  // Words only the photo descriptions say.
  described: ReadonlySet<string>;
}

const wordsOf = (text: string) =>
  text.split(/[^\p{L}\p{N}'’]+/u).filter(Boolean);
// A word without its possessive: "Elmas's" → "Elmas", "Elma's" → "Elma".
const stem = (w: string) => w.replace(/['’]s?$/u, "").toLowerCase();

// The guard for [tripData] (#460); [code] are the film's own lines.
export function wordGuard(
  tripData: TripData,
  summaries: ReadonlyMap<string, string>,
  code: readonly string[] = [],
): WordGuard {
  const texts = [
    tripData.trip.name,
    tripData.trip.destination ?? "",
    ...tripData.notes.map((n) => n.content),
    ...tripData.photos.map((p) => p.caption ?? ""),
    ...tripData.photos.map((p) => p.place_text ?? ""),
  ];
  const names = new Set<string>();
  for (const w of wordsOf(tripData.trip.name)) names.add(stem(w));
  for (const w of wordsOf(tripData.trip.destination ?? "")) names.add(stem(w));
  for (const t of texts.slice(2)) {
    for (const sentence of t.split(/[.!?\n]+/u)) {
      wordsOf(sentence).forEach((w, k) => {
        if (k > 0 && /^\p{Lu}/u.test(w)) names.add(stem(w));
      });
    }
  }
  const own = new Set(
    [...texts, ...code].flatMap((t) => wordsOf(t).map(stem)),
  );
  const described = new Set(
    [...summaries.values()].flatMap((t) => wordsOf(t).map(stem))
      .filter((w) => [...w].length >= 4 && !own.has(w)),
  );
  return { names, own, described };
}

// How many single-letter edits turn [a] into [b].
function editDistance(a: string, b: string): number {
  const row = Array.from({ length: b.length + 1 }, (_, k) => k);
  for (let i = 1; i <= a.length; i++) {
    let prev = row[0];
    row[0] = i;
    for (let k = 1; k <= b.length; k++) {
      const next = row[k];
      row[k] = Math.min(
        row[k] + 1,
        row[k - 1] + 1,
        prev + (a[i - 1] === b[k - 1] ? 0 : 1),
      );
      prev = next;
    }
  }
  return row[b.length];
}

// Why the director's own [text] can't play, or null (#460): it changes a
// name the user wrote ("Elma's" for "Elmas" — the name, or the name and
// "'s", only), names a person the user never wrote, or says what only
// the photo descriptions say.
export function wordsProblem(
  text: string,
  guard: WordGuard,
): string | null {
  for (const raw of wordsOf(text)) {
    const w = stem(raw);
    if (!w || guard.names.has(w)) continue;
    for (const name of guard.names) {
      if (
        [...name].length >= 4 && w[0] === name[0] &&
        editDistance(w, name) <= ([...name].length >= 6 ? 2 : 1)
      ) return `«${raw}» changes the name «${name}»`;
    }
    if (guard.own.has(w)) continue;
    if (FIRST_NAMES.has(w)) return `«${raw}»: a name the user never wrote`;
    if (guard.described.has(w)) {
      return `«${raw}»: only in the photo descriptions`;
    }
  }
  return null;
}

// How a photo ranks for a main page (#458): Always, then captioned, then
// one a note was written on or among ([withNote], #460: a main page shows
// a note), then its hero score. Higher is better.
export function photoRank(
  p: Photo,
  heroScores: Readonly<Record<string, number>>,
  withNote: ReadonlySet<string> | ReadonlyMap<string, number> = new Set(),
): number {
  // The more notes belong to it, the better (#460), up to 3 (a note
  // written on it counts 2).
  const notes = withNote instanceof Map
    ? Math.min(3, withNote.get(p.id) ?? 0)
    : withNote.has(p.id)
    ? 1
    : 0;
  return (p.use_in_wrap_up === true ? 100 : 0) +
    (p.caption?.trim() ? 20 : 0) + 10 * notes + (heroScores[p.id] ?? 0);
}

// The photos the notes belong to (#460): a note's own photo, else the
// film photo taken nearest when it was written, within
// SCENE_NEAR_MINUTES. A note written far from every photo anchors none.
export function noteAnchors(
  tripData: TripData,
  photos: readonly Photo[],
): Map<string, string> {
  const anchors = new Map<string, string>();
  const ids = new Set(photos.map((p) => p.id));
  for (const n of tripData.notes) {
    if (!n.id || !n.content.trim()) continue;
    if (n.photo_id && ids.has(n.photo_id)) {
      anchors.set(n.id, n.photo_id);
      continue;
    }
    const near = nearestPhoto(photos, noteTime(n));
    if (
      near &&
      Math.abs(timeOf(near) - noteTime(n)) <= SCENE_NEAR_MINUTES * 60_000
    ) anchors.set(n.id, near.id);
  }
  return anchors;
}

// [count] of [photos] (time order) for a page of prints: Always picks
// first, then the best shot of each equal stretch of the rest; in time
// order.
export function spreadPicks(
  photos: readonly Photo[],
  count: number,
  score: (p: Photo) => number,
): Photo[] {
  // The best of each stretch of [list], [room] of them.
  const spread = (list: readonly Photo[], room: number, picked: Photo[]) => {
    for (let k = 0; k < room && list.length > 0; k++) {
      const from = Math.floor(k * list.length / room);
      const to = Math.max(from + 1, Math.floor((k + 1) * list.length / room));
      const best = list.slice(from, to).filter((p) => !picked.includes(p))
        .sort((x, y) => score(y) - score(x))[0];
      if (best) picked.push(best);
    }
  };
  const always = photos.filter((p) => p.use_in_wrap_up === true);
  const picked: Photo[] = [];
  // More Always picks than room (#460): spread over the chapter too, not
  // its first ones.
  if (always.length >= count) spread(always, count, picked);
  else {
    picked.push(...always);
    spread(
      photos.filter((p) => !always.includes(p)),
      count - always.length,
      picked,
    );
  }
  return photos.filter((p) => picked.includes(p));
}
