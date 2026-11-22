import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { chapterLayout, MAX_GV_HEART, packingOf } from "./golden_vows.ts";
import { goldenVowsFilm, gvShortestSeconds } from "./gv_film.ts";
import { directorTripData } from "./director_fixtures.ts";
import { gvHeroScores, gvMemory } from "./gv_fixtures.ts";
import { scopedId } from "./film_slots.ts";
import { WRAP_UP_LIMITS } from "./wrap_up_limits.ts";

Deno.test("chapter layouts follow the photos' shapes", () => {
  const shapes = (s: string[]) =>
    Object.fromEntries(s.map((o, i) => [`x${i}`, o]));
  const ids = ["x0", "x1", "x2"];
  assertEquals(
    chapterLayout(ids, shapes(["landscape", "portrait", "portrait"]), 0),
    "A",
  );
  assertEquals(
    chapterLayout(ids, shapes(["portrait", "square", "landscape"]), 0),
    "C",
  );
  assertEquals(
    chapterLayout(ids, shapes(["portrait", "portrait", "portrait"]), 0),
    "B",
  );
  // Unknown shapes: A, B, C in turn.
  assertEquals(
    [0, 1, 2, 3].map((i) => chapterLayout(ids, {}, i)),
    ["A", "B", "C", "A"],
  );
});

Deno.test("content: the memory's facts, the user's words, code's album", () => {
  const data = gvMemory();
  const { content } = goldenVowsFilm(data, null, {
    heroScores: gvHeroScores(),
  });
  assertEquals(content.gv_version, 1);
  assertEquals(content.occasion, "romance");
  assertEquals(content.names, "Париж вдвоём");
  assertEquals(content.place, "Париж");
  assertEquals(content.day_count, 2);
  // A captioned page plays its caption and no time; the others a line of
  // their own notes with their time.
  assertEquals(
    content.heroes.map((h) => [h.photo_id, h.note, h.taken_at !== null]),
    [
      ["g04", "Утро в Париже, кофе и круассаны у окна.", true],
      ["g07", "Эйфелева башня", false],
      [
        "g16",
        "Последний закат над Сеной, пообещали вернуться сюда через год.",
        true,
      ],
    ],
  );
  assertEquals(content.chapters.map((c) => [c.title, c.line]), [
    ["Наш первый круассан", "Глава первая · Утро"],
    ["Ужин на Монмартре", "Глава вторая · Вечер"],
    ["Последний закат", "Глава третья · Утро"],
  ]);
  assertEquals(content.chapters.map((c) => c.photo_ids.length), [3, 3, 3]);
  // 20 photos: past its target even at its quickest, so no carousel.
  assertEquals(content.carousel, null);
  assertEquals(content.heart_photo_ids.length, 20);
  assertEquals(content.moment_count, 20);
  assert(content.occasion_line && content.end_line);
});

Deno.test("the director's picks play when they hold", () => {
  const data = gvMemory();
  const cut = goldenVowsFilm(data, null, { heroScores: gvHeroScores() });
  const finale = cut.slots.find((s) => s.slot === "finale")!;
  // Its last candidate: words nothing else shows.
  const pick = finale.candidates[finale.candidates.length - 1];
  const film = goldenVowsFilm(data, {
    finale: { ids: [scopedId("finale", pick.id)] },
    "ch1.title": { ids: [], free_title: "Утро у Сены" },
    "ch2.title": { ids: ["invented"] },
  }, { heroScores: gvHeroScores() });
  assertEquals(film.content.end_line, pick.text);
  assertEquals(film.content.chapters[0].title, "Утро у Сены");
  // Not in its list: code's top candidate, and the inspector says why.
  assertEquals(film.content.chapters[1].title, "Ужин на Монмартре");
  const r = film.report.find((x) => x.slot === "ch2.title")!;
  assertEquals(r.source, "code");
  assert(r.reason.includes("not in this slot's list"), r.reason);
});

Deno.test("photos shown on pages, and the heart holds them all", () => {
  const film = goldenVowsFilm(gvMemory(), null, { heroScores: gvHeroScores() });
  // 3 main pages and 3 chapters of 3; no carousel for its target.
  assertEquals(film.shown, { pages: 12, photos: 20 });
});

Deno.test("packing: checked items first, else planned quests, else none", () => {
  const checklist = directorTripData({
    checklist: [
      { title: "Rings", suggestion_code: null, is_checked: true },
      { title: "Passport", suggestion_code: "passport", is_checked: true },
      { title: "Umbrella", suggestion_code: null, is_checked: false },
    ],
  });
  assertEquals(packingOf(checklist), {
    source: "checklist",
    items: [
      { text: "Rings", suggestion_code: null },
      { text: "Passport", suggestion_code: "passport" },
    ],
    checked: 2,
    total: 3,
  });
  const quests = directorTripData({
    checklist: [{ title: "Rings", suggestion_code: null, is_checked: false }],
    quests: Array.from({ length: 7 }, (_, i) => ({
      title: `Quest ${i}`,
      day_date: "2026-09-01",
      completed_at: null,
    })),
  });
  const fromQuests = packingOf(quests)!;
  assertEquals(fromQuests.source, "quests");
  assertEquals(fromQuests.items.map((i) => i.text), [
    "Quest 0",
    "Quest 1",
    "Quest 2",
    "Quest 3",
    "Quest 4",
  ]);
  assertEquals(packingOf(directorTripData()), null);
});

Deno.test("the heart: every photo, spread to 200; left-out ones never", () => {
  const data = directorTripData();
  data.photos = Array.from({ length: 230 }, (_, i) => ({
    ...data.photos[i % 12],
    id: `h${String(i).padStart(3, "0")}`,
    taken_at: `2026-09-01T${String(Math.floor(i / 60)).padStart(2, "0")}:${
      String(i % 60).padStart(2, "0")
    }:00Z`,
    day_date: "2026-09-01",
  }));
  data.photos[5].use_in_wrap_up = false;
  const { content } = goldenVowsFilm(data, null);
  assertEquals(content.heart_photo_ids.length, MAX_GV_HEART);
  assertEquals(content.heart_photo_ids.includes("h005"), false);
  assertEquals(content.moment_count, 229);
});

// Long notes on many pages: past the longest film even at its quickest.
function longMemory() {
  const data = gvMemory();
  data.photos = Array.from({ length: 48 }, (_, i) => {
    const day = 12 + Math.floor(i / 12);
    const at = `2026-06-${day}T${String(8 + (i % 12)).padStart(2, "0")}:00`;
    return {
      ...data.photos[0],
      id: `L${String(i).padStart(2, "0")}`,
      day_date: at.slice(0, 10),
      taken_at: new Date(Date.parse(`${at}:00+02:00`)).toISOString(),
      created_at: new Date(Date.parse(`${at}:00+02:00`)).toISOString(),
      caption: null,
      use_in_wrap_up: null,
    };
  });
  data.photos[0].caption = "Наш первый круассан у окна";
  data.trip.end_date = "2026-06-15";
  // Sentences of about 85 characters: each fits a page whole.
  data.notes = data.photos.filter((_, i) => i % 6 === 3).map((p, k) => ({
    id: `ln${k}`,
    day_date: p.day_date!,
    taken_at: p.taken_at,
    created_at: p.taken_at,
    photo_id: p.id,
    content:
      `Мы гуляли вдоль Сены до вечера, держались за руки и смеялись, день ${
        k + 1
      } был лучшим. Потом нашли маленькое кафе у моста и пили кофе с круассанами до темноты.`,
  }));
  data.checklist = [{
    title: "Кольца",
    suggestion_code: null,
    is_checked: true,
  }];
  return data;
}

Deno.test("length: notes give way first, then the carousel, packing, pages", () => {
  const data = longMemory();
  const film = goldenVowsFilm(data, null);
  const limit = WRAP_UP_LIMITS.longestFilmSeconds;
  assert(gvShortestSeconds(film.content) <= limit, `${film.trims}`);
  // The order: every note trim before the carousel, the carousel before
  // the packing card, both before any page.
  const at = (p: (t: string) => boolean) => film.trims.findIndex(p);
  const lastNote = film.trims.findLastIndex((t) => t.includes("note"));
  const carousel = at((t) => t === "no carousel");
  const packing = at((t) => t === "no packing card");
  const page = at((t) => t.endsWith("left out"));
  if (carousel >= 0) assert(lastNote < carousel, `${film.trims}`);
  if (packing >= 0) assert(carousel < packing, `${film.trims}`);
  if (page >= 0) assert(packing < page, `${film.trims}`);
  assert(film.trims.length > 0);
});

Deno.test("length: never a chapter, the title page, the heart or a caption", () => {
  const data = longMemory();
  const full = goldenVowsFilm(data, null);
  assertEquals(full.content.chapters.length, full.skeleton.chapters.length);
  assertEquals(full.content.heart_photo_ids.length, 48);
  assert(full.content.occasion_line);
  const captioned = full.content.heroes.find((h) => h.photo_id === "L00");
  if (full.skeleton.mains.some((m) => m.photo_id === "L00")) {
    assertEquals(captioned?.note, "Наш первый круассан у окна");
  }
  assert(full.content.heroes.length >= 2);
});

Deno.test("length: a shorter clause is never words already shown", () => {
  const notes = goldenVowsFilm(longMemory(), null).content.heroes
    .flatMap((h) => h.note ? [h.note.toLowerCase()] : []);
  assertEquals(new Set(notes).size, notes.length);
});

Deno.test("a short album aims at its target: no carousel, then no packing (#458)", () => {
  // 20 photos: a target of about 39 s, past it even at its quickest.
  const data = gvMemory();
  data.checklist = [{
    title: "Кольца",
    suggestion_code: null,
    is_checked: true,
  }];
  const film = goldenVowsFilm(data, null, { heroScores: gvHeroScores() });
  const { content } = film;
  assertEquals(content.carousel, null);
  assertEquals(content.packing, null);
  assertEquals(film.trims, [
    "no carousel (for the target)",
    "no packing card (for the target)",
  ]);
  // Never a chapter, a note, a caption or the heart.
  assertEquals(content.chapters.length, film.skeleton.chapters.length);
  assertEquals(content.heroes.length, film.skeleton.mains.length);
  assert(content.heroes.every((h) => h.note));
  assertEquals(content.heart_photo_ids.length, 20);
});

Deno.test("a long album keeps its carousel while it fits 75 s (#458)", () => {
  const film = goldenVowsFilm(longMemory(), null);
  assert(
    !film.trims.some((t) => t.includes("for the target")),
    `${film.trims}`,
  );
});
