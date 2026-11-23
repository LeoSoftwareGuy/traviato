// The first real Golden Vows run (#460) on its exported memory: time
// order, names as written, real labels, photos on pages.
import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  budapestFilmMemory,
  budapestFreeTexts,
  budapestHeroScores,
  budapestOrientations,
  budapestSummaries,
} from "./budapest_birthday.ts";
import { goldenVowsFilm, gvShortestSeconds } from "./gv_film.ts";
import { gvNoteHomes, gvPartOf, gvPartOfTime } from "./gv_slots.ts";
import type { SlotPicks } from "./film_slots.ts";
import { timeOf } from "./neon_night.ts";
import { assertPlayOrder } from "./gv_fixtures.ts";
import { MAX_GV_CAPTION_LABEL_CHARS } from "./golden_vows.ts";

const OFFSET = 120;

function film(picks: SlotPicks | null = null) {
  const data = budapestFilmMemory();
  return {
    data,
    ...goldenVowsFilm(data, picks, {
      heroScores: budapestHeroScores(),
      summaries: budapestSummaries(),
      orientations: budapestOrientations(),
      language: "en",
    }),
  };
}

// The note a slot's played candidate is from, if any.
const noteOf = (f: ReturnType<typeof film>, slot: string) => {
  const id = f.report.find((r) => r.slot === slot)!.chosen[0]?.id;
  return f.slots.find((s) => s.slot === slot)!.candidates
    .find((c) => c.id === id)?.note_id ?? null;
};

// Every word the album shows.
const shownTexts = (f: ReturnType<typeof film>) => {
  const c = f.content;
  return [
    c.occasion_line,
    c.end_line,
    c.carousel?.title ?? "",
    ...c.heroes.flatMap((h) => [h.label, h.note ?? ""]),
    ...c.chapters.map((ch) => ch.title),
  ].filter(Boolean);
};

Deno.test("Budapest: every page in time order, each main page in its chapter", () => {
  for (const picks of [null, budapestFreeTexts()]) {
    const f = film(picks);
    assertPlayOrder(f.data, f.content, f.skeleton.mains.map((m) => m.chapter));
    for (const m of f.skeleton.mains) {
      assert(
        f.skeleton.chapters[m.chapter].photos.some((p) => p.id === m.photo_id),
      );
    }
    // One chapter a logical day with photos: never merged.
    assertEquals(f.skeleton.chapters.map((c) => c.days), [
      ["2026-02-26"],
      ["2026-02-27"],
      ["2026-02-27"],
      ["2026-02-28"],
    ]);
  }
});

Deno.test("Budapest: names exactly as written, never «Elma's»", () => {
  const f = film(budapestFreeTexts());
  const occasion = f.report.find((r) => r.slot === "occasion")!;
  assertEquals(occasion.source, "code");
  assertStringIncludes(occasion.reason, "changes the name");
  for (const t of shownTexts(f)) {
    assert(!/elma['’]s/iu.test(t), t);
    for (const m of t.matchAll(/\belmas\b/giu)) assertEquals(m[0], "Elmas", t);
  }
  assert(shownTexts(f).some((t) => t.includes("Elmas")));
  // A name the user never wrote, or words only the photo descriptions
  // say, never play either.
  for (
    const [text, why] of [
      ["Anna's birthday", "a name the user never wrote"],
      ["Twin towers", "only in the photo descriptions"],
    ]
  ) {
    const r = film({ "ch2.title": { ids: [], free_title: text } }).report
      .find((x) => x.slot === "ch2.title")!;
    assertEquals(r.source, "code", text);
    assertStringIncludes(r.reason, why);
  }
});

Deno.test("Budapest: no generic labels, no time beside a caption", () => {
  const f = film();
  const byId = new Map(f.data.photos.map((p) => [p.id, p]));
  for (const h of f.content.heroes) {
    const caption = byId.get(h.photo_id)!.caption?.trim();
    if (caption) assertEquals(h.taken_at, null, h.photo_id);
    if (!h.label) continue;
    // The caption, else a phrase of the user's own notes.
    assert(
      h.label === caption ||
        f.data.notes.some((n) =>
          n.content.toLowerCase().includes(h.label.toLowerCase())
        ),
      h.label,
    );
    assert([...h.label].length <= MAX_GV_CAPTION_LABEL_CHARS);
    // Never its page's note again.
    assert(!h.note?.toLowerCase().includes(h.label.toLowerCase()), h.label);
  }
});

Deno.test("Budapest: most photos on pages, within 75 s", () => {
  const f = film();
  assert(
    f.shown.pages >= 0.7 * f.shown.photos,
    `${f.shown.pages} / ${f.shown.photos}`,
  );
  assert(gvShortestSeconds(f.content) <= 75);
  // A long album trims only past 75 s: its second pages first.
  assert(f.trims.every((t) => t.endsWith("one page of prints")), `${f.trims}`);
});

Deno.test("Budapest: each note line on the page it belongs to", () => {
  const f = film();
  const homes = gvNoteHomes(f.data, f.skeleton);
  f.content.heroes.forEach((h, k) => {
    const noteId = noteOf(f, `main${k + 1}.note`);
    if (!h.note || !noteId) return;
    assertEquals(homes.get(noteId), { main: k }, `main${k + 1}: ${h.note}`);
  });
  // A page of prints: its own note; a second page (or a chapter's only
  // page) another line of its chapter — never the eyebrow again.
  f.content.chapters.forEach((c, i) => {
    const noMain = !f.skeleton.mains.some((m) => m.chapter === i);
    c.pages!.forEach((pg, k) => {
      const noteId = noteOf(f, `ch${i + 1}.p${k + 1}.note`);
      if (!pg.note || !noteId) return;
      const home = homes.get(noteId);
      if (k > 0 || noMain) {
        assert(typeof home === "object", pg.note);
        const chapter = "main" in home
          ? f.skeleton.mains[home.main].chapter
          : home.chapter;
        assertEquals(chapter, i, pg.note);
      } else {
        assertEquals(home, { chapter: i, page: k }, pg.note);
      }
    });
  });
  // The café line with the café photo, the birthday on the spa.
  const pageOf = (text: string) => {
    const hero = f.content.heroes.find((h) => h.note?.includes(text));
    if (hero) return [hero.photo_id];
    return f.content.chapters.flatMap((c) => c.pages!)
      .find((pg) => pg.note?.includes(text))?.photo_ids ?? [];
  };
  assert(pageOf("golden coffee").some((id) => id.startsWith("25661a")));
  assert(pageOf("Elmas birthday").some((id) => id.startsWith("133bbd")));
});

Deno.test("Budapest: no photo twice; a 2-photo day is its page of 2 with a line", () => {
  const f = film();
  const shown = [
    ...f.content.heroes.map((h) => h.photo_id),
    ...f.content.chapters.flatMap((c) => c.pages!.flatMap((p) => p.photo_ids)),
    ...(f.content.carousel?.photo_ids ?? []),
  ];
  assertEquals(new Set(shown).size, shown.length);
  const day1 = f.content.chapters[0];
  assertEquals(day1.pages!.map((p) => [p.layout, p.photo_ids.length]), [
    ["B2", 2],
  ]);
  assert(!f.skeleton.mains.some((m) => m.chapter === 0));
  assertStringIncludes(day1.pages![0].note!, "Tallinn to Budapest");
});

Deno.test("Budapest: a second page never repeats the eyebrow", () => {
  const f = film();
  for (const c of f.content.chapters) {
    for (const pg of c.pages!.slice(1)) {
      assert(pg.note !== c.line);
      if (pg.note) assert(!pg.note.startsWith("Chapter"), pg.note);
    }
  }
});

Deno.test("Budapest: each chapter's time of day is most of its photos'", () => {
  const f = film();
  const words = ["Morning", "Afternoon", "Evening", "Night"];
  f.skeleton.chapters.forEach((c, i) => {
    const counts = [0, 0, 0, 0];
    // Each photo on Budapest's clock (#461), not the phone's +120.
    for (const p of c.photos) {
      counts[gvPartOfTime(timeOf(p), p.utc_offset_minutes ?? OFFSET)]++;
    }
    const most = Math.max(...counts);
    const part = gvPartOf(c.photos, OFFSET)!;
    assertEquals(counts[part], most, `chapter ${i + 1}`);
    assert(f.content.chapters[i].line.endsWith(words[part]));
  });
});

Deno.test("Budapest: no title from another day's note while its own day has one", () => {
  const f = film();
  const dayOf = new Map(f.data.notes.map((n) => [n.id, n.day_date]));
  f.skeleton.chapters.forEach((c, i) => {
    const slot = f.slots.find((x) => x.slot === `ch${i + 1}.title`)!;
    const own = slot.candidates.some((k) =>
      k.note_id && c.days.includes(dayOf.get(k.note_id)!)
    );
    const chosen = noteOf(f, slot.slot);
    if (own && chosen) {
      assert(
        c.days.includes(dayOf.get(chosen)!),
        `ch${i + 1}: ${f.content.chapters[i].title}`,
      );
    }
  });
  // The birthday chapter is titled from its own day, not the last day's
  // actor.
  assertEquals(f.content.chapters[3].title, "Famous spas");
  assert(
    !shownTexts(f).some((t) => t.includes("Travis Fimmel") && t.length < 30),
  );
});
