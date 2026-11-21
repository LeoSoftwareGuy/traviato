// Picking the user's own words for the films (#398 R3, R6): candidates cut
// only at sentence or clause boundaries, scored for detail over summary,
// and kept away from drug references or profanity where the film puts
// words big (headlines, the note scene, the finale). Exact words only —
// nothing here rewords or corrects.

// A candidate is at most this long; a longer sentence is cut at its
// clauses.
export const MAX_EXCERPT_CHARS = 140;
const MIN_CLAUSE_CHARS = 20;

function collapse(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

// [text]'s sentences, exactly as written: each ends at . ! ? … followed by
// a space, or at a line break.
export function sentencesOf(text: string): string[] {
  return text.split(/(?<=[.!?…])\s+|\n+/u).map(collapse).filter((s) =>
    s.length > 0
  );
}

// A long sentence's clauses: cut after , ; : or before a dash, merged back
// until each is long enough to stand on its own.
function clausesOf(sentence: string): string[] {
  const pieces = sentence.split(/(?<=[,;:])\s+|\s+(?=[—–-]\s)/u).map(collapse)
    .filter((p) => p.length > 0);
  const clauses: string[] = [];
  for (const piece of pieces) {
    const last = clauses[clauses.length - 1];
    if (last !== undefined && [...last].length < MIN_CLAUSE_CHARS) {
      clauses[clauses.length - 1] = `${last} ${piece}`;
    } else {
      clauses.push(piece);
    }
  }
  return clauses;
}

// Every excerpt [text] offers: its sentences, a long one cut into clauses.
export function excerptCandidates(text: string): string[] {
  const out: string[] = [];
  for (const sentence of sentencesOf(text)) {
    if ([...sentence].length <= MAX_EXCERPT_CHARS) {
      out.push(sentence);
      continue;
    }
    for (const clause of clausesOf(sentence)) {
      if ([...clause].length <= MAX_EXCERPT_CHARS) out.push(clause);
    }
  }
  return out;
}

// Generic summaries (#398 R3): what a specific detail beats.
const GENERIC = [
  /\b(it )?was (so |really |very )?(fun|great|nice|cool|amazing)\b/iu,
  /\bhad (a )?(great |good )?(fun|time)\b/iu,
  /\b(everyone|we) (was|were|got) (so |very )?tired\b/iu,
  /\bwent (back )?home\b/iu,
  /\bwe (just )?sat\b/iu,
  /\b(good|nice|great) (day|night|time)\b/iu,
  /было (очень |так |супер )?(весело|классно|круто|здорово|хорошо)/iu,
  /все (очень )?устали/iu,
  /пошли (домой|спать)/iu,
  /(^|\s)сидели(\s|$|[.,!])/iu,
  /(хороший|отличный) (день|вечер)/iu,
  /отлично провели/iu,
];

const FOOD =
  /ribs|beer|burger|pizza|pasta|coffee|breakfast|brunch|dinner|lunch|wine|cocktail|fries|waffle|steak|ребр|рёбр|пив|бургер|пицц|кофе|завтрак|обед|ужин|вин[оа]|коктейл|вафл|стейк|картош/iu;
const FIRSTS =
  /\b(first|never|finally)\b|впервые|перв(ый|ая|ое|ые|ый раз)|никогда|наконец/iu;
// Emotions and feelings (#433): what the film plays first.
const FEELINGS =
  /\b(best|lov(e|ed|ing)|incredible|craziest|unreal|felt|feel(ing)?|happ(y|iest)|cried|tears|laugh(ed|ing)?|heart|goosebumps|scared|nervous|proud|excited|missed|miss|wish|alive)\b|самый|самая|самое|лучш|обожа|невероят|охренен|безумн|счастлив|плакал|слёз|слез|смеял|смех|люблю|любим|сердц|мурашк|страшно|волнов|горд|восторг|кайф|чувств|скуча/iu;

// What a film's vibe is about (#433): the lines that match it come right
// after the feelings.
export type LineTheme = "night" | "romance" | "outdoors";
const THEMES: Record<LineTheme, RegExp> = {
  night:
    /\b(music|dj|bass|crowd|danc(e|ed|ing)|track|song|lights?|dawn|sunrise|night|club|stage|beat|rave|party|sang)\b|музык|диджей|бас|толп|танц|трек|песн|рассвет|ноч|клуб|сцен|вечеринк|пели/iu,
  romance:
    /\b(us|we|together|kiss(ed)?|hands?|our|two of us|date|wedding|ring|proposed)\b|вместе|поцел|рук|вдвоём|вдвоем|наш|мы с|свидани|свадьб|кольц/iu,
  outdoors:
    /\b(trail|hike|hiked|summit|peak|forest|river|lake|sea|route|km|climb(ed)?|wind|mountains?|valley|camp|road|miles)\b|троп|поход|верш|лес|рек|озер|мор[еяю]|маршрут|км|подъ[её]м|ветер|гор[аыу]|долин|лагер|дорог/iu,
};

// The line theme of a played film: Neon Night is about the night, Golden
// Vows about the two of you, Field Notes about the outdoors; else none.
export function lineThemeFor(film: string): LineTheme | null {
  switch (film) {
    case "neon_night":
      return "night";
    case "golden_vows":
      return "romance";
    case "field_notes":
      return "outdoors";
    default:
      return null;
  }
}

// The tiers of a line's score (#433): feelings > the vibe > details >
// generic summaries. Details add up to at most 7, so a feeling or a vibe
// line always outranks one that only has details.
const FEELING_SCORE = 8;
const THEME_SCORE = 5;

// How good a line [excerpt] is for the film (#398 R3, #433): feelings
// first, then lines about [theme], then details — numbers, names and
// places, food, firsts, a good length; − generic summaries, a fragment.
export function excerptScore(
  excerpt: string,
  theme: LineTheme | null = null,
): number {
  const text = collapse(excerpt);
  const length = [...text].length;
  let score = 0;
  if (/\d/u.test(text)) score += 2;
  // Names and places: a capitalised word that doesn't start the sentence.
  const names =
    text.split(" ").slice(1).filter((w) => /^[A-ZА-ЯЁ][a-zа-яё]/u.test(w))
      .length;
  score += Math.min(names, 2);
  if (FOOD.test(text)) score += 1;
  if (FIRSTS.test(text)) score += 1;
  if (FEELINGS.test(text)) score += FEELING_SCORE;
  else if (text.includes("!")) score += 1;
  if (theme && THEMES[theme].test(text)) score += THEME_SCORE;
  if (length >= 30 && length <= MAX_EXCERPT_CHARS) score += 1;
  if (length < 15) score -= 1;
  // Generic summaries go last, whatever else they have.
  if (GENERIC.some((g) => g.test(text))) score -= FEELING_SCORE + THEME_SCORE;
  return score;
}

// A specific excerpt clears this; a generic one never does.
export const SPECIFIC_SCORE = 2;

export function isGeneric(excerpt: string): boolean {
  return GENERIC.some((g) => g.test(collapse(excerpt)));
}

// Drug references and profanity (#398 R6): never chosen for a headline,
// the note scene, the finale or a code-picked excerpt. The user's own
// captions and notes elsewhere stay as written.
const SENSITIVE = [
  /\b(mdma|molly|ecstasy|cocaine|ketamine|lsd|weed|stoned|drugs?)\b/iu,
  /\b(fuck\w*|shit(s|ty|ting|ted)?|bitch\w*|cunt)\b/iu,
  // Word starts only: \b knows no Cyrillic, and "бля" hides in "корабля".
  /(^|[^а-яё])(мдма|экстази|кокаин|кетамин|наркот|упорот|обдолб)/iu,
  /(^|[^а-яё])(бля|хуй|хуё|хуе|пизд|ёб|еба[тлн]|ебу|сука|нахуй|залуп|мудак)/iu,
];

export function isSensitive(text: string): boolean {
  return SENSITIVE.some((s) => s.test(text));
}

export interface PickedLine {
  note_id: string;
  text: string;
  score: number;
}

// The best lines of [notes] (#419), given in time order: their specific
// candidates (score ≥ SPECIFIC_SCORE, nothing sensitive, at most
// [maxChars]), the [max] highest-scoring, then back in the notes' order —
// so a page reads like the note did. Never a line twice. Empty when the
// notes have nothing specific: the film shows the note as before.
export function bestLines(
  notes: readonly { id: string; content: string }[],
  max: number,
  maxChars = MAX_EXCERPT_CHARS,
  theme: LineTheme | null = null,
): PickedLine[] {
  const seen = new Set<string>();
  const candidates: (PickedLine & { at: number })[] = [];
  for (const note of notes) {
    for (const text of excerptCandidates(note.content)) {
      if (seen.has(text) || isSensitive(text)) continue;
      if ([...text].length > maxChars) continue;
      const score = excerptScore(text, theme);
      if (score < SPECIFIC_SCORE) continue;
      seen.add(text);
      candidates.push({ note_id: note.id, text, score, at: candidates.length });
    }
  }
  return candidates
    .sort((a, b) => b.score - a.score || a.at - b.at)
    .slice(0, max)
    .sort((a, b) => a.at - b.at)
    .map(({ at: _at, ...line }) => line);
}

// A director line snapped to the note's own words (#444): the passage of
// [note] that reads the same ignoring case, spaces, punctuation and ё/е,
// in the note's exact words. Null when no passage matches.
export function snapToNote(line: string, note: string): string | null {
  const norm = (c: string) => {
    const l = c.toLowerCase();
    return l === "ё" ? "е" : l;
  };
  const isWord = (c: string) => /[\p{L}\p{N}]/u.test(c);
  const chars = [...note];
  let n = "";
  const at: number[] = [];
  let space = true;
  for (let i = 0; i < chars.length; i++) {
    if (isWord(chars[i])) {
      n += norm(chars[i]);
      at.push(i);
      space = false;
    } else if (!space) {
      n += " ";
      at.push(i);
      space = true;
    }
  }
  const want = [...line].map((c) => isWord(c) ? norm(c) : " ").join("")
    .replace(/\s+/g, " ").trim();
  if (want.length === 0) return null;
  // n is built per character, so its indices line up with [at].
  const nChars = [...n];
  const wChars = [...want];
  for (let s = 0; s + wChars.length <= nChars.length; s++) {
    if (s > 0 && nChars[s - 1] !== " ") continue;
    let ok = true;
    for (let k = 0; k < wChars.length && ok; k++) {
      ok = nChars[s + k] === wChars[k];
    }
    if (!ok) continue;
    const end = s + wChars.length;
    if (end < nChars.length && nChars[end] !== " ") continue;
    let to = at[end - 1] + 1;
    // Keep the sentence's own closing punctuation.
    while (to < chars.length && /[.!?…)»"]/u.test(chars[to])) to++;
    return chars.slice(at[s], to).join("").trim();
  }
  return null;
}
