// A small Romantic memory for the Golden Vows unit tests (#458). Made up,
// not real data: the real-data tests run on the exported fixture
// (fixtures/, tools/export_director_input.ts) once it is there.
import type { TripData } from "./gather.ts";

type Photo = TripData["photos"][number];
type Note = TripData["notes"][number];

// Paris, two days, at UTC+2: a day in two parts (a 3 h break), then a
// second day.
const PHOTOS: [string, string, string | null, boolean | null][] = [
  // id, local time, caption, use_in_wrap_up
  ["g01", "2026-06-12T10:05", "Наш первый круассан", null],
  ["g02", "2026-06-12T10:40", null, null],
  ["g03", "2026-06-12T11:30", "Сена", null],
  ["g04", "2026-06-12T12:10", null, true],
  ["g05", "2026-06-12T13:00", null, null],
  ["g06", "2026-06-12T13:45", null, null],
  ["g07", "2026-06-12T17:10", "Эйфелева башня", null],
  ["g08", "2026-06-12T18:00", null, null],
  ["g09", "2026-06-12T19:30", "Ужин на Монмартре", null],
  ["g10", "2026-06-12T20:15", null, null],
  ["g11", "2026-06-12T22:40", null, null],
  ["g12", "2026-06-12T23:30", null, null],
  ["g13", "2026-06-13T11:00", "Лувр", null],
  ["g14", "2026-06-13T11:40", null, null],
  ["g15", "2026-06-13T13:10", null, null],
  ["g16", "2026-06-13T14:30", null, true],
  ["g17", "2026-06-13T16:00", null, null],
  ["g18", "2026-06-13T17:20", "Последний закат", null],
  ["g19", "2026-06-13T18:40", null, null],
  ["g20", "2026-06-13T20:00", null, null],
];

const HERO: Record<string, number> = {
  g01: 4,
  g02: 2,
  g03: 3,
  g04: 5,
  g05: 2,
  g06: 3,
  g07: 5,
  g08: 3,
  g09: 4,
  g10: 2,
  g11: 4,
  g12: 3,
  g13: 3,
  g14: 2,
  g15: 4,
  g16: 5,
  g17: 3,
  g18: 5,
  g19: 2,
  g20: 3,
};

// [local] ('YYYY-MM-DDTHH:MM', UTC+2) as an ISO instant.
const utc = (local: string) =>
  new Date(Date.parse(`${local}:00+02:00`)).toISOString();

const NOTES: [string, string, string, string | null][] = [
  // id, local time, text, photo id
  [
    "n1",
    "2026-06-12T10:20",
    "Утро в Париже, кофе и круассаны у окна. Мы так долго этого ждали!",
    null,
  ],
  [
    "n2",
    "2026-06-12T17:30",
    "Поднялись на Эйфелеву башню, весь город под нами. Я держала его за руку и не хотела уходить.",
    null,
  ],
  [
    "n3",
    "2026-06-12T23:00",
    "Гуляли по ночному Монмартру до полуночи.",
    "g11",
  ],
  [
    "n4",
    "2026-06-13T15:00",
    "Было хорошо.",
    null,
  ],
  [
    "n5",
    "2026-06-13T18:00",
    "Последний закат над Сеной, пообещали вернуться сюда через год.",
    null,
  ],
];

// The memory; [wedding] makes its first note a wedding's.
export function gvMemory(
  { wedding = false }: { wedding?: boolean } = {},
): TripData {
  const photos: Photo[] = PHOTOS.map(([id, local, caption, use]) => ({
    id,
    day_date: local.slice(0, 10),
    taken_at: utc(local),
    created_at: utc(local),
    storage_path: `p/${id}.jpg`,
    caption,
    use_in_wrap_up: use,
    place_text: "Париж",
  }));
  const notes: Note[] = NOTES.map(([id, local, content, photo_id]) => ({
    id,
    day_date: local.slice(0, 10),
    taken_at: utc(local),
    created_at: utc(local),
    content: wedding && id === "n1"
      ? "Сегодня наша свадьба! Утро в Париже, кофе и круассаны у окна."
      : content,
    photo_id,
  }));
  return {
    trip: {
      name: "Париж вдвоём",
      destination: "Париж",
      country_code: "FR",
      start_date: "2026-06-12",
      end_date: "2026-06-13",
      vibes: ["Romantic"],
      cover_image_path: "asset:sunset",
    },
    notes,
    photos,
    utc_offset_minutes: 120,
  } as TripData;
}

export function gvHeroScores(): Record<string, number> {
  return { ...HERO };
}
