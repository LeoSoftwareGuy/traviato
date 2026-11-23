// The words an AI-written line may never say (#433), and how such a line
// is cleaned. Moved from film_plan.ts when the classic plan call went
// (#463). Never used on the user's own captions or notes.

export const BANNED_PHRASES = [
  "unforgettable",
  "adventure awaits",
  "wanderlust",
  "memories to last a lifetime",
  "epic",
];

// The banned phrase found in [line], or null.
export function bannedPhraseIn(line: string): string | null {
  const lower = line.toLowerCase();
  for (const phrase of BANNED_PHRASES) {
    // Whole words only, so "epicentre" isn't "epic".
    const pattern = new RegExp(`(^|[^\\p{L}])${phrase}($|[^\\p{L}])`, "u");
    if (pattern.test(lower)) return phrase;
  }
  return null;
}

const OPENING_QUOTES = new Set(['"', "“", "«", "„"]);
const CLOSING_QUOTES = new Set(['"', "”", "»", "“"]);
const QUOTES = new Set([...OPENING_QUOTES, ...CLOSING_QUOTES]);

function quoteCount(line: string): number {
  return [...line].filter((ch) => QUOTES.has(ch)).length;
}

// [line] trimmed, without a quote pair wrapping all of it and without an
// unmatched quote at either end. Quotes inside the line stay.
// An AI-written [line] without its banned phrases (#433): each removed as
// whole words, with the spacing and punctuation left dangling around it.
// Never used on the user's own captions or notes.
export function withoutBannedPhrases(line: string): string {
  let out = line;
  for (const phrase of BANNED_PHRASES) {
    const pattern = new RegExp(
      `(^|[^\\p{L}])${phrase.replace(/ /g, "\\s+")}(?=$|[^\\p{L}])`,
      "giu",
    );
    out = out.replace(pattern, "$1");
  }
  if (out === line) return line;
  return out.replace(/\s{2,}/gu, " ")
    .replace(/\s+([,.!?;:])/gu, "$1")
    .replace(/^[\s,;:—–·.!-]+|[\s,;:—–·-]+$/gu, "")
    .trim();
}

// An AI-written line made fit (#433): cleaned, banned phrases removed.
export function cleanAiLine(line: string): string {
  return withoutBannedPhrases(cleanLine(line));
}

export function cleanLine(line: string): string {
  let out = line.trim();
  for (;;) {
    const first = out[0];
    const last = out[out.length - 1];
    if (
      out.length >= 2 && OPENING_QUOTES.has(first) &&
      CLOSING_QUOTES.has(last) && quoteCount(out.slice(1, -1)) % 2 === 0
    ) {
      out = out.slice(1, -1).trim();
    } else if (quoteCount(out) % 2 === 1 && CLOSING_QUOTES.has(last)) {
      out = out.slice(0, -1).trim();
    } else if (quoteCount(out) % 2 === 1 && OPENING_QUOTES.has(first)) {
      out = out.slice(1).trim();
    } else {
      return out;
    }
  }
}
