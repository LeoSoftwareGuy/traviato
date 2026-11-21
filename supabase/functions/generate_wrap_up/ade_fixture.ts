// An ADE-Amsterdam-shaped Neon Night memory (#448), after the real one:
// three days, 27 photos, Russian notes and captions (some long, one
// profane). Day one breaks into the airport, the ribs dinner and the Kuko
// night; day two is UFC then the AMF night (the 04:43 laser shot); day
// three is Brussels. Times are the phone's (offset 0).
import { directorTripData } from "./director_fixtures.ts";
import type { TripData } from "./gather.ts";
import type { NeonNightPlan } from "./neon_night.ts";

type Photo = TripData["photos"][number];

const base = directorTripData().photos[0];

function photo(
  id: string,
  at: string,
  caption: string | null = null,
  extra: Partial<Photo> = {},
): Photo {
  return {
    ...base,
    id,
    day_date: at.slice(0, 10),
    taken_at: `${at}:00Z`,
    created_at: `${at}:00Z`,
    storage_path: `u/t/${id}.jpg`,
    caption,
    use_in_wrap_up: null,
    place_text: null,
    ...extra,
  };
}

export const ADE_LASER = "4b0281";

export function adeMemory(): TripData {
  const photos: Photo[] = [
    // Day 1 — the Tallinn airport, before the flight.
    photo("a1", "2026-10-22T09:40", "15 минут до посадки"),
    photo("a2", "2026-10-22T09:41"),
    photo("a3", "2026-10-22T10:05", "Боча уже спит в очереди на посадку"),
    photo("a4", "2026-10-22T10:30", "Последний кофе в Таллине перед вылетом"),
    // Day 1 — ribs.
    photo("r1", "2026-10-22T18:42", "Рёбра на четверых, 4,5 кг"),
    photo("r2", "2026-10-22T18:50", "Официант принёс поднос размером с колесо"),
    photo("r3", "2026-10-22T19:05", "пиво и ещё раз пиво"),
    photo("r4", "2026-10-22T19:30"),
    photo("r5", "2026-10-22T20:10"),
    // Day 1 — Kuko (after midnight stays on day one).
    photo(
      "k1",
      "2026-10-22T23:30",
      "Очередь в Kuko на час, но оно того стоило",
    ),
    photo(
      "k2",
      "2026-10-23T00:15",
      "Первый трек и весь зал уже прыгает вместе",
    ),
    photo("k3", "2026-10-23T01:02", "Unreal, всю ночь до утра без остановки"),
    photo("k4", "2026-10-23T01:40", "охуенный сет"),
    photo("k5", "2026-10-23T02:30", "Свет погас и все заорали в один голос"),
    photo("k6", "2026-10-23T03:10"),
    // Day 2 — UFC.
    photo("u1", "2026-10-23T20:00", "UFC в баре"),
    photo("u2", "2026-10-23T20:40", "Заняли последний столик прямо у экрана"),
    photo("u3", "2026-10-23T21:15", "Нокаут во втором раунде, бар взорвался"),
    photo("u4", "2026-10-23T22:00"),
    // Day 2 — AMF.
    photo("m1", "2026-10-24T00:30", "AMF"),
    photo(
      "m2",
      "2026-10-24T01:20",
      "Очередь на вход растянулась на весь квартал",
    ),
    photo("m3", "2026-10-24T03:00"),
    photo(ADE_LASER, "2026-10-24T04:43", "Лазеры над всем залом"),
    // Day 3 — Brussels.
    photo("b1", "2026-10-24T14:00", "Брюссель"),
    photo("b2", "2026-10-24T15:10"),
    photo("b3", "2026-10-24T16:40", "some sweets for Anna"),
    photo("b4", "2026-10-24T18:19"),
  ];
  const note = (id: string, at: string, content: string) => ({
    id,
    day_date: at.slice(0, 10),
    content,
    created_at: `${at}:00Z`,
    taken_at: `${at}:00Z`,
    photo_id: null,
    legacy: false,
  });
  return directorTripData({
    trip: {
      ...directorTripData().trip,
      name: "ADE-Amsterdam 2026",
      destination: "Amsterdam",
      start_date: "2026-10-22",
      end_date: "2026-10-24",
      vibes: ["Nightlife"],
    },
    photos,
    notes: [
      // Written after landing, far from the Tallinn photos (#450).
      note(
        "n0",
        "2026-10-22T13:10",
        "Приземлились в Амстердаме и сразу поехали в отель.",
      ),
      note(
        "n1",
        "2026-10-22T20:30",
        "Взяли 4,5 кг рёбер и пиво на четверых. Было супер весело и получили много позитивных эмоций.",
      ),
      note(
        "n2",
        "2026-10-23T03:30",
        "Kuko Unreal всю ночь до утра. Домой пришли в 8 утра, ноги отваливаются.",
      ),
      note(
        "n3",
        "2026-10-23T22:30",
        "Смотрели UFC в баре, нокаут во втором раунде и весь бар орал.",
      ),
      note(
        "n4",
        "2026-10-24T05:00",
        "Откисаем до AMF, а потом лазеры над всем залом и самый мощный дроп за неделю.",
      ),
      note(
        "n5",
        "2026-10-24T18:30",
        "Проснулись собрались с силами и позавтракали, потом поехали в Брюссель. Брюссель не меняется отличное пиво и вкусная еда.",
      ),
    ],
    checklist: [],
    quests: [],
  });
}

// The director's plan for it, as it came back (#450): English titles over
// Russian notes, a title too long, the headline as a chapter title, and
// chapters that don't match code's parts (a night-one title starting on
// day two). Brussels has no chapter of its own.
export function adeDirectorPlan(): NeonNightPlan {
  const chapter = (
    title: string,
    first: string,
    moments: NeonNightPlan["chapters"][number]["moments"] = [],
  ) => ({
    title,
    first_photo_id: first,
    note_id: null,
    note_excerpt: null,
    moments,
    excerpts: [],
  });
  return {
    chapters: [
      chapter("Tallinn airport", "a1"),
      chapter("4.5kg ribs then Куко", "r1"),
      chapter("Самый крутой сет", "k3"),
      chapter("Куко Unreal, home at 8 am", "u3"),
    ],
    note_moment: null,
    headline: "Самый крутой сет",
  };
}
