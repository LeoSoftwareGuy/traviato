// Neon Night's slots and their resolution (#454): code lists candidates
// with ids, the director only picks ids, and validation is "is this id in
// this slot's list" — else the slot's top candidate.
import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  buildNeonPickInput,
  buildNeonPickSystemPrompt,
  freeTitleProblem,
  hasVerb,
  inOtherLanguage,
  MAX_NN_CANDIDATES,
  namePhrases,
  type NnCandidate,
  type NnSlot,
  noteChapters,
  parseNeonPicks,
  resolveNeonSlots,
  type ResolveOptions,
} from "./neon_slots.ts";
import { neonNightFilm } from "./neon_film.ts";
import { clausesOf, isDrugReference } from "./excerpts.ts";
import { directorTripData } from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";
import { useFilmLengthRuleForTests } from "./film_length.ts";

useFilmLengthRuleForTests(false);

const c = (id: string, text: string, score = 10): NnCandidate => ({
  id,
  text,
  note_id: id.startsWith("n:") ? id.split(":")[1] : null,
  photo_id: null,
  score,
});

const slot = (
  name: string,
  kind: NnSlot["kind"],
  candidates: NnCandidate[],
  chapter: number | null = 0,
): NnSlot => ({
  slot: name,
  kind,
  chapter,
  moment: null,
  max_picks: 1,
  candidates,
});

const options = (o: Partial<ResolveOptions> = {}): ResolveOptions => ({
  shownCaptions: [],
  language: "ru",
  names: new Set(),
  moments: new Map(),
  dayTitle: (i) => `День ${i + 1}`,
  ...o,
});

Deno.test("a pick in the slot's list plays; an id off it takes the top candidate", () => {
  const slots = [
    slot("ch1.card", "card", [
      c("n:a:1", "Взяли полтора метра рёбер", 30),
      c("n:a:2", "Пиво было отличное", 20),
    ]),
  ];
  const good = resolveNeonSlots(
    slots,
    { "ch1.card": { ids: ["n:a:2"] } },
    options(),
  ).get("ch1.card")!;
  assertEquals(good.source, "director");
  assertEquals(good.chosen[0].text, "Пиво было отличное");

  const bad = resolveNeonSlots(
    slots,
    { "ch1.card": { ids: ["n:zz:9"] } },
    options(),
  ).get("ch1.card")!;
  assertEquals(bad.source, "code");
  assertEquals(bad.chosen[0].text, "Взяли полтора метра рёбер");
  assertStringIncludes(bad.reason, "n:zz:9: not in this slot's list");
});

Deno.test("an id is used once in the film: a second pick of it gives way", () => {
  const line = c("n:a:1", "Взяли полтора метра рёбер", 30);
  const slots = [
    slot("note", "note", [line], null),
    slot("ch1.card", "card", [line, c("n:b:1", "Пиво было отличное", 20)]),
  ];
  const r = resolveNeonSlots(
    slots,
    { note: { ids: ["n:a:1"] }, "ch1.card": { ids: ["n:a:1"] } },
    options(),
  );
  assertEquals(r.get("note")!.chosen[0].id, "n:a:1");
  assertEquals(r.get("ch1.card")!.chosen[0].id, "n:b:1");
  assertStringIncludes(r.get("ch1.card")!.reason, "already shows");
});

Deno.test("no words twice: a line never repeats a shown caption; a title never a line", () => {
  const slots = [
    slot("ch1.card", "card", [
      c("n:a:1", "Кофешоп на углу канала", 30),
      c("n:a:2", "Пиво было отличное", 20),
    ]),
    slot("ch1.title", "title", [
      c("n:a:3", "Пиво было отличное", 30),
      c("p:1", "Амстердам", 10),
    ]),
  ];
  const r = resolveNeonSlots(
    slots,
    null,
    options({ shownCaptions: ["Кофешоп на углу канала"] }),
  );
  assertEquals(r.get("ch1.card")!.chosen[0].text, "Пиво было отличное");
  assertEquals(r.get("ch1.title")!.chosen[0].text, "Амстердам");
});

Deno.test("free_title: only for a title, checked, first when it holds", () => {
  const slots = [slot("ch1.title", "title", [c("p:1", "Amsterdam", 10)])];
  const free = (free_title: string, ids: string[] = []) =>
    resolveNeonSlots(slots, { "ch1.title": { ids, free_title } }, options())
      .get("ch1.title")!;
  assertEquals(free("Брюссель").chosen[0].text, "Брюссель");
  assertEquals(free("Брюссель").source, "director");
  // A free title that holds wins over an id: the director writes one
  // whenever it names the chapter better (#454).
  assertEquals(free("Брюссель", ["p:1"]).chosen[0].text, "Брюссель");
  // One that doesn't hold: the director's id.
  assertEquals(free("Brussels", ["p:1"]).chosen[0].text, "Amsterdam");
  for (
    const bad of [
      "Брюссель, пиво и вкусная еда навсегда", // > 22
      "Brussels", // not the notes' language
      "День 2",
      "23:15",
    ]
  ) {
    assertEquals(free(bad).source === "director", false, bad);
  }
  assert(freeTitleProblem("A".repeat(23), options()));
  assertEquals(freeTitleProblem("Rave до утра", options()), null);
  // A free title is never a card's or a moment's line.
  const card = resolveNeonSlots(
    [slot("ch1.card", "card", [c("n:a:1", "Пиво было отличное")])],
    { "ch1.card": { ids: [], free_title: "Брюссель" } },
    options(),
  ).get("ch1.card")!;
  assertEquals(card.chosen[0].text, "Пиво было отличное");
});

Deno.test("a title nothing fits is plain Day N", () => {
  const r = resolveNeonSlots(
    [slot("ch2.title", "title", [], 1)],
    null,
    options(),
  );
  assertEquals(r.get("ch2.title")!.chosen[0].text, "День 2");
});

Deno.test("parseNeonPicks: junk is no picks; slots keep their ids", () => {
  for (const junk of [null, "x", 3, {}, { picks: "none" }]) {
    const p = parseNeonPicks(junk);
    assert(p === null || Object.keys(p).length === 0, JSON.stringify(junk));
  }
  assertEquals(
    parseNeonPicks({
      picks: [{ slot: "ch1.card", ids: ["n:a:1"], free_title: null }],
    })?.["ch1.card"].ids,
    ["n:a:1"],
  );
});

Deno.test("the script check works by words: Latin event names are fine in Russian", () => {
  const names = new Set<string>();
  assertEquals(inOtherLanguage("Rave до утра", "ru", names), false);
  assertEquals(inOtherLanguage("Куко Unreal", "ru", names), false);
  assertEquals(inOtherLanguage("Tallinn airport", "ru", names), true);
  assertEquals(inOtherLanguage("coffee shop", "ru", names), true);
  // A word the notes use is the user's own.
  assertEquals(inOtherLanguage("AMF", "ru", new Set(["amf"])), false);
});

Deno.test("drugs: explicit words are blocked, a lone М is not", () => {
  assert(isDrugReference("Покурили косячок и пошли гулять"));
  assert(isDrugReference("Взяли бомбочки на вечер"));
  assertEquals(
    isDrugReference("Это самый крутой сет который я слышал или это М?"),
    false,
  );
  // "4,5" is no clause break; a comma before a word is.
  assertEquals(clausesOf("Заказали 4,5 кг рёбер"), ["Заказали 4,5 кг рёбер"]);
  assertEquals(
    clausesOf("Тусили всю ночь до самого утра,сначало были на Куко"),
    ["Тусили всю ночь до самого утра", "сначало были на Куко"],
  );
});

// One day, two parts: 12:00–14:00 and, after a break, 20:00–22:00.
function twoParts(): TripData {
  const base = directorTripData().photos[0];
  const photos = [12, 12.5, 13, 13.5, 14, 20, 20.5, 21, 21.5, 22].map((
    h,
    k,
  ) => ({
    ...base,
    id: `t${k}`,
    day_date: k < 5 ? "2026-09-02" : "2026-09-02",
    taken_at: `2026-09-02T${String(Math.floor(h)).padStart(2, "0")}:${
      h % 1 ? "30" : "00"
    }:00Z`,
    storage_path: `u/t/t${k}.jpg`,
    caption: null,
    place_text: null,
    use_in_wrap_up: null,
  }));
  const day1 = [10, 11, 12, 13, 14].map((h, k) => ({
    ...base,
    id: `y${k}`,
    day_date: "2026-09-01",
    taken_at: `2026-09-01T${h}:00:00Z`,
    storage_path: `u/t/y${k}.jpg`,
    caption: null,
    place_text: null,
    use_in_wrap_up: null,
  }));
  return directorTripData({
    trip: {
      ...directorTripData().trip,
      start_date: "2026-09-01",
      end_date: "2026-09-02",
    },
    photos: [...day1, ...photos],
    notes: [
      {
        id: "late",
        day_date: "2026-09-02",
        taken_at: "2026-09-02T23:40:00Z",
        photo_id: null,
        content: "Danced at Shelter until 3 with the whole crew.",
      },
      {
        id: "lunch",
        day_date: "2026-09-02",
        taken_at: "2026-09-02T15:10:00Z",
        photo_id: null,
        content: "Ribs at Café de Klos, 3 plates between us.",
      },
      {
        id: "yesterday",
        day_date: "2026-09-02",
        taken_at: "2026-09-02T09:00:00Z",
        photo_id: null,
        content: "Yesterday we rented 3 bikes and rode 12 km.",
      },
      {
        id: "onphoto",
        day_date: "2026-09-02",
        taken_at: "2026-09-02T23:50:00Z",
        photo_id: "t1",
        content: "The best ribs of my life at the market.",
      },
    ],
  });
}

Deno.test("note → chapter: its photo's, else the nearest part; after the last photo the last; yesterday stays on its Journal day", () => {
  const data = twoParts();
  const { chapters } = neonNightFilm(data, null);
  assertEquals(chapters.length, 3);
  const owners = noteChapters(data, chapters);
  // On a photo: that photo's chapter, whenever it was written.
  assertEquals(owners.get("onphoto"), [1]);
  // Written after the lunch part, before the evening: the nearest.
  assertEquals(owners.get("lunch"), [1]);
  // Written after the day's last photo: its last part.
  assertEquals(owners.get("late"), [2]);
  // "Yesterday…" stays on its Journal day (#468): never the day before.
  assertEquals(owners.get("yesterday")?.every((i) => i > 0), true);
});

Deno.test("a backfilled note goes by what it says, within its own Journal day (#468)", () => {
  const data = twoParts();
  // The evening part shows the canal; the lunch part the café.
  data.photos = data.photos.map((p) => ({
    ...p,
    summary: p.id === "t7"
      ? "Boats on a canal at night"
      : p.id === "t1"
      ? "Plates of ribs on a café table"
      : "A street",
  }));
  data.notes = [
    {
      id: "canal",
      day_date: "2026-09-02",
      // Typed two months later.
      taken_at: "2026-11-20T18:00:00Z",
      photo_id: null,
      content: "The canal boats at night were the best part.",
    },
    {
      id: "ribs",
      day_date: "2026-09-02",
      taken_at: "2026-11-20T18:05:00Z",
      photo_id: null,
      content: "Ribs at the café, three plates between us.",
    },
    {
      id: "nothing",
      day_date: "2026-09-02",
      taken_at: "2026-11-20T18:10:00Z",
      photo_id: null,
      content: "Slept so well.",
    },
  ];
  const { chapters } = neonNightFilm(data, null);
  const owners = noteChapters(data, chapters);
  assertEquals(owners.get("canal"), [2]);
  assertEquals(owners.get("ribs"), [1]);
  // Nothing matches: the day's first part — never day 1.
  assertEquals(owners.get("nothing"), [1]);
});

Deno.test("every list is capped at 8 (a card keeps one line of each note it owns)", () => {
  const data = twoParts();
  data.notes.push(...Array.from({ length: 12 }, (_, k) => ({
    id: `x${k}`,
    day_date: "2026-09-02",
    taken_at: "2026-09-02T21:00:00Z",
    photo_id: null,
    content: `We tried bar number ${k + 1} on the canal, ${k + 2} beers in.`,
  })));
  const { slots } = neonNightFilm(data, null);
  for (const s of slots) {
    if (s.kind === "card") {
      const notes = new Set(s.candidates.map((x) => x.note_id)).size;
      assert(s.candidates.length <= Math.max(MAX_NN_CANDIDATES, notes));
    } else assert(s.candidates.length <= MAX_NN_CANDIDATES, s.slot);
  }
});

Deno.test("ids are scoped to their slot: one from another slot's list is refused", () => {
  const slots = [
    slot("ch1.m1", "moment", [c("n:a:1", "Взяли полтора метра рёбер", 30)]),
    slot("ch2.card", "card", [c("n:b:1", "Пиво было отличное", 20)], 1),
  ];
  const r = resolveNeonSlots(
    slots,
    {
      "ch1.m1": { ids: ["ch1.m1/n:a:1"] },
      "ch2.card": { ids: ["ch1.m1/n:a:1"] },
    },
    options(),
  );
  assertEquals(r.get("ch1.m1")!.source, "director");
  assertEquals(r.get("ch2.card")!.source, "code");
  assertStringIncludes(r.get("ch2.card")!.reason, "from ch1.m1's list");
  // The director sees every id with its slot's name.
  const data = directorTripData();
  const { chapters, slots: real } = neonNightFilm(data, null);
  const input = buildNeonPickInput(data, chapters, real, new Map(), () => null);
  for (const s of input.slots) {
    for (const k of s.candidates) assert(k.id.startsWith(`${s.slot}/`), k.id);
  }
  const prompt = buildNeonPickSystemPrompt("ru");
  assertStringIncludes(prompt, "valid only in that slot");
  assertStringIncludes(prompt, "a title names the chapter");
  assertStringIncludes(prompt, "Write free_title whenever it's better");
  assertStringIncludes(prompt, "starts with a preposition, has a typo");
  assertStringIncludes(prompt, "never a ");
  assertStringIncludes(prompt, "complaint or a low");
});

Deno.test("titles name things: names from the notes, never a verb fragment", () => {
  assertEquals(
    namePhrases("Приземлились в Амстердаме и сразу пошли завтракать."),
    ["В Амстердаме"],
  );
  assertEquals(namePhrases("Брюссель не меняется, отличное пиво."), [
    "Брюссель",
  ]);
  assertEquals(namePhrases("Вчера сначало были на Куко Unreal до утра."), [
    "На Куко Unreal",
  ]);
  assertEquals(namePhrases("Выезжаем на AMF тусовку под ливнем"), ["На AMF"]);
  // A lowercase Latin word names nothing; a lone letter neither.
  assertEquals(namePhrases("смотрим ufc и это М?"), []);
  for (
    const fragment of [
      "сразу пошли завтракать",
      "поехали в дом откисать",
      "похмелились пора домой",
      "we went home",
    ]
  ) {
    assert(hasVerb(fragment), fragment);
  }
  for (
    const name of [
      "Куко Unreal",
      "Амстердам",
      "Пиво",
      "Брюссель",
      "coffee shop",
    ]
  ) {
    assertEquals(hasVerb(name), false, name);
  }
});
