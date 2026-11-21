// ADE-Amsterdam (#448): the storyboard after #445/#447 ran 91 s against
// a 51.6 s target — 7 captions in one timeline, a card of 1 photo, four
// card-only chapters, lines and the Note scene gone, a clock title, a
// line twice. Its shape, played through the real content builder.
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { ADE_LASER, adeDirectorPlan, adeMemory } from "./ade_fixture.ts";
import {
  buildNeonNightContent,
  MAX_NN_MOMENT_WORDS,
  type NeonNightPlan,
  nnCheckContext,
  overlaps,
  repairNeonNight,
  sameLine,
} from "./neon_night.ts";
import { withFilmPhotos } from "./film_photos.ts";
import { nnBeatsFor, nnMomentBeats } from "./film_length.ts";

function ade() {
  const memory = withFilmPhotos(adeMemory(), {});
  return {
    memory,
    // The director's plan as it came back, repaired (#450).
    content: buildNeonNightContent(
      memory,
      repairNeonNight(
        adeDirectorPlan(),
        nnCheckContext(memory),
      ) as NeonNightPlan,
    ),
  };
}

Deno.test("ADE: 5 chapters, Brussels its own, the laser shot in a scene", () => {
  const { content } = ade();
  assertEquals(content.chapters.length, 5);
  const last = content.chapters[4];
  assertEquals(last.photos.map((p) => p.id), ["b1", "b2", "b3", "b4"]);
  const shown = new Set(
    content.chapters.flatMap((c) => [
      ...c.card_photo_ids,
      ...c.moments.flatMap((m) => m.photo_ids),
    ]),
  );
  assert(shown.has(ADE_LASER), "the laser shot");
  assert(shown.size >= 0.7 * 27, `${shown.size} / 27 shown`);
});

Deno.test("ADE: full cards, a moment from 5 photos, ≤ 3 words and ~12 s a scene", () => {
  const { content } = ade();
  for (const c of content.chapters) {
    assert(c.card_photo_ids.length >= 3, `${c.title}: card`);
    if (c.photos.length >= 5) assert(c.moments.length >= 1, c.title);
    for (const m of c.moments) {
      const words = m.words ?? [];
      assert(words.length <= MAX_NN_MOMENT_WORDS, `${c.title}: words`);
      for (const w of words) assert(m.photo_ids.includes(w.photo_id));
      const beats = nnMomentBeats({
        type: m.type as "split" | "burst" | "timeline",
        photos: m.photo_ids.length,
        lines: words.map((w) => w.text),
      });
      assert(beats <= nnBeatsFor(12) + 4, `${c.title}: ${beats} beats`);
      if (m.type === "timeline") assert(m.photo_ids.length <= 6);
    }
  }
});

Deno.test("ADE: every chapter with notes shows a line; the Note scene is there", () => {
  const { content } = ade();
  assert(content.note !== null, "the Note scene");
  const played = content.chapters.map((c) => [
    ...(c.note ? [c.note] : []),
    ...c.moments.flatMap((m) => (m.words ?? []).map((w) => w.text)),
  ]);
  // Ribs, Kuko, UFC/AMF and Brussels have notes; the airport has none.
  // Each shows one of its lines — on its card, in a moment, or as the
  // Note scene.
  const captions = new Set(memoryCaptions());
  content.chapters.forEach((c, i) => {
    const own = [
      ...c.excerpts.map((e) => e.text),
      ...(c.rejected_excerpts ?? []).map((e) => e.text),
    ];
    // The airport's only note was written after landing in Amsterdam: it
    // never plays over the Tallinn photos (#450).
    if (i === 0) {
      assert(!(c.note ?? "").startsWith("Приземлились"), "not over Tallinn");
      return;
    }
    if (own.length === 0) return;
    const lines = played[i].filter((t) => !captions.has(t));
    assert(
      lines.length > 0 || own.some((t) => sameLine(t, content.note!.text)),
      `${c.title}: a line`,
    );
  });
  assert(
    played.flat().some((t) => t.includes("4,5 кг рёбер")),
    "the ribs line",
  );
  assert(
    played.flat().some((t) => t.startsWith("Брюссель не меняется")),
    "the Brussels line",
  );
});

function memoryCaptions(): string[] {
  return adeMemory().photos.map((p) => p.caption ?? "").filter((c) => c);
}

Deno.test("ADE: every card zooms; ≤ 75 s leaves at least one zoom (#448)", () => {
  const { content } = ade();
  for (const c of content.chapters) {
    assert((c.card_zooms ?? 2) >= 1, `${c.title}: a zoom`);
  }
});

Deno.test("ADE: no clock titles, titles in the notes' language", () => {
  const { content } = ade();
  for (const c of content.chapters) {
    assert(!/^\d{1,2}:\d{2}$/.test(c.title), c.title);
    assert(/[Ѐ-ӿ]/.test(c.title), `${c.title}: Russian`);
  }
  assertEquals(
    new Set(content.chapters.map((c) => c.title)).size,
    content.chapters.length,
    "no title twice",
  );
});

Deno.test("ADE: no line appears twice in one film", () => {
  const { content } = ade();
  const all = [
    ...content.chapters.flatMap((c) => [
      ...(c.note ? [c.note] : []),
      ...c.moments.flatMap((m) => (m.words ?? []).map((w) => w.text)),
    ]),
    ...(content.note ? [content.note.text] : []),
  ];
  for (let i = 0; i < all.length; i++) {
    for (let j = i + 1; j < all.length; j++) {
      assert(!overlaps(all[i], all[j]), `"${all[i]}" twice`);
    }
  }
});

Deno.test("ADE: the user's own profane caption shows as written", () => {
  const { content } = ade();
  const words = content.chapters.flatMap((c) =>
    c.moments.flatMap((m) => (m.words ?? []).map((w) => w.text))
  );
  const titles = content.chapters.map((c) => c.title);
  assert(!titles.includes("охуенный сет"), "never a title");
  assert(
    words.includes("охуенный сет") ||
      content.chapters.some((c) => c.card_photo_ids.includes("k4")),
    "shown on its photo",
  );
});

Deno.test("ADE: director titles fit their own chapter, whole, in Russian, not the headline (#450)", () => {
  const { content } = ade();
  const titles = content.chapters.map((c) => c.title);
  for (const bad of ["Tallinn airport", "4.5kg ribs then Куко"]) {
    assert(!titles.includes(bad), `${bad}: in English`);
  }
  for (const t of titles) {
    assert(!t.startsWith("Куко Unreal"), `${t}: cut or on the wrong day`);
    assert(!sameLine(t, content.headline ?? "-"), `${t}: the headline`);
  }
  assert(!titles.some((t) => t.startsWith("some sweets")), "Brussels");
  assertEquals(titles[4], "Брюссель");
});

Deno.test("ADE: Brussels types its specific line, never the morning's (#450)", () => {
  const { content } = ade();
  const brussels = content.chapters[4];
  assertEquals(
    brussels.note,
    "Брюссель не меняется отличное пиво и вкусная еда.",
  );
  const all = content.chapters.flatMap((c) => [
    c.note ?? "",
    ...c.moments.flatMap((m) => (m.words ?? []).map((w) => w.text)),
  ]);
  assert(!all.some((t) => t.startsWith("Проснулись")), "no generic line");
  assert(!all.some((t) => /[,;:]$/.test(t)), "no trailing comma");
});
