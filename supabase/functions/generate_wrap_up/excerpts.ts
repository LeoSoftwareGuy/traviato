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
const FEELINGS =
  /\b(best|loved|incredible|craziest|unreal)\b|самый|самая|самое|лучш|обожа|невероят|охренен|безумн/iu;

// How specific [excerpt] is (#398 R3): + numbers, names and places, food,
// firsts, strong feelings, a good length; − generic summaries, a fragment.
export function excerptScore(excerpt: string): number {
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
  if (FEELINGS.test(text) || text.includes("!")) score += 1;
  if (length >= 30 && length <= MAX_EXCERPT_CHARS) score += 1;
  if (length < 15) score -= 1;
  if (GENERIC.some((g) => g.test(text))) score -= 3;
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
