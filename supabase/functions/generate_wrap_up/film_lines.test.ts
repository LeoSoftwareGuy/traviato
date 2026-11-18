import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { bestLines } from "./excerpts.ts";
import { buildSkyContent, codeSkyPages } from "./sky_story.ts";
import { buildGoldenVowsContent } from "./golden_vows.ts";
import { directorTripData, goldenVowsPlan } from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";

// Sky Story and Golden Vows use the chosen lines (#419).

const RIBS = "Заказали 4,5 кг рёбер на троих в Брюсселе!";
const BIKES = "Rented 3 bikes and rode 12 km to Zaandam.";

Deno.test("bestLines: the specific ones, back in the notes' order", () => {
  const lines = bestLines([
    { id: "a", content: `It was fun. ${BIKES} Everyone was tired.` },
    { id: "b", content: `We went home. ${RIBS}` },
  ], 2);
  assertEquals(lines.map((l) => l.text), [BIKES, RIBS]);
  assertEquals(lines.map((l) => l.note_id), ["a", "b"]);
  // Nothing specific: none, and the film shows the note as before.
  assertEquals(bestLines([{ id: "a", content: "It was fun." }], 2), []);
  // Too long for the card: left out.
  assertEquals(bestLines([{ id: "a", content: RIBS }], 2, 20), []);
});

function withNotes(notes: TripData["notes"]): TripData {
  return directorTripData({ notes });
}

Deno.test("Sky Story: a note page carries its days' best lines", () => {
  const data = withNotes([
    {
      id: "n1",
      day_date: "2026-09-01",
      content: `It was fun. ${RIBS} We went home.`,
    },
    {
      id: "n1b",
      day_date: "2026-09-01",
      taken_at: "2026-09-01T20:00:00Z",
      content: BIKES,
    },
    { id: "n2", day_date: "2026-09-03", content: "Rain, then stroopwafels." },
  ]);
  const sky = buildSkyContent(data, null)!;
  const day1 = sky.pages.find((p) => p.first_day === 1 && p.note)!;
  assertEquals(day1.excerpts.map((e) => e.text), [RIBS, BIKES]);
  // Only the note's page carries them; a day with nothing specific none.
  for (const page of sky.pages) {
    if (page !== day1) assertEquals(page.excerpts, []);
  }
  assert(codeSkyPages(data).every((p) => p.excerpts.length === 0));
});

Deno.test("Golden Vows: a hero without words gets its day's best line", () => {
  const data = withNotes([
    { id: "n1", day_date: "2026-09-01", content: "Bikes everywhere." },
    {
      id: "n2",
      day_date: "2026-09-03",
      taken_at: "2026-09-03T12:00:00Z",
      content: `It was fun. ${BIKES}`,
    },
  ]);
  const gv = buildGoldenVowsContent(data, goldenVowsPlan());
  // The director's excerpt stays; p09 (day 3, no caption) gets the bikes.
  assertEquals(gv.heroes.map((h) => h.note), ["Bikes everywhere", BIKES]);
});

Deno.test("Golden Vows: a note on the photo first; a caption always wins", () => {
  const data = withNotes([
    {
      id: "n2",
      day_date: "2026-09-03",
      taken_at: "2026-09-03T12:00:00Z",
      content: BIKES,
    },
    {
      id: "n3",
      day_date: "2026-09-03",
      taken_at: "2026-09-03T13:00:00Z",
      photo_id: "p09",
      content: `We went home. ${RIBS}`,
    },
  ]);
  assertEquals(
    buildGoldenVowsContent(data, goldenVowsPlan()).heroes[1].note,
    RIBS,
  );
  data.photos = data.photos.map((p) =>
    p.id === "p09" ? { ...p, caption: "Our first dance" } : p
  );
  assertEquals(
    buildGoldenVowsContent(data, goldenVowsPlan()).heroes[1].note,
    "Our first dance",
  );
});
