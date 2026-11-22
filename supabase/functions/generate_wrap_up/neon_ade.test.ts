// ADE-Amsterdam 2026 on its real data (#454): the memory exported from the
// database (fixtures/ade_amsterdam.json) and the director's recorded
// picks for it (fixtures/ade_amsterdam_picks.json). Re-record the picks
// after a change to the slots: tools/record_neon_picks.ts.
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { adeFilmMemory, adePicks } from "./ade_amsterdam.ts";
import { neonNightFilm } from "./neon_film.ts";
import {
  inOtherLanguage,
  namesOf,
  type NnSlot,
  unlistedNotes,
  writtenLanguage,
} from "./neon_slots.ts";
import { isDrugReference } from "./excerpts.ts";
import { MAX_NN_TITLE_CHARS, sameLine } from "./neon_night.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";
import { nnBeatsFor } from "./film_length.ts";

const BRUSSELS_LINE = "Брюссель не меняется отличное пиво и вкусная еда.";
const NOTE_LINE = "Это самый крутой сет который я слышал или это М?";
const DRUG_NOTE = "Покурили косячок";

// The film code cuts, with code's picks (what the director is shown).
function cut() {
  const { memory, heroScores } = adeFilmMemory();
  return { memory, ...neonNightFilm(memory, null, heroScores) };
}

// The film as it plays with the director's recorded picks.
function played() {
  const { memory, heroScores } = adeFilmMemory();
  return { memory, ...neonNightFilm(memory, adePicks(), heroScores) };
}

const slot = (slots: NnSlot[], id: string) => slots.find((s) => s.slot === id)!;

Deno.test("ADE: five chapters — the Tallinn morning, the evening, Kuko, the AMF day, Brussels", () => {
  const { chapters } = cut();
  assertEquals(chapters.map((c) => c.days), [
    ["2026-10-23"],
    ["2026-10-23"],
    ["2026-10-23"],
    ["2026-10-24"],
    ["2026-10-25"],
  ]);
  // Every chapter in time order, its card first.
  for (const c of chapters) {
    assert(c.card.length > 0);
    const order = c.photos.map((p) => p.id);
    const shown = [...c.card, ...c.moments.flatMap((m) => m.photo_ids)];
    assertEquals(
      shown,
      [...shown].sort((a, b) => order.indexOf(a) - order.indexOf(b)),
    );
  }
});

Deno.test("ADE: every note without explicit drug words is on a list (#454)", () => {
  const { memory, chapters, slots } = cut();
  const unlisted = unlistedNotes(memory, chapters, slots);
  assertEquals(unlisted.map((n) => n.reason), [
    "explicit drug words in every sentence",
  ]);
  assert(unlisted[0].text.startsWith(DRUG_NOTE));
  const listed = new Set(
    slots.flatMap((s) => s.candidates.map((c) => c.note_id)),
  );
  for (const n of memory.notes) {
    if (n.content.startsWith(DRUG_NOTE)) continue;
    assert(listed.has(n.id!), n.content);
  }
});

Deno.test("ADE: every chapter with notes has card candidates; Brussels has its line", () => {
  const { slots } = cut();
  for (let i = 1; i <= 5; i++) {
    assert(slot(slots, `ch${i}.card`).candidates.length > 0, `ch${i}`);
  }
  const brussels = slot(slots, "ch5.card").candidates.map((c) => c.text);
  assert(brussels.includes(BRUSSELS_LINE), brussels.join(" | "));
  // The AMF night's notes are ch4's (#454: they were on no list).
  const amf = slot(slots, "ch4.card").candidates.map((c) => c.text);
  assert(amf.some((t) => t.startsWith("Выезжаем на AMF тусовку")));
  assert(amf.some((t) => t.startsWith("Мы на месте")));
  // "вчера…" is the night before's: Kuko's card.
  assert(
    slot(slots, "ch3.card").candidates.some((c) =>
      c.text.includes("Куко Unreal")
    ),
  );
});

Deno.test("ADE: the Note scene offers the coded line; no list has a drug line", () => {
  const { slots } = cut();
  assert(
    slot(slots, "note").candidates.some((c) => c.text === NOTE_LINE),
    "a lone М is no drug word",
  );
  for (const s of slots) {
    for (const c of s.candidates) {
      assertEquals(isDrugReference(c.text), false, `${s.slot}: ${c.text}`);
      // Nor a piece of a sentence that has one.
      assertEquals(c.text === "очень необычно", false, s.slot);
    }
  }
});

Deno.test("ADE: titles and headline only in the notes' language", () => {
  const { memory, slots } = cut();
  const language = writtenLanguage(memory);
  assertEquals(language, "ru");
  const names = namesOf(memory);
  for (const s of slots) {
    if (s.kind !== "title" && s.kind !== "headline") continue;
    for (const c of s.candidates) {
      assertEquals(inOtherLanguage(c.text, language, names), false, c.text);
      for (
        const english of [
          "Tallinn airport",
          "coffee shop",
          "back to the roots",
          "morning hangover",
          "some sweets for Elmas",
        ]
      ) {
        assertEquals(c.text === english, false, `${s.slot}: ${c.text}`);
      }
    }
  }
  // Latin event words inside Russian are fine (#454).
  assertEquals(inOtherLanguage("Rave до утра", language, names), false);
  assertEquals(inOtherLanguage("Куко Unreal", language, names), false);
  assertEquals(inOtherLanguage("AMF", language, names), false);
  assertEquals(inOtherLanguage("Tallinn airport", language, names), true);
  // The headline lists its own candidates, several of them.
  const headline = slot(slots, "headline").candidates;
  assert(headline.length >= 3, headline.map((c) => c.text).join(" | "));
  assert(headline.every((c) => c.id.startsWith("h:")));
});

Deno.test("ADE: each list is capped at 8, plus one line of every note it owns", () => {
  const { slots } = cut();
  for (const s of slots) {
    if (s.kind === "card") {
      const notes = new Set(s.candidates.map((c) => c.note_id));
      assert(s.candidates.length <= Math.max(8, notes.size), s.slot);
    } else assert(s.candidates.length <= 8, s.slot);
  }
});

Deno.test("ADE replay: the director's picks hold, Brussels types its line", () => {
  const { report, content } = played();
  for (const r of report) {
    // A director pick, or code's for the film's length only.
    assert(
      r.source === "director" ||
        r.reason.startsWith("a shorter line as good as the pick"),
      `${r.slot}: ${r.reason}`,
    );
  }
  const titles = content.chapters.map((c) => c.title);
  assertEquals(titles[4], "Брюссель");
  for (const t of titles) {
    assert([...t].length <= MAX_NN_TITLE_CHARS, t);
    assertEquals(/^(День|Day) \d/.test(t), false, t);
  }
  assertEquals(content.chapters[4].note, BRUSSELS_LINE);
  assertEquals(content.note?.text, NOTE_LINE);
});

Deno.test("ADE replay: the director may title Brussels itself — free_title is accepted", () => {
  const { memory, heroScores } = adeFilmMemory();
  const picks = adePicks();
  // Over its own pick of "В Брюсель" (a preposition, the note's typo).
  const recorded = picks["ch5.title"].ids;
  picks["ch5.title"] = { ids: recorded, free_title: "Брюссель" };
  const film = neonNightFilm(memory, picks, heroScores);
  const r = film.report.find((x) => x.slot === "ch5.title")!;
  assertEquals(r.source, "director");
  assertEquals(film.content.chapters[4].title, "Брюссель");
  // In English, too long or a day number: code's candidate instead.
  for (const bad of ["Brussels", "Брюссель, пиво и вкусная еда", "День 3"]) {
    picks["ch5.title"] = { ids: [], free_title: bad };
    const t = neonNightFilm(memory, picks, heroScores).report.find((x) =>
      x.slot === "ch5.title"
    )!;
    assertEquals(t.source === "director", false, bad);
  }
});

Deno.test("ADE replay: no words twice, within 75 s", () => {
  const { content } = played();
  const shown = [
    ...content.chapters.flatMap((c) => [
      c.title,
      c.note,
      ...c.moments.flatMap((m) => (m.words ?? []).map((w) => w.text)),
    ]),
    content.note?.text,
  ].filter((t): t is string => !!t);
  for (let i = 0; i < shown.length; i++) {
    for (let j = i + 1; j < shown.length; j++) {
      assertEquals(
        sameLine(shown[i], shown[j]),
        false,
        `${shown[i]} / ${shown[j]}`,
      );
    }
  }
  // The headline may share a name with a title (#454), never a line, nor
  // a title's whole words.
  const headline = content.headline!;
  const titles = content.chapters.map((c) => c.title.toLowerCase());
  assertEquals(titles.includes(headline.toLowerCase()), false);
  for (const line of shown) {
    if (!titles.includes(line.toLowerCase())) {
      assertEquals(sameLine(line, headline), false, line);
    }
  }
  const { shape } = played();
  assert(shape.cardZooms >= 1, "every card keeps a zoom");
  assert(nnBeatsFor(WRAP_UP_LIMITS.longestFilmSeconds) > 0);
});

Deno.test("ADE: titles are names, the card line matches the card's photos (#454)", () => {
  const { slots } = cut();
  for (const s of slots) {
    if (s.kind !== "title") continue;
    for (const k of s.candidates) {
      for (
        const fragment of [
          "сразу пошли завтракать",
          "диджеи не очень",
          "похмелились пора домой",
          "поехали в дом откисать",
        ]
      ) {
        assertEquals(k.text.includes(fragment), false, `${s.slot}: ${k.text}`);
      }
    }
  }
  assert(
    slot(slots, "ch3.title").candidates.some((k) =>
      k.text.includes("Куко Unreal")
    ),
  );
  // Ch1's card opens at Tallinn airport: the airport note leads.
  assert(
    slot(slots, "ch1.card").candidates[0].text.startsWith("Прибыл в аэропорт"),
  );
});

Deno.test("ADE: the headline is upbeat — names and highlights, the director's own words (#454)", () => {
  const { slots } = cut();
  const headline = slot(slots, "headline").candidates.map((k) => k.text);
  for (const name of ["ADE", "AMF", "Куко Unreal"]) {
    assert(headline.includes(name), headline.join(" · "));
  }
  for (
    const low of ["диджеи не очень", "Amsterdam", "Амстердаме", "Сидим", "Петр"]
  ) {
    assertEquals(headline.includes(low), false, low);
  }
  const { memory, heroScores } = adeFilmMemory();
  const picks = adePicks();
  const playing = (free_title: string) => {
    picks.headline = { ids: [], free_title };
    return neonNightFilm(memory, picks, heroScores).report.find((r) =>
      r.slot === "headline"
    )!;
  };
  assertEquals(playing("Самый крутой сет").chosen[0].text, "Самый крутой сет");
  assertEquals(playing("Самый крутой сет").source, "director");
  for (
    const bad of [
      "Диджеи не очень",
      "Самый крутой сет в жизни",
      "Best set ever",
    ]
  ) {
    assertEquals(playing(bad).source === "director", false, bad);
  }
});

Deno.test("ADE replay: the recorded titles and headline play (#454)", () => {
  const { content, report } = played();
  assertEquals(content.chapters.map((c) => c.title), [
    "Амстердам",
    "Полтора метра ребер",
    "На Куко Unreal",
    "AMF под ливнем",
    "Брюссель",
  ]);
  // A headline may share a name with a title, never be the same words.
  assertEquals(content.headline, "Куко Unreal");
  assertEquals(report.find((r) => r.slot === "headline")!.source, "director");
});
