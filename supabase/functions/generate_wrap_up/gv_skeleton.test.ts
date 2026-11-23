import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { buildGvSkeleton, gvOccasionOf } from "./gv_skeleton.ts";
import { gvHeroScores, gvMemory } from "./gv_fixtures.ts";
import type { TripData } from "./gather.ts";
import {
  GV_CHAPTER_PHOTOS,
  MAX_GV_CHAPTERS,
  MAX_GV_HEROES,
  MIN_GV_CAROUSEL,
  MIN_GV_HEROES,
} from "./golden_vows.ts";

type Photo = TripData["photos"][number];

// A memory of [days] days with [perDay] photos a day, an hour apart.
function daysMemory(days: number, perDay: number): TripData {
  const photos: Photo[] = [];
  for (let d = 0; d < days; d++) {
    const day = `2026-07-${String(10 + d).padStart(2, "0")}`;
    for (let k = 0; k < perDay; k++) {
      const at = `${day}T${String(9 + k).padStart(2, "0")}:00:00Z`;
      photos.push({
        id: `d${d}p${k}`,
        day_date: day,
        taken_at: at,
        created_at: at,
        storage_path: `p/d${d}p${k}.jpg`,
        caption: null,
        use_in_wrap_up: null,
      } as Photo);
    }
  }
  return { ...gvMemory(), photos, notes: [] } as TripData;
}

Deno.test("a day in parts at its long break, then the next day", () => {
  const s = buildGvSkeleton(gvMemory(), gvHeroScores());
  assertEquals(
    s.chapters.map((c) => c.photos.map((p) => p.id).join(",")),
    [
      "g01,g02,g03,g04,g05,g06",
      "g07,g08,g09,g10,g11,g12",
      "g13,g14,g15,g16,g17,g18,g19,g20",
    ],
  );
  assertEquals(s.chapters.map((c) => c.days), [
    ["2026-06-12"],
    ["2026-06-12"],
    ["2026-06-13"],
  ]);
});

Deno.test("every page's photos: mains, 2–6 prints, the carousel, no repeats", () => {
  const s = buildGvSkeleton(gvMemory(), gvHeroScores());
  const shown = [
    ...s.mains.map((m) => m.photo_id),
    ...s.chapters.flatMap((c) => c.prints),
    ...s.carousel,
  ];
  assertEquals(new Set(shown).size, shown.length);
  // Up to 6 prints a chapter (#460): one page of 2–3, or two pages.
  for (const c of s.chapters) {
    assert(c.prints.length >= 2 && c.prints.length <= 6, `${c.prints}`);
    assertEquals(c.pages.flatMap((p) => p.prints), c.prints);
    for (const p of c.pages) {
      assert(p.prints.length >= 2 && p.prints.length <= GV_CHAPTER_PHOTOS);
    }
  }
  assert(s.mains.length >= MIN_GV_HEROES && s.mains.length <= MAX_GV_HEROES);
  // Each chapter has a main page; the Always picks are mains.
  assertEquals(new Set(s.mains.map((m) => m.chapter)).size, s.chapters.length);
  for (const id of ["g04", "g16"]) {
    assert(s.mains.some((m) => m.photo_id === id), id);
  }
  assert(s.carousel.length === 0 || s.carousel.length >= MIN_GV_CAROUSEL);
});

Deno.test("never more than 4 chapters, and no photo is lost", () => {
  const data = daysMemory(7, 4);
  const s = buildGvSkeleton(data);
  assertEquals(s.chapters.length, MAX_GV_CHAPTERS);
  assertEquals(
    s.chapters.flatMap((c) => c.photos.map((p) => p.id)),
    data.photos.map((p) => p.id),
  );
  // Each merged chapter keeps its days.
  assertEquals(s.chapters.flatMap((c) => c.days).length, 7);
});

Deno.test("a short day stays its own chapter; one photo joins (#460)", () => {
  const data = daysMemory(3, 8);
  // The middle day keeps 3 photos: a main page and a page of 2 prints.
  data.photos = data.photos.filter((p) =>
    !p.id.startsWith("d1") || ["d1p0", "d1p1", "d1p2"].includes(p.id)
  );
  const three = buildGvSkeleton(data);
  assertEquals(three.chapters.length, 3);
  assertEquals(three.chapters[1].pages.map((p) => p.layout), ["B2"]);
  assertEquals(three.mains.filter((m) => m.chapter === 1).length, 1);
  // 2 photos: a page of both, and a main page of one of them.
  data.photos = data.photos.filter((p) => p.id !== "d1p2");
  const two = buildGvSkeleton(data);
  assertEquals(two.chapters.length, 3);
  assertEquals(two.chapters[1].prints, ["d1p0", "d1p1"]);
  assert(
    two.mains.some((m) => m.chapter === 1 && m.photo_id.startsWith("d1")),
  );
  // 1 photo: into its neighbour, never lost.
  data.photos = data.photos.filter((p) => p.id !== "d1p1");
  const one = buildGvSkeleton(data);
  assertEquals(one.chapters.length, 2);
  assertEquals(
    one.chapters.flatMap((c) => c.photos).length,
    data.photos.length,
  );
});

Deno.test("play order: each chapter's heading page, then its pages by time (#460)", () => {
  const s = buildGvSkeleton(daysMemory(3, 10));
  let chapter = -1;
  for (const page of s.sequence) {
    const c = page.kind === "main" ? s.mains[page.main].chapter : page.chapter;
    if (page.kind === "prints" && page.page === 0) {
      assertEquals(c, chapter + 1);
      chapter = c;
    } else assertEquals(c, chapter);
  }
  assertEquals(chapter, s.chapters.length - 1);
  assertEquals(
    s.sequence.filter((p) => p.kind === "main").length,
    s.mains.length,
  );
});

Deno.test("one day: chapters only at long breaks", () => {
  const s = buildGvSkeleton(daysMemory(1, 15));
  // An hour apart: no break of 2 h, one chapter.
  assertEquals(s.chapters.length, 1);
  assert(s.mains.length >= MIN_GV_HEROES);
});

Deno.test("the occasion and the word that set it", () => {
  assertEquals(gvOccasionOf(gvMemory()), {
    occasion: "romance",
    trigger: null,
  });
  assertEquals(gvOccasionOf(gvMemory({ wedding: true })), {
    occasion: "wedding",
    trigger: { word: "свадьба", source: "note", id: "n1" },
  });
  const proposal = gvMemory();
  proposal.photos[2].caption = "She said yes!";
  assertEquals(gvOccasionOf(proposal).trigger, {
    word: "She said yes",
    source: "caption",
    id: "g03",
  });
  // A photo's summary counts too.
  assertEquals(
    gvOccasionOf(gvMemory(), new Map([["g05", "bride and groom dancing"]]))
      .trigger,
    { word: "bride", source: "photo", id: "g05" },
  );
  // A word inside another isn't one ("vowsome" no, "groomer" no).
  const other = gvMemory();
  other.notes[0].content = "Took the dog to the groomer.";
  assertEquals(gvOccasionOf(other).occasion, "romance");
});
