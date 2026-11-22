import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { buildGvSkeleton } from "./gv_skeleton.ts";
import {
  buildGvSlots,
  gvChapterLine,
  gvDayTitle,
  type GvSlot,
  gvUnlistedNotes,
  resolveGvSlots,
} from "./gv_slots.ts";
import { namesOf, scopedId, type SlotPicks } from "./film_slots.ts";
import { gvHeroScores, gvMemory } from "./gv_fixtures.ts";
import type { TripData } from "./gather.ts";

function album(data: TripData = gvMemory()) {
  const skeleton = buildGvSkeleton(data, gvHeroScores());
  const slots = buildGvSlots(data, skeleton, "en");
  const resolve = (picks: SlotPicks | null) =>
    resolveGvSlots(slots, picks, {
      language: "ru",
      names: namesOf(data),
      dayTitle: (i) => gvDayTitle(data, skeleton, i, "ru"),
      shown: [data.trip.name, data.trip.destination ?? ""],
    });
  return { data, skeleton, slots, resolve };
}

const slotOf = (slots: GvSlot[], name: string) =>
  slots.find((s) => s.slot === name)!;
const texts = (slot: GvSlot) => slot.candidates.map((c) => c.text);

Deno.test("a captioned main page shows its caption, as written", () => {
  const { skeleton, slots, resolve } = album();
  const k = skeleton.mains.findIndex((m) => m.photo_id === "g07");
  const note = slotOf(slots, `main${k + 1}.note`);
  assert(note.fixed);
  assertEquals(texts(note), ["Эйфелева башня"]);
  // Whatever the director picks.
  const other = slotOf(slots, "main1.note").candidates[0].id;
  const r = resolve({ [note.slot]: { ids: [scopedId(note.slot, other)] } });
  assertEquals(r.get(note.slot)!.chosen.map((c) => c.text), ["Эйфелева башня"]);
});

Deno.test("a main page lists only its own notes' lines", () => {
  const { data, skeleton, slots } = album();
  const notesOf = (k: number) =>
    new Set(
      slotOf(slots, `main${k + 1}.note`).candidates.map((c) => c.note_id),
    );
  skeleton.mains.forEach((m, k) => {
    if (slotOf(slots, `main${k + 1}.note`).fixed) return;
    for (const id of notesOf(k)) {
      const n = data.notes.find((x) => x.id === id)!;
      // The note's chapter is the page's: its day, near its photos.
      const ch = skeleton.chapters[m.chapter];
      assert(ch.days.includes(n.day_date), `${id} on main${k + 1}`);
    }
  });
  // The morning note on the morning page, the sunset note on the last.
  assertEquals(notesOf(0), new Set(["n1"]));
  assert(notesOf(skeleton.mains.length - 1).has("n5"));
});

Deno.test("no wedding words when it isn't a wedding", () => {
  const wedding = /свадьб|клятв|кольц|поженил|wedding|vows/iu;
  for (const s of album().slots) {
    for (const t of texts(s)) assert(!wedding.test(t), `${s.slot}: ${t}`);
  }
  const w = album(gvMemory({ wedding: true }));
  assert(texts(slotOf(w.slots, "occasion")).some((t) => wedding.test(t)));
});

Deno.test("without picks every slot plays code's choice, no words twice", () => {
  const { resolve } = album();
  const r = resolve(null);
  const shown = [...r.values()].flatMap((x) => x.chosen.map((c) => c.text));
  const norm = (t: string) =>
    t.toLowerCase().replace(/[^\p{L}]+/gu, " ").trim();
  assertEquals(new Set(shown.map(norm)).size, shown.length);
  for (const [slot, x] of r) {
    assertEquals(x.chosen.length, 1, slot);
    if (!slot.endsWith(".note") || !x.reason.includes("caption")) {
      assertEquals(x.source, "code", slot);
    }
  }
  // Never the memory's name or place again.
  assert(!shown.includes("Париж"));
  assert(!shown.includes("Париж вдвоём"));
});

Deno.test("a pick holds only in its own slot's list", () => {
  const { slots, resolve } = album();
  const label = slotOf(slots, "main1.label");
  const title = slotOf(slots, "ch2.title");
  // Its last candidate: one nothing else takes.
  const second = label.candidates[label.candidates.length - 1];
  const r = resolve({
    "main1.label": { ids: [scopedId(label.slot, second.id)] },
    // ch2.title picks main1.label's id: not in its list.
    "ch2.title": { ids: [scopedId(label.slot, label.candidates[2].id)] },
  });
  assertEquals(r.get("main1.label")!.source, "director");
  assertEquals(r.get("main1.label")!.chosen[0].text, second.text);
  const t = r.get("ch2.title")!;
  assertEquals(t.source, "code");
  // What code plays with no picks at all.
  assertEquals(
    t.chosen[0].text,
    resolve(null).get("ch2.title")!.chosen[0].text,
  );
  assert(title.candidates.length > 0);
  assert(t.reason.includes("valid only there"), t.reason);
});

Deno.test("the director's own words, checked", () => {
  const { resolve } = album();
  const free = (slot: string, text: string) =>
    resolve({ [slot]: { ids: [], free_title: text } }).get(slot)!;
  assertEquals(
    free("ch1.title", "Утро на Сене").chosen[0].text,
    "Утро на Сене",
  );
  assertEquals(free("ch1.title", "Утро на Сене").source, "director");
  // Too long, a clock time, another language, a complaint at the end.
  for (
    const [slot, text] of [
      ["ch1.title", "Самое длинное утро нашей жизни в Париже"],
      ["ch1.title", "10:05"],
      ["ch1.title", "Morning by the river"],
      ["finale", "Устали и замёрзли"],
    ]
  ) {
    const r = free(slot, text);
    assertEquals(r.source, "code", `${slot}: ${text}`);
    assert(r.chosen[0].text !== text);
  }
});

Deno.test("a title nothing fits is the day", () => {
  const data = gvMemory();
  data.notes = [];
  for (const p of data.photos) {
    p.caption = null;
    p.place_text = null;
  }
  const { resolve } = album(data);
  const r = resolve(null);
  assertEquals(
    ["ch1.title", "ch2.title", "ch3.title"].map((s) =>
      r.get(s)!.chosen[0].text
    ),
    ["День 1", "День 1 · вечер", "День 2"],
  );
});

Deno.test("chapter eyebrows: number and part of the day", () => {
  const { skeleton } = album();
  assertEquals(
    skeleton.chapters.map((c, i) => gvChapterLine(c.photos, i, "ru", 120)),
    ["Глава первая · Утро", "Глава вторая · Вечер", "Глава третья · Утро"],
  );
});

Deno.test("notes on no page say why", () => {
  const { data, skeleton, slots } = album();
  assertEquals(gvUnlistedNotes(data, skeleton, slots), [{
    note_id: "n4",
    text: "Было хорошо.",
    reason: "only generic lines, and its page has a specific one",
  }]);
});
