import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  excerptCandidates,
  excerptScore,
  isGeneric,
  isSensitive,
  MAX_EXCERPT_CHARS,
  SPECIFIC_SCORE,
} from "./excerpts.ts";

Deno.test("candidates are whole sentences, exactly as written", () => {
  assertEquals(
    excerptCandidates("Landed at 6. Ribs!\nWent home"),
    ["Landed at 6.", "Ribs!", "Went home"],
  );
});

Deno.test("a long sentence is cut at its clauses, never mid-clause", () => {
  const long = `${"We walked along every canal in the old town, ".repeat(2)}` +
    `then we found the tiny bar with 4 stools where the owner played jazz records until three in the morning and nobody wanted to leave`;
  assert([...long].length > MAX_EXCERPT_CHARS);
  const out = excerptCandidates(long);
  assert(out.length > 1);
  for (const c of out) {
    assert(long.includes(c), c);
    assert([...c].length <= MAX_EXCERPT_CHARS);
  }
});

Deno.test("specific beats generic, in English and Russian", () => {
  const specific = [
    "Заказали 4,5 кг рёбер на троих в Брюсселе!",
    "First time on a bike in Amsterdam, 12 km to Zaandam.",
  ];
  const generic = [
    "It was fun.",
    "Everyone was tired.",
    "We went home.",
    "Было весело.",
    "Все устали, пошли домой.",
  ];
  for (const s of specific) assert(excerptScore(s) >= SPECIFIC_SCORE, s);
  for (const g of generic) {
    assert(excerptScore(g) < SPECIFIC_SCORE, g);
    assert(isGeneric(g), g);
  }
  assert(!isGeneric(specific[0]));
});

Deno.test("drug references and profanity are flagged, innocent words are not", () => {
  for (
    const s of [
      "Someone had MDMA",
      "That was fucking great",
      "Кто-то закинулся экстази",
      "Бля, опоздали",
      "Пошли нахуй домой",
    ]
  ) {
    assert(isSensitive(s), s);
  }
  for (
    const s of [
      "Мы видели корабля нос",
      "Shitake mushrooms? No, shiitake",
      "Сухой закон",
      "Brussels sprouts",
    ]
  ) {
    assertEquals(isSensitive(s), false, s);
  }
});
