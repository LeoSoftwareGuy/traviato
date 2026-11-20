// Fitting an AI-written line to its space (#428, #433).

// [text] within [max] characters (#428): as it is, else with whole words
// dropped from its end (and any dangling punctuation), keeping at least
// two words; else null. Never cut inside a word.
export function wholeWords(text: string, max: number): string | null {
  const trimmed = text.trim();
  if ([...trimmed].length <= max) return trimmed || null;
  const words = trimmed.split(/\s+/u);
  while (words.length > 2 && [...words.join(" ")].length > max) words.pop();
  const out = words.join(" ").replace(/[\s,;:—–·.-]+$/u, "");
  return words.length >= 2 && [...out].length <= max ? out : null;
}
